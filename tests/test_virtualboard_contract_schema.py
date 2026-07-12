#!/usr/bin/env python3
"""Prove every schema constraint used by the framework contract is enforced."""

from __future__ import annotations

import copy
import json
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

from json_schema import SchemaDefinitionError, validate  # noqa: E402
from check_contract import validate_authorization  # noqa: E402


class VirtualBoardContractSchemaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.contract = json.loads((ROOT / "virtualboard.json").read_text(encoding="utf-8"))
        cls.schema = json.loads(
            (ROOT / "schemas" / "virtualboard-contract.schema.json").read_text(encoding="utf-8")
        )

    def assert_invalid(self, mutate) -> None:
        value = copy.deepcopy(self.contract)
        mutate(value)
        self.assertTrue(validate(value, self.schema))

    def test_live_contract_satisfies_the_checked_schema(self):
        self.assertEqual([], validate(self.contract, self.schema))

    def test_required_and_additional_properties(self):
        self.assert_invalid(lambda value: value.pop("contractVersion"))
        self.assert_invalid(lambda value: value.__setitem__("unknown", True))
        self.assert_invalid(lambda value: value["roles"][0].__setitem__("unknown", True))

    def test_type_const_enum_and_minimum(self):
        self.assert_invalid(lambda value: value.__setitem__("contractVersion", "1"))
        self.assert_invalid(lambda value: value.__setitem__("contractVersion", 0))
        self.assert_invalid(lambda value: value["cli"].__setitem__("compatibility", "maybe"))
        self.assert_invalid(lambda value: value["feature"].__setitem__("claimBeforeWork", False))
        self.assert_invalid(
            lambda value: value["cli"]["actor"].__setitem__(
                "implicitOperatingSystemActorAllowed", True
            )
        )

    def test_string_length_and_pattern(self):
        self.assert_invalid(lambda value: value["roles"][0].__setitem__("displayName", "x"))
        self.assert_invalid(lambda value: value["roles"][0].__setitem__("id", "Not Valid"))

    def test_array_item_minimum_and_uniqueness(self):
        self.assert_invalid(lambda value: value.__setitem__("roles", []))
        self.assert_invalid(lambda value: value["roles"].__setitem__(0, 42))
        self.assert_invalid(lambda value: value["feature"]["statuses"].append("backlog"))
        self.assert_invalid(
            lambda value: value["cli"]["actor"].__setitem__("environmentVariables", [])
        )

    def test_object_minimum_and_referenced_definitions(self):
        self.assert_invalid(lambda value: value.__setitem__("pluginExpectations", {}))
        self.assert_invalid(lambda value: value["commands"][0].pop("alias"))

    def test_authorization_effects_are_exact_and_fail_closed(self):
        effects = self.contract["authorization"]["effects"]
        for effect_id, policy in effects.items():
            with self.subTest(effect=effect_id):
                replacement = (
                    "explicit-required"
                    if policy["confirmation"] != "explicit-required"
                    else "covered-by-task-scope"
                )
                self.assert_invalid(
                    lambda value, effect_id=effect_id, replacement=replacement: value[
                        "authorization"
                    ]["effects"][effect_id].__setitem__("confirmation", replacement)
                )

        self.assert_invalid(
            lambda value: value["authorization"]["effects"].pop("external-write")
        )
        self.assert_invalid(
            lambda value: value["authorization"]["effects"].__setitem__(
                "unknown", {"confirmation": "not-required"}
            )
        )
        self.assert_invalid(
            lambda value: value["authorization"]["untrustedContent"].__setitem__(
                "mayGrantToolAuthority", True
            )
        )

    def test_contract_checker_pins_the_same_authorization_mapping(self):
        mutated = copy.deepcopy(self.contract)
        mutated["authorization"]["effects"]["install"]["confirmation"] = (
            "covered-by-task-scope"
        )
        errors: list[str] = []
        validate_authorization(mutated, errors)
        self.assertEqual(1, len(errors))
        self.assertIn("exactly match", errors[0])

        errors = []
        validate_authorization(self.contract, errors)
        self.assertEqual([], errors)

    def test_unknown_schema_keywords_fail_closed(self):
        schema = copy.deepcopy(self.schema)
        schema["properties"]["contractVersion"]["multipleOf"] = 1
        with self.assertRaises(SchemaDefinitionError):
            validate(self.contract, schema)


if __name__ == "__main__":
    unittest.main()
