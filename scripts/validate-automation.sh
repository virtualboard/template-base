#!/usr/bin/env bash

# CI entry point for repository automation contracts. The behavioral lifecycle
# gate separately proves that both text and JSON validation failures are
# non-zero, so this entry point can use the concise text summary.

set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$ROOT"

VB="$ROOT/.state/bin/vb"
[[ -x "$VB" ]] || {
    echo "workspace-local vb is required; run scripts/install-vb-cli.sh --ensure-latest .state/bin first" >&2
    exit 1
}
export PATH="$ROOT/.state/bin:$PATH"

SELECTED_VERSION=$(tr -d '[:space:]' < .vb-version)
SELECTED_VERSION=${SELECTED_VERSION#v}
INSTALLED_VERSION=$("$VB" version | sed -E -n 's/.*v?([0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?).*/\1/p')
if [[ -z "$INSTALLED_VERSION" || "$INSTALLED_VERSION" != "$SELECTED_VERSION" ]]; then
    echo "vb version mismatch: selected v$SELECTED_VERSION, installed ${INSTALLED_VERSION:-unknown}" >&2
    echo "run scripts/install-vb-cli.sh --ensure-latest before validation" >&2
    exit 1
fi

echo "Validating JSON syntax..."
python3 - <<'PY'
import json
from pathlib import Path

for path in sorted(Path(".").rglob("*.json")):
    if ".git" in path.parts or ".state" in path.parts:
        continue
    with path.open(encoding="utf-8") as handle:
        json.load(handle)
PY

echo "Validating VirtualBoard features and system specs..."
"$VB" --root "$ROOT" validate

bash tests/run.sh
