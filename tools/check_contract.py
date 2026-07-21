#!/usr/bin/env python3
"""Validate VirtualBoard's canonical contract using only the Python standard library."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from json_schema import SchemaDefinitionError, validate as validate_json_schema


EXPECTED_AUTHORIZATION: dict[str, Any] = {
    "defaultScope": "current-user-request",
    "continuousQueueProcessingRequiresExplicitOptIn": True,
    "untrustedContent": {
        "mayDefineDesiredOutcomes": True,
        "mayGrantToolAuthority": False,
        "mayExpandTaskScope": False,
    },
    "effects": {
        "read": {"confirmation": "not-required"},
        "write-local": {"confirmation": "covered-by-task-scope"},
        "execute": {"confirmation": "covered-by-task-scope"},
        "network-read": {"confirmation": "covered-by-task-scope"},
        "install": {"confirmation": "explicit-required"},
        "external-write": {"confirmation": "explicit-required"},
        "production-sensitive": {"confirmation": "explicit-required"},
        "destructive": {"confirmation": "explicit-required"},
    },
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "root",
        nargs="?",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="repository or installed VirtualBoard root",
    )
    parser.add_argument("--json", action="store_true", help="emit machine-readable output")
    return parser.parse_args()


def load_json(path: Path, errors: list[str]) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        errors.append(f"missing required file: {path}")
        return {}
    except json.JSONDecodeError as exc:
        errors.append(f"invalid JSON in {path}: {exc}")
        return {}
    if not isinstance(value, dict):
        errors.append(f"expected JSON object in {path}")
        return {}
    return value


def unique(values: list[str], label: str, errors: list[str]) -> None:
    duplicates = sorted({value for value in values if values.count(value) > 1})
    if duplicates:
        errors.append(f"duplicate {label}: {', '.join(duplicates)}")


def yaml_string(text: str, key: str) -> str | None:
    match = re.search(
        rf'^\s*{re.escape(key)}:\s*("(?:[^"\\]|\\.)*")\s*$',
        text,
        re.MULTILINE,
    )
    if not match:
        return None
    try:
        value = json.loads(match.group(1))
    except json.JSONDecodeError:
        return None
    return value if isinstance(value, str) else None


def validate_authorization(contract: dict[str, Any], errors: list[str]) -> set[str]:
    authorization = contract.get("authorization")
    if authorization != EXPECTED_AUTHORIZATION:
        errors.append(
            "authorization must exactly match the canonical scope, untrusted-content policy, "
            "effect taxonomy, and per-effect confirmation requirements"
        )
    effects = authorization.get("effects", {}) if isinstance(authorization, dict) else {}
    return set(effects) if isinstance(effects, dict) else set()


def validate(root: Path) -> list[str]:
    errors: list[str] = []
    contract_path = root / "virtualboard.json"
    contract = load_json(contract_path, errors)
    if not contract:
        return errors

    schema_ref = contract.get("$schema")
    if not isinstance(schema_ref, str) or not (root / schema_ref).is_file():
        errors.append(f"contract schema does not exist: {schema_ref!r}")
    else:
        contract_schema = load_json(root / schema_ref, errors)
        if contract_schema:
            try:
                for issue in validate_json_schema(contract, contract_schema):
                    errors.append(f"virtualboard.json schema violation: {issue}")
            except SchemaDefinitionError as exc:
                errors.append(f"invalid or unsupported framework contract schema: {exc}")

    template_version_file = contract.get("templateVersionFile")
    template_version = ""
    if not isinstance(template_version_file, str) or not (root / template_version_file).is_file():
        errors.append(f"templateVersionFile does not reference a file: {template_version_file!r}")
    else:
        template_version = (root / template_version_file).read_text(encoding="utf-8").strip()
        if not re.fullmatch(r"\d+\.\d+\.\d+", template_version):
            errors.append(f"invalid template version in {template_version_file}: {template_version!r}")

    version_surfaces = (
        ("plugins/claude/virtualboard/.claude-plugin/plugin.json", ("version",)),
        ("plugins/codex/virtualboard/.codex-plugin/plugin.json", ("version",)),
        (".claude-plugin/marketplace.json", ("metadata", "version")),
    )
    for relative, keys in version_surfaces:
        document = load_json(root / relative, errors)
        value: Any = document
        for key in keys:
            value = value.get(key) if isinstance(value, dict) else None
        if template_version and value != template_version:
            errors.append(f"{relative} version {value!r} must match {template_version!r}")
    marketplace = load_json(root / ".claude-plugin" / "marketplace.json", errors)
    marketplace_plugins = marketplace.get("plugins", []) if marketplace else []
    if template_version and isinstance(marketplace_plugins, list):
        for plugin in marketplace_plugins:
            if isinstance(plugin, dict) and plugin.get("version") != template_version:
                errors.append("Claude marketplace plugin version must match template version")
    opencode_path = root / "docs" / ".opencode" / "skill" / "virtualboard" / "SKILL.md"
    try:
        opencode_text = opencode_path.read_text(encoding="utf-8")
    except FileNotFoundError:
        errors.append(f"missing required file: {opencode_path}")
        opencode_text = ""
    opencode_match = re.search(r"^\s{2}version:\s*(\S+)\s*$", opencode_text, re.MULTILINE)
    if template_version and (not opencode_match or opencode_match.group(1) != template_version):
        errors.append("OpenCode skill version must match template version")

    cli = contract.get("cli", {})
    version_file = cli.get("versionFile") if isinstance(cli, dict) else None
    if not isinstance(version_file, str) or not (root / version_file).is_file():
        errors.append(f"cli.versionFile does not reference a file: {version_file!r}")
    elif not re.fullmatch(r"v\d+\.\d+\.\d+", (root / version_file).read_text().strip()):
        errors.append(f"invalid pinned CLI version in {version_file}")
    required_commands = cli.get("requiredCommands", []) if isinstance(cli, dict) else []
    if not isinstance(required_commands, list):
        errors.append("cli.requiredCommands must be an array")
        required_commands = []
    for required_command in ("audit", "migrate"):
        if required_command not in required_commands:
            errors.append(f"cli.requiredCommands must include {required_command}")
    actor = cli.get("actor", {}) if isinstance(cli, dict) else {}
    if actor.get("flag") != "--actor":
        errors.append("cli.actor.flag must be --actor")
    actor_environment = actor.get("environmentVariables", []) if isinstance(actor, dict) else []
    if actor_environment != ["VIRTUALBOARD_ACTOR", "AGENT_ID"]:
        errors.append(
            "cli.actor.environmentVariables must be VIRTUALBOARD_ACTOR then AGENT_ID"
        )
    actor_pattern = actor.get("pattern") if isinstance(actor, dict) else None
    try:
        if not isinstance(actor_pattern, str):
            raise re.error("not a string")
        re.compile(actor_pattern)
    except re.error as exc:
        errors.append(f"cli.actor.pattern is not a valid regular expression: {exc}")
    if actor.get("requiredForFeatureMutations") is not True:
        errors.append("cli.actor.requiredForFeatureMutations must be true")
    if actor.get("implicitOperatingSystemActorAllowed") is not False:
        errors.append("cli.actor.implicitOperatingSystemActorAllowed must be false")

    workspace = contract.get("workspace", {})
    paths = workspace.get("paths", {}) if isinstance(workspace, dict) else {}
    if not isinstance(paths, dict):
        errors.append("workspace.paths must be an object")
        paths = {}
    for path_id, relative in paths.items():
        if (
            not isinstance(path_id, str)
            or not isinstance(relative, str)
            or not relative
            or Path(relative).is_absolute()
            or ".." in Path(relative).parts
        ):
            errors.append(f"workspace path {path_id!r} is not a safe relative path: {relative!r}")

    feature = contract.get("feature", {})
    statuses = feature.get("statuses", []) if isinstance(feature, dict) else []
    if not isinstance(statuses, list) or not all(isinstance(item, str) for item in statuses):
        errors.append("feature.statuses must be an array of strings")
        statuses = []
    unique(statuses, "feature status", errors)

    transitions = feature.get("transitions", {}) if isinstance(feature, dict) else {}
    ownership = feature.get("ownership", {}) if isinstance(feature, dict) else {}
    if set(transitions) != set(statuses):
        errors.append("feature.transitions keys must exactly match feature.statuses")
    if set(ownership) != set(statuses):
        errors.append("feature.ownership keys must exactly match feature.statuses")
    for source, targets in transitions.items():
        if not isinstance(targets, list):
            errors.append(f"transition targets for {source} must be an array")
            continue
        unknown = sorted(set(targets) - set(statuses))
        if unknown:
            errors.append(f"unknown transition targets from {source}: {', '.join(unknown)}")
    if transitions.get("done") != []:
        errors.append("done must be terminal")

    for pattern_field in ("idPattern", "filenamePattern", "ownerPattern", "branchPattern"):
        pattern = feature.get(pattern_field) if isinstance(feature, dict) else None
        if not isinstance(pattern, str):
            errors.append(f"feature.{pattern_field} must be a regular-expression string")
            continue
        try:
            re.compile(pattern)
        except re.error as exc:
            errors.append(f"feature.{pattern_field} is not a valid regular expression: {exc}")
    if feature.get("branchFormat") != "feat/{id}-{slug}":
        errors.append("feature.branchFormat must be feat/{id}-{slug}")
    if not isinstance(feature.get("slugMaxWords"), int) or feature.get("slugMaxWords", 0) < 1:
        errors.append("feature.slugMaxWords must be a positive integer")
    if not isinstance(feature.get("lockTtlMinutes"), int) or feature.get("lockTtlMinutes", 0) < 1:
        errors.append("feature.lockTtlMinutes must be a positive integer")
    if feature.get("remoteClaimRequiredAcrossClones") is not True:
        errors.append("feature.remoteClaimRequiredAcrossClones must be true")
    if feature.get("localClaimRequiresSharedWorkspaceOptIn") is not True:
        errors.append("feature.localClaimRequiresSharedWorkspaceOptIn must be true")

    feature_root = paths.get("features")
    if isinstance(feature_root, str):
        for status in statuses:
            if not (root / feature_root / status).is_dir():
                errors.append(f"missing lifecycle directory: {feature_root}/{status}")

    roles = contract.get("roles", [])
    if not isinstance(roles, list):
        errors.append("roles must be an array")
        roles = []
    role_ids = [role.get("id", "") for role in roles if isinstance(role, dict)]
    unique(role_ids, "role id", errors)
    role_id_set = set(role_ids)
    for role in roles:
        if not isinstance(role, dict):
            errors.append("each role must be an object")
            continue
        for field in ("agentFile", "commandCatalog"):
            relative = role.get(field)
            if not isinstance(relative, str) or not (root / relative).is_file():
                errors.append(f"role {role.get('id')} has missing {field}: {relative!r}")

    effect_ids = validate_authorization(contract, errors)
    skills = contract.get("skills", [])
    if not isinstance(skills, list):
        errors.append("skills must be an array")
        skills = []
    skill_ids = [skill.get("id", "") for skill in skills if isinstance(skill, dict)]
    unique(skill_ids, "skill id", errors)
    for skill in skills:
        if not isinstance(skill, dict):
            errors.append("each skill must be an object")
            continue
        skill_id = skill.get("id")
        path = skill.get("path")
        if not isinstance(path, str) or not (root / path).is_file():
            errors.append(f"skill {skill_id} has missing path: {path!r}")
        skill_effects = skill.get("effects", [])
        if not isinstance(skill_effects, list):
            errors.append(f"skill {skill_id} effects must be an array")
        else:
            unknown_effects = sorted(set(skill_effects) - effect_ids)
            if unknown_effects:
                errors.append(f"skill {skill_id} has unknown effects: {', '.join(unknown_effects)}")

    commands = contract.get("commands", [])
    if not isinstance(commands, list):
        errors.append("commands must be an array")
        commands = []
    command_ids = [command.get("id", "") for command in commands if isinstance(command, dict)]
    aliases = [command.get("alias", "") for command in commands if isinstance(command, dict)]
    unique(command_ids, "command id", errors)
    unique(aliases, "command alias", errors)
    for command in commands:
        if not isinstance(command, dict):
            errors.append("each command must be an object")
            continue
        command_id = command.get("id")
        if command.get("role") not in role_id_set:
            errors.append(f"command {command_id} references unknown role {command.get('role')!r}")
        prompt = command.get("prompt")
        if not isinstance(prompt, str) or not (root / prompt).is_file():
            errors.append(f"command {command_id} has missing prompt: {prompt!r}")
            prompt_text = ""
        else:
            prompt_text = (root / prompt).read_text(encoding="utf-8")
        command_effects = command.get("effects", [])
        if not isinstance(command_effects, list):
            errors.append(f"command {command_id} effects must be an array")
        else:
            unknown_effects = sorted(set(command_effects) - effect_ids)
            if unknown_effects:
                errors.append(f"command {command_id} has unknown effects: {', '.join(unknown_effects)}")
            if "Generated by tools/sync_report_instructions.py" in prompt_text and "execute" not in command_effects:
                errors.append(f"report command {command_id} must declare execute for the renderer")
            if re.search(r"^\s*(?:npx\b|npm\s+install\b|yarn\s+create\b)", prompt_text, re.MULTILINE):
                if "install" not in command_effects:
                    errors.append(f"command {command_id} may install through package tooling but omits install")
                if "network-read" not in command_effects:
                    errors.append(f"command {command_id} may use package tooling but omits network-read")
            if re.search(r"^\s*(?:curl\s+https?://|npm\s+audit\b)", prompt_text, re.MULTILINE) and "network-read" not in command_effects:
                errors.append(f"command {command_id} performs a network read but omits network-read")
            if re.search(
                r"^\s*(?:npx\s+(?:--no-install\s+)?pact-broker\s+publish\b|git\s+push\b|gh\s+pr\s+create\b)",
                prompt_text,
                re.MULTILINE,
            ) and "external-write" not in command_effects:
                errors.append(
                    f"command {command_id} may mutate an external system but omits external-write"
                )

    expectations = contract.get("pluginExpectations", {})
    claude = expectations.get("claude", {}) if isinstance(expectations, dict) else {}
    if claude.get("agents") != len(roles):
        errors.append("Claude agent expectation must equal role count")
    if claude.get("workflows") != len(commands):
        errors.append("Claude workflow expectation must equal command count")
    if claude.get("skills") != len(skills):
        errors.append("Claude skill expectation must equal skill count")

    codex = expectations.get("codex", {}) if isinstance(expectations, dict) else {}
    if codex.get("skills") != len(skills):
        errors.append("Codex skill expectation must equal skill count")

    feature_schema = load_json(root / "schemas" / "frontmatter.schema.json", errors)
    schema_statuses = (
        feature_schema.get("properties", {}).get("status", {}).get("enum", [])
        if feature_schema
        else []
    )
    if schema_statuses != statuses:
        errors.append("frontmatter schema status enum must match feature.statuses in order")
    schema_owner_pattern = (
        feature_schema.get("properties", {}).get("owner", {}).get("pattern")
        if feature_schema
        else None
    )
    if schema_owner_pattern != feature.get("ownerPattern"):
        errors.append("frontmatter schema owner pattern must match feature.ownerPattern")
    if isinstance(actor_pattern, str) and feature.get("ownerPattern") != (
        f"^(?:unassigned|{actor_pattern.removeprefix('^').removesuffix('$')})$"
    ):
        errors.append("feature.ownerPattern must extend cli.actor.pattern only with unassigned")
    implementation_owner_field = feature.get("implementationOwnerField")
    implementation_owner_schema = (
        feature_schema.get("properties", {}).get(implementation_owner_field, {})
        if feature_schema and isinstance(implementation_owner_field, str)
        else {}
    )
    if implementation_owner_schema.get("pattern") != feature.get("ownerPattern"):
        errors.append("implementation-owner schema must use the canonical owner pattern")
    status_changed_field = feature.get("statusChangedField")
    status_changed_schema = (
        feature_schema.get("properties", {}).get(status_changed_field, {})
        if feature_schema and isinstance(status_changed_field, str)
        else {}
    )
    if status_changed_schema.get("format") != "date":
        errors.append("frontmatter schema must define feature.statusChangedField as a date")
    required_frontmatter = set(feature_schema.get("required", [])) if feature_schema else set()
    for required_field in ("owner", implementation_owner_field, status_changed_field):
        if required_field not in required_frontmatter:
            errors.append(f"frontmatter schema must require {required_field}")
    try:
        feature_template = (root / "templates" / "feature.md").read_text(encoding="utf-8")
    except FileNotFoundError:
        feature_template = ""
    if not isinstance(status_changed_field, str) or not re.search(
        rf"^{re.escape(status_changed_field)}:\s*YYYY-MM-DD\s*$",
        feature_template,
        re.MULTILINE,
    ):
        errors.append("feature template must initialize the canonical status-changed field")
    if not isinstance(implementation_owner_field, str) or not re.search(
        rf"^{re.escape(implementation_owner_field)}:\s*unassigned\s*$",
        feature_template,
        re.MULTILINE,
    ):
        errors.append("feature template must initialize the implementation-owner field")
    assigned_statuses = {
        status for status, policy in ownership.items() if policy == "assigned-required"
    }
    schema_assigned_statuses: set[str] = set()
    for condition in feature_schema.get("allOf", []) if feature_schema else []:
        candidates = (
            condition.get("if", {})
            .get("properties", {})
            .get("status", {})
            .get("enum", [])
        )
        then = condition.get("then", {})
        required_managed_fields = set(then.get("required", []))
        if "owner" in required_managed_fields:
            schema_assigned_statuses.update(candidates)
            if implementation_owner_field not in required_managed_fields:
                errors.append(
                    "managed lifecycle states must require the canonical implementation-owner field"
                )
    if schema_assigned_statuses != assigned_statuses:
        errors.append("frontmatter schema assigned-owner statuses must match feature.ownership")

    rules_path = root / "templates" / "rules.yml"
    try:
        rules = rules_path.read_text(encoding="utf-8")
    except FileNotFoundError:
        errors.append(f"missing required file: {rules_path}")
        rules = ""
    rule_fields = {
        "id_pattern": feature.get("idPattern"),
        "filename_pattern": feature.get("filenamePattern"),
        "owner_pattern": feature.get("ownerPattern"),
        "branch_pattern": feature.get("branchPattern"),
    }
    for key, expected in rule_fields.items():
        if yaml_string(rules, key) != expected:
            errors.append(f"templates/rules.yml {key} must match the canonical contract")
    expected_schema_path = f"{paths.get('schemas')}/frontmatter.schema.json"
    if yaml_string(rules, "frontmatter_schema") != expected_schema_path:
        errors.append("templates/rules.yml frontmatter_schema must be relative to VB_ROOT")
    for setting in (
        "require_implementation_owner_for_managed_status",
        "require_status_changed",
    ):
        if not re.search(rf"^\s{{2}}{setting}:\s*true\s*$", rules, re.MULTILINE):
            errors.append(f"templates/rules.yml must enable {setting}")
    ttl_match = re.search(r"^\s*lock_ttl_minutes:\s*(\d+)\s*$", rules, re.MULTILINE)
    rule_ttl = int(ttl_match.group(1)) if ttl_match else None
    if rule_ttl != feature.get("lockTtlMinutes"):
        errors.append("templates/rules.yml lock_ttl_minutes must match the canonical contract")
    allowed_match = re.search(
        r"^transitions:\s*$\n(?P<body>.*?)(?=^\s{2}forbidden:\s*$)",
        rules,
        re.MULTILINE | re.DOTALL,
    )
    rule_transitions: dict[str, list[str]] = {}
    if allowed_match:
        for source, target_text in re.findall(
            r'^\s{4}- from: "([^"]+)"\s*$\n^\s{6}to: \[([^\]]*)\]\s*$',
            allowed_match.group("body"),
            re.MULTILINE,
        ):
            rule_transitions[source] = re.findall(r'"([^"]+)"', target_text)
    expected_nonterminal = {source: targets for source, targets in transitions.items() if targets}
    if rule_transitions != expected_nonterminal:
        errors.append("templates/rules.yml allowed transitions must match the canonical contract")

    return errors


def main() -> int:
    args = parse_args()
    root = args.root.resolve()
    errors = validate(root)
    result = {"success": not errors, "root": str(root), "errors": errors}
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    elif errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
    else:
        print("VirtualBoard contract is internally consistent")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
