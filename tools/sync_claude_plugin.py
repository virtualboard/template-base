#!/usr/bin/env python3
"""Generate or verify the distributable Claude Code plugin components.

The framework sources stay canonical in ``agents/``, ``prompts/``, and
``skills/``.  Claude Code receives a self-contained plugin package under
``plugins/claude/virtualboard`` whose default component directories are
discoverable by both the runtime and ``claude plugin details``.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
CONTRACT_PATH = REPO_ROOT / "virtualboard.json"
PLUGIN_ROOT = REPO_ROOT / "plugins" / "claude" / "virtualboard"
MARKETPLACE_PATH = REPO_ROOT / ".claude-plugin" / "marketplace.json"
PLUGIN_MANIFEST_PATH = PLUGIN_ROOT / ".claude-plugin" / "plugin.json"
GENERATED_DIRECTORIES = ("agents", "commands", "skills")
SAFE_COMPONENT_NAME = re.compile(r"^[a-z][a-z0-9-]*$")


@dataclass(frozen=True)
class GeneratedFile:
    path: Path
    content: bytes


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group()
    action.add_argument(
        "--check",
        action="store_true",
        help="verify committed plugin components (default)",
    )
    action.add_argument(
        "--write",
        action="store_true",
        help="synchronize committed plugin components from canonical sources",
    )
    parser.add_argument("--json", action="store_true", help="emit JSON output")
    return parser.parse_args()


def load_json_object(path: Path, label: str) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise ValueError(f"missing {label}: {path}") from exc
    except json.JSONDecodeError as exc:
        raise ValueError(f"invalid {label}: {exc}") from exc
    if not isinstance(value, dict):
        raise ValueError(f"{label} must be a JSON object")
    return value


def load_contract() -> dict[str, Any]:
    return load_json_object(CONTRACT_PATH, "canonical contract")


def validate_packaging_metadata() -> None:
    legacy_manifest = REPO_ROOT / ".claude-plugin" / "plugin.json"
    if legacy_manifest.exists():
        raise ValueError(
            "legacy marketplace-root plugin manifest must remain absent; "
            "the distributable plugin root is plugins/claude/virtualboard"
        )

    marketplace = load_json_object(MARKETPLACE_PATH, "Claude marketplace manifest")
    manifest = load_json_object(PLUGIN_MANIFEST_PATH, "Claude plugin manifest")
    plugins = marketplace.get("plugins")
    if not isinstance(plugins, list):
        raise ValueError("Claude marketplace manifest plugins must be an array")
    matches = [
        entry
        for entry in plugins
        if isinstance(entry, dict) and entry.get("name") == manifest.get("name")
    ]
    if len(matches) != 1:
        raise ValueError(
            "Claude marketplace must contain exactly one entry matching the plugin name"
        )
    entry = matches[0]
    expected_source = "./plugins/claude/virtualboard"
    if entry.get("source") != expected_source:
        raise ValueError(
            f"Claude marketplace source must be {expected_source!r}, "
            f"found {entry.get('source')!r}"
        )
    for field in ("name", "version", "description", "homepage", "repository", "license"):
        if entry.get(field) != manifest.get(field):
            raise ValueError(
                f"Claude marketplace and plugin manifest disagree on {field}: "
                f"{entry.get(field)!r} != {manifest.get(field)!r}"
            )
    component_fields = {"agents", "commands", "skills"} & manifest.keys()
    if component_fields:
        raise ValueError(
            "Claude plugin manifest must use default component discovery; remove: "
            + ", ".join(sorted(component_fields))
        )


def require_list(contract: dict[str, Any], key: str) -> list[dict[str, Any]]:
    value = contract.get(key)
    if not isinstance(value, list) or not all(isinstance(item, dict) for item in value):
        raise ValueError(f"contract field {key!r} must be an array of objects")
    return value


def read_source(relative: str, label: str) -> bytes:
    source = REPO_ROOT / relative
    if not source.is_file():
        raise ValueError(f"{label} source does not exist: {relative}")
    return source.read_bytes()


def first_heading(markdown: str, fallback: str) -> str:
    for line in markdown.splitlines():
        if line.startswith("# "):
            return line.removeprefix("# ").strip()
    return fallback


def render_agent(role_id: str, source: str) -> GeneratedFile:
    source_text = read_source(source, f"role {role_id}").decode("utf-8")
    if not source_text.startswith("---\n"):
        raise ValueError(f"role {role_id} agent source has no YAML frontmatter")
    frontmatter_end = source_text.find("\n---\n", 4)
    if frontmatter_end < 0:
        raise ValueError(f"role {role_id} agent source has unterminated frontmatter")
    frontmatter = source_text[4:frontmatter_end]
    rewritten, replacements = re.subn(
        r"^name:\s*.+$", f"name: {role_id}", frontmatter, count=1, flags=re.MULTILINE
    )
    if replacements != 1:
        raise ValueError(f"role {role_id} agent source frontmatter has no name")
    body = source_text[frontmatter_end + len("\n---\n") :]
    generated = (
        f"---\n{rewritten}\n---\n\n"
        f"<!-- Generated from {source} by tools/sync_claude_plugin.py. -->\n\n"
        f"{body.lstrip()}"
    )
    return GeneratedFile(Path("agents") / f"{role_id}.md", generated.encode("utf-8"))


def render_command(command: dict[str, Any]) -> GeneratedFile:
    command_id = command.get("id")
    alias = command.get("alias")
    prompt = command.get("prompt")
    effects = command.get("effects")
    if not all(isinstance(value, str) and value for value in (command_id, alias, prompt)):
        raise ValueError(f"invalid command registry entry: {command!r}")
    if not isinstance(effects, list) or not effects or not all(
        isinstance(effect, str) and effect for effect in effects
    ):
        raise ValueError(f"command {command_id!r} has invalid effects")

    component_name = command_id.replace(".", "-")
    if not SAFE_COMPONENT_NAME.fullmatch(component_name):
        raise ValueError(f"command {command_id!r} produces invalid component name")

    source_bytes = read_source(prompt, f"command {command_id}")
    source_text = source_bytes.decode("utf-8")
    title = first_heading(source_text, command_id)
    description = (
        f"Execute the VirtualBoard {title} workflow "
        f"({command_id} / {alias}). Use when the user requests this named workflow."
    )
    frontmatter = (
        "---\n"
        f"name: {component_name}\n"
        "description: >-\n"
        f"  {description}\n"
        "---\n\n"
        f"<!-- Generated from {prompt} by tools/sync_claude_plugin.py. -->\n\n"
    )
    target = Path("commands") / f"{component_name}.md"
    return GeneratedFile(target, frontmatter.encode("utf-8") + source_bytes)


def collect_expected(contract: dict[str, Any]) -> tuple[dict[Path, bytes], dict[str, int]]:
    roles = require_list(contract, "roles")
    commands = require_list(contract, "commands")
    expected: dict[Path, bytes] = {}

    role_ids: set[str] = set()
    for role in roles:
        role_id = role.get("id")
        source = role.get("agentFile")
        if not isinstance(role_id, str) or not SAFE_COMPONENT_NAME.fullmatch(role_id):
            raise ValueError(f"invalid role id: {role_id!r}")
        if role_id in role_ids:
            raise ValueError(f"duplicate role id: {role_id}")
        role_ids.add(role_id)
        if not isinstance(source, str):
            raise ValueError(f"role {role_id} has invalid agentFile")
        generated = render_agent(role_id, source)
        expected[generated.path] = generated.content

    command_names: set[str] = set()
    for command in commands:
        generated = render_command(command)
        if generated.path.name in command_names:
            raise ValueError(f"duplicate generated command: {generated.path.name}")
        command_names.add(generated.path.name)
        expected[generated.path] = generated.content

    source_skills_root = REPO_ROOT / "skills"
    skill_count = 0
    for skill_file in sorted(source_skills_root.glob("*/SKILL.md")):
        skill_count += 1
        skill_root = skill_file.parent
        skill_name = skill_root.name
        if not SAFE_COMPONENT_NAME.fullmatch(skill_name):
            raise ValueError(f"invalid skill directory name: {skill_name}")
        for source in sorted(path for path in skill_root.rglob("*") if path.is_file()):
            relative = Path("skills") / skill_name / source.relative_to(skill_root)
            expected[relative] = source.read_bytes()

    counts = {"agents": len(roles), "workflows": len(commands), "skills": skill_count}
    expectations = contract.get("pluginExpectations", {}).get("claude", {})
    if expectations != counts:
        raise ValueError(
            "contract pluginExpectations.claude does not match registered components: "
            f"expected {expectations!r}, found {counts!r}"
        )
    return expected, counts


def actual_generated_files() -> dict[Path, bytes]:
    actual: dict[Path, bytes] = {}
    for directory in GENERATED_DIRECTORIES:
        root = PLUGIN_ROOT / directory
        if not root.exists():
            continue
        for path in sorted(item for item in root.rglob("*") if item.is_file()):
            if path.name == ".DS_Store":
                continue
            actual[path.relative_to(PLUGIN_ROOT)] = path.read_bytes()
    return actual


def diff_components(expected: dict[Path, bytes]) -> list[str]:
    actual = actual_generated_files()
    errors: list[str] = []
    for path in sorted(expected.keys() - actual.keys()):
        errors.append(f"missing generated component: {path}")
    for path in sorted(actual.keys() - expected.keys()):
        errors.append(f"stale generated component: {path}")
    for path in sorted(expected.keys() & actual.keys()):
        if expected[path] != actual[path]:
            errors.append(f"out-of-date generated component: {path}")
    return errors


def write_components(expected: dict[Path, bytes]) -> None:
    resolved_plugin = PLUGIN_ROOT.resolve()
    expected_parent = (REPO_ROOT / "plugins" / "claude").resolve()
    if resolved_plugin.parent != expected_parent:
        raise ValueError(f"refusing to write outside Claude plugin directory: {resolved_plugin}")

    actual = actual_generated_files()
    for stale in sorted(actual.keys() - expected.keys()):
        (PLUGIN_ROOT / stale).unlink()
    for relative, content in expected.items():
        target = PLUGIN_ROOT / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content)
    for directory in reversed(GENERATED_DIRECTORIES):
        root = PLUGIN_ROOT / directory
        if not root.exists():
            continue
        for candidate in sorted(root.rglob("*"), reverse=True):
            if candidate.is_dir() and not any(candidate.iterdir()):
                candidate.rmdir()


def main() -> int:
    args = parse_args()
    try:
        validate_packaging_metadata()
        expected, counts = collect_expected(load_contract())
        if args.write:
            write_components(expected)
        errors = diff_components(expected)
    except (OSError, UnicodeError, ValueError) as exc:
        errors = [str(exc)]
        counts = {}

    result = {
        "success": not errors,
        "mode": "write" if args.write else "check",
        "pluginRoot": str(PLUGIN_ROOT),
        "counts": counts,
        "errors": errors,
    }
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    elif errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
    else:
        action = "Synchronized" if args.write else "Verified"
        print(
            f"{action} Claude plugin components: "
            f"{counts['agents']} agents, {counts['workflows']} workflows, "
            f"{counts['skills']} skill"
        )
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
