#!/usr/bin/env bash

set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
VB="$ROOT/.state/bin/vb"

[[ -x "$VB" ]] || {
    echo "missing pinned workspace CLI: $VB" >&2
    exit 1
}

HELP_OUTPUT=$("$VB" help)
COMMANDS=$(python3 -c '
import json, pathlib
contract = json.loads((pathlib.Path(__import__("sys").argv[1]) / "virtualboard.json").read_text())
print("\n".join(contract["cli"]["requiredCommands"]))
' "$ROOT")

COUNT=0
while IFS= read -r command; do
    [[ -n "$command" ]] || continue
    if ! grep -Eq "^  ${command}[[:space:]]" <<< "$HELP_OUTPUT"; then
        echo "required pinned-CLI command is missing from help: $command" >&2
        exit 1
    fi
    COUNT=$((COUNT + 1))
done <<< "$COMMANDS"

[[ "$COUNT" -gt 0 ]] || {
    echo "cli.requiredCommands is empty" >&2
    exit 1
}

echo "pinned CLI exposes all $COUNT contract-required commands"
