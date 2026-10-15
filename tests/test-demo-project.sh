#!/usr/bin/env bash

set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
DEMO="$ROOT/examples/demo-project"
VB="$ROOT/.state/bin/vb"

[[ -x "$VB" ]] || {
    echo "missing pinned workspace CLI: $VB" >&2
    exit 1
}

cmp "$ROOT/schemas/frontmatter.schema.json" "$DEMO/schemas/frontmatter.schema.json"
cmp "$ROOT/schemas/system-spec.schema.json" "$DEMO/schemas/system-spec.schema.json"
cmp "$ROOT/templates/feature.md" "$DEMO/templates/feature.md"
[[ "$(tr -d '[:space:]' < "$DEMO/.template-version")" == "0.7.0" ]]

OUTPUT=$("$VB" --root "$DEMO" validate)
grep -q 'Validated 5 features and 1 specs' <<< "$OUTPUT"
"$VB" --root "$DEMO" index --check >/dev/null

BEFORE=$(sha256sum "$DEMO/features/INDEX.md" 2>/dev/null | awk '{print $1}' || shasum -a 256 "$DEMO/features/INDEX.md" | awk '{print $1}')
"$VB" --root "$DEMO" index --dry-run >/dev/null
AFTER=$(sha256sum "$DEMO/features/INDEX.md" 2>/dev/null | awk '{print $1}' || shasum -a 256 "$DEMO/features/INDEX.md" | awk '{print $1}')
[[ "$BEFORE" == "$AFTER" ]]

echo "demo project validated with five lifecycle features and one system spec"
