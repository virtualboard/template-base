#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
PLUGIN_ROOT="$REPO_ROOT/plugins/claude/virtualboard"

python3 "$REPO_ROOT/tools/sync_claude_plugin.py" --check
python3 "$REPO_ROOT/tools/sync_work_on_plugins.py" --check

if ! command -v claude >/dev/null 2>&1; then
  if [[ "${REQUIRE_CLAUDE_PLUGIN_CLI:-0}" == "1" ]]; then
    echo "ERROR: Claude Code CLI is required for plugin runtime validation" >&2
    exit 1
  fi
  echo "SKIP: Claude Code CLI is unavailable; generated inventory was verified"
  exit 0
fi

claude plugin validate "$PLUGIN_ROOT" --strict
claude plugin validate "$REPO_ROOT" --strict

TEMP_HOME="$(mktemp -d "${TMPDIR:-/tmp}/virtualboard-claude-plugin.XXXXXX")"
DETAILS_FILE="$TEMP_HOME/plugin-details.txt"
cleanup() {
  rm -rf -- "$TEMP_HOME"
}
trap cleanup EXIT HUP INT TERM

HOME="$TEMP_HOME" claude plugin marketplace add "$REPO_ROOT" --scope user >/dev/null
HOME="$TEMP_HOME" claude plugin install \
  virtualboard@virtualboard-marketplace --scope user >/dev/null
HOME="$TEMP_HOME" claude plugin details \
  virtualboard@virtualboard-marketplace >"$DETAILS_FILE"

python3 - "$REPO_ROOT" "$DETAILS_FILE" <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
details = Path(sys.argv[2]).read_text(encoding="utf-8")
contract = json.loads((root / "virtualboard.json").read_text(encoding="utf-8"))

expected_agents = {role["id"] for role in contract["roles"]}
expected_skills = {
    command["id"].replace(".", "-") for command in contract["commands"]
}
expected_skills.update(
    path.parent.name for path in (root / "skills").glob("*/SKILL.md")
)


def inventory(label: str) -> set[str]:
    match = re.search(rf"^  {label} \((\d+)\)\s*(.*)$", details, re.MULTILINE)
    if not match:
        raise SystemExit(f"missing {label} inventory in claude plugin details output")
    declared_count = int(match.group(1))
    names = {item.strip() for item in match.group(2).split(",") if item.strip()}
    if declared_count != len(names):
        raise SystemExit(
            f"{label} inventory declares {declared_count} but lists {len(names)}"
        )
    return names


actual_skills = inventory("Skills")
actual_agents = inventory("Agents")
errors = []
if actual_skills != expected_skills:
    errors.append(
        "Skills mismatch: missing="
        f"{sorted(expected_skills - actual_skills)}, "
        f"unexpected={sorted(actual_skills - expected_skills)}"
    )
if actual_agents != expected_agents:
    errors.append(
        "Agents mismatch: missing="
        f"{sorted(expected_agents - actual_agents)}, "
        f"unexpected={sorted(actual_agents - expected_agents)}"
    )
if errors:
    raise SystemExit("\n".join(errors))

print(
    "Verified installed Claude plugin inventory: "
    f"{len(actual_agents)} agents, "
    f"{len(contract['commands'])} workflows, "
    f"{len(actual_skills) - len(contract['commands'])} skill"
)
PY
