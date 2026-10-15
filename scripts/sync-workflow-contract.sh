#!/usr/bin/env bash
# Copy the canonical compatibility fixture into independent Go repositories.
set -euo pipefail
base="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
check=false
if [[ "${1:-}" == --check ]]; then check=true; shift; fi
if [[ $# == 0 ]]; then set -- "$base/../vb-cli" "$base/../herdr-virtualboard"; fi
for repository in "$@"; do
  [[ -f "$repository/go.mod" ]] || { echo "Not a Go repository: $repository" >&2; exit 1; }
  target="$repository/testdata/workflow-contract.json"
  if $check; then
    cmp "$base/schemas/workflow-contract.json" "$target" || { echo "Workflow contract differs in $repository; sync and review all consumers." >&2; exit 1; }
  else
    mkdir -p "$repository/testdata"
    cp "$base/schemas/workflow-contract.json" "$target"
  fi
done
