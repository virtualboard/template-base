#!/usr/bin/env python3
"""Dependency-free validator for the strict JSON Schema subset used here.

The framework contract deliberately uses a small Draft-07 vocabulary. Unknown
validation keywords are rejected so CI cannot silently ignore schema rules.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from typing import Any


ANNOTATION_KEYWORDS = {"$schema", "title", "description", "definitions"}
VALIDATION_KEYWORDS = {
    "$ref", "type", "required", "properties", "additionalProperties",
    "enum", "const", "minimum", "maximum", "minLength", "maxLength",
    "pattern", "minItems", "maxItems", "uniqueItems", "minProperties",
    "maxProperties", "items",
}
SUPPORTED_KEYWORDS = ANNOTATION_KEYWORDS | VALIDATION_KEYWORDS


@dataclass(frozen=True)
class SchemaIssue:
    path: str
    message: str

    def __str__(self) -> str:
        return f"{self.path}: {self.message}"


class SchemaDefinitionError(ValueError):
    """The schema itself uses an invalid or unsupported construct."""


def _json_key(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True)


def _matches_type(value: Any, expected: str) -> bool:
    checks = {
        "object": lambda: isinstance(value, dict),
        "array": lambda: isinstance(value, list),
        "string": lambda: isinstance(value, str),
        "integer": lambda: isinstance(value, int) and not isinstance(value, bool),
        "number": lambda: isinstance(value, (int, float)) and not isinstance(value, bool),
        "boolean": lambda: isinstance(value, bool),
        "null": lambda: value is None,
    }
    if expected not in checks:
        raise SchemaDefinitionError(f"unsupported JSON Schema type {expected!r}")
    return checks[expected]()


def _resolve_ref(root_schema: dict[str, Any], reference: str) -> dict[str, Any]:
    if not reference.startswith("#/"):
        raise SchemaDefinitionError(f"only local JSON Pointer references are supported: {reference!r}")
    current: Any = root_schema
    for raw_part in reference[2:].split("/"):
        part = raw_part.replace("~1", "/").replace("~0", "~")
        if not isinstance(current, dict) or part not in current:
            raise SchemaDefinitionError(f"unresolvable JSON Schema reference {reference!r}")
        current = current[part]
    if not isinstance(current, dict):
        raise SchemaDefinitionError(f"JSON Schema reference is not an object: {reference!r}")
    return current


def _check_schema_shape(schema: dict[str, Any], path: str) -> None:
    unknown = sorted(set(schema) - SUPPORTED_KEYWORDS)
    if unknown:
        raise SchemaDefinitionError(
            f"{path} uses unsupported JSON Schema keywords: {', '.join(unknown)}"
        )
    properties = schema.get("properties", {})
    if not isinstance(properties, dict):
        raise SchemaDefinitionError(f"{path}.properties must be an object")
    for name, child in properties.items():
        if not isinstance(child, dict):
            raise SchemaDefinitionError(f"{path}.properties.{name} must be an object")
        _check_schema_shape(child, f"{path}.properties.{name}")
    additional = schema.get("additionalProperties")
    if isinstance(additional, dict):
        _check_schema_shape(additional, f"{path}.additionalProperties")
    items = schema.get("items")
    if items is not None:
        if not isinstance(items, dict):
            raise SchemaDefinitionError(f"{path}.items must be an object")
        _check_schema_shape(items, f"{path}.items")
    definitions = schema.get("definitions", {})
    if not isinstance(definitions, dict):
        raise SchemaDefinitionError(f"{path}.definitions must be an object")
    for name, child in definitions.items():
        if not isinstance(child, dict):
            raise SchemaDefinitionError(f"{path}.definitions.{name} must be an object")
        _check_schema_shape(child, f"{path}.definitions.{name}")


def validate(instance: Any, schema: dict[str, Any]) -> list[SchemaIssue]:
    """Return every violation of the repository's supported Draft-07 subset."""

    if not isinstance(schema, dict):
        raise SchemaDefinitionError("root schema must be an object")
    _check_schema_shape(schema, "schema")
    issues: list[SchemaIssue] = []

    def visit(value: Any, rule: dict[str, Any], path: str) -> None:
        reference = rule.get("$ref")
        if reference is not None:
            if not isinstance(reference, str):
                raise SchemaDefinitionError(f"{path} has a non-string $ref")
            visit(value, _resolve_ref(schema, reference), path)
            return

        expected_type = rule.get("type")
        if expected_type is not None:
            if not isinstance(expected_type, str):
                raise SchemaDefinitionError(f"{path} has a non-string type")
            if not _matches_type(value, expected_type):
                issues.append(SchemaIssue(path, f"expected {expected_type}, got {type(value).__name__}"))
                return

        if "const" in rule and value != rule["const"]:
            issues.append(SchemaIssue(path, f"must equal {rule['const']!r}"))
        if "enum" in rule:
            choices = rule["enum"]
            if not isinstance(choices, list):
                raise SchemaDefinitionError(f"{path} has a non-array enum")
            if value not in choices:
                issues.append(SchemaIssue(path, f"must be one of {choices!r}"))

        if isinstance(value, dict):
            required = rule.get("required", [])
            if not isinstance(required, list) or not all(isinstance(item, str) for item in required):
                raise SchemaDefinitionError(f"{path} has an invalid required array")
            for name in required:
                if name not in value:
                    issues.append(SchemaIssue(path, f"missing required property {name!r}"))
            minimum = rule.get("minProperties")
            maximum = rule.get("maxProperties")
            if minimum is not None and len(value) < minimum:
                issues.append(SchemaIssue(path, f"must contain at least {minimum} properties"))
            if maximum is not None and len(value) > maximum:
                issues.append(SchemaIssue(path, f"must contain at most {maximum} properties"))
            properties = rule.get("properties", {})
            additional = rule.get("additionalProperties", True)
            for name, child_value in value.items():
                child_path = f"{path}.{name}"
                if name in properties:
                    visit(child_value, properties[name], child_path)
                elif additional is False:
                    issues.append(SchemaIssue(child_path, "additional property is forbidden"))
                elif isinstance(additional, dict):
                    visit(child_value, additional, child_path)
                elif additional is not True:
                    raise SchemaDefinitionError(f"{path}.additionalProperties must be boolean or object")

        if isinstance(value, list):
            minimum = rule.get("minItems")
            maximum = rule.get("maxItems")
            if minimum is not None and len(value) < minimum:
                issues.append(SchemaIssue(path, f"must contain at least {minimum} items"))
            if maximum is not None and len(value) > maximum:
                issues.append(SchemaIssue(path, f"must contain at most {maximum} items"))
            if rule.get("uniqueItems") is True:
                seen: set[str] = set()
                for index, item in enumerate(value):
                    key = _json_key(item)
                    if key in seen:
                        issues.append(SchemaIssue(f"{path}[{index}]", "duplicate item is forbidden"))
                    seen.add(key)
            item_rule = rule.get("items")
            if item_rule is not None:
                for index, item in enumerate(value):
                    visit(item, item_rule, f"{path}[{index}]")

        if isinstance(value, str):
            minimum = rule.get("minLength")
            maximum = rule.get("maxLength")
            if minimum is not None and len(value) < minimum:
                issues.append(SchemaIssue(path, f"must contain at least {minimum} characters"))
            if maximum is not None and len(value) > maximum:
                issues.append(SchemaIssue(path, f"must contain at most {maximum} characters"))
            pattern = rule.get("pattern")
            if pattern is not None:
                if not isinstance(pattern, str):
                    raise SchemaDefinitionError(f"{path}.pattern must be a string")
                try:
                    matched = re.search(pattern, value)
                except re.error as exc:
                    raise SchemaDefinitionError(f"invalid regex at {path}: {exc}") from exc
                if matched is None:
                    issues.append(SchemaIssue(path, f"does not match pattern {pattern!r}"))

        if isinstance(value, (int, float)) and not isinstance(value, bool):
            minimum = rule.get("minimum")
            maximum = rule.get("maximum")
            if minimum is not None and value < minimum:
                issues.append(SchemaIssue(path, f"must be at least {minimum}"))
            if maximum is not None and value > maximum:
                issues.append(SchemaIssue(path, f"must be at most {maximum}"))

    visit(instance, schema, "$")
    return issues
