#!/usr/bin/env bash

set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$ROOT"

VB="$ROOT/.state/bin/vb"
[[ -x "$VB" ]] || {
    echo "workspace-local vb is missing; run scripts/install-vb-cli.sh --ensure-latest .state/bin" >&2
    exit 1
}
SELECTED_VERSION=$(tr -d '[:space:]' < "$ROOT/.vb-version")
[[ "$("$VB" version)" == "$SELECTED_VERSION" ]] || {
    echo "workspace-local vb does not match $SELECTED_VERSION" >&2
    exit 1
}
export PATH="$ROOT/.state/bin:$PATH"

python3 tools/check_contract.py
python3 tools/build_docs.py --check
python3 tools/sync_agent_catalog.py --check
python3 tools/sync_command_contracts.py --check
python3 tools/sync_command_catalogs.py --check
python3 tools/sync_report_instructions.py --check
python3 tools/sync_report_headers.py --check
python3 tools/sync_claude_plugin.py --check
python3 tools/sync_work_on_plugins.py --check

INDEX_POLICY=${VIRTUALBOARD_INDEX_POLICY:-auto}
case "$INDEX_POLICY" in
    check)
        CHECK_ROOT_INDEX=true
        ;;
    skip)
        CHECK_ROOT_INDEX=false
        ;;
    auto)
        CHECK_ROOT_INDEX=false
        CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || true)
        if [[ "$CURRENT_BRANCH" == main \
            || ${GITHUB_REF:-} == refs/heads/main \
            || ( ${GITHUB_ACTIONS:-} == true && ${GITHUB_EVENT_NAME:-} != pull_request ) ]]; then
            CHECK_ROOT_INDEX=true
        fi
        ;;
    *)
        echo "VIRTUALBOARD_INDEX_POLICY must be auto, check, or skip" >&2
        exit 1
        ;;
esac

if [[ "$CHECK_ROOT_INDEX" == true ]]; then
    echo "Checking the integration-branch feature index..."
    "$VB" --root "$ROOT" index --check
else
    echo "Skipping the shared root index on a feature branch; main/CI owns it."
fi
echo "Checking the immutable demo feature index..."
"$VB" --root "$ROOT/examples/demo-project" index --check

echo "Checking Bash syntax..."
while IFS= read -r script; do
    bash -n "$script"
done < <(find scripts tests -type f -name '*.sh' -print | sort)

echo "Running shell contract tests..."
while IFS= read -r test_script; do
    [[ "$test_script" == "tests/test-cli-lifecycle.sh" ]] && continue
    echo "==> $test_script"
    bash "$test_script"
done < <(find tests -maxdepth 1 -type f \( -name 'test-*.sh' -o -name 'test_*.sh' \) -print | sort)

echo "Running pinned CLI lifecycle compatibility gate..."
bash tests/test-cli-lifecycle.sh

if find tests -maxdepth 1 -type f -name 'test_*.py' -print -quit | grep -q .; then
    command -v python3 >/dev/null 2>&1 || {
        echo "python3 is required for Python contract tests" >&2
        exit 1
    }
    echo "Running Python contract tests..."
    python3 -m unittest discover -s tests -p 'test_*.py'
fi

echo "All automation contract tests passed."
