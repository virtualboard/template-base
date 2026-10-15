#!/bin/sh

set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
TMPDIR_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/vb-root-test.XXXXXX")
trap 'rm -rf "$TMPDIR_ROOT"' EXIT HUP INT TERM
TMPDIR_ROOT=$(CDPATH= cd -- "$TMPDIR_ROOT" && pwd -P)

fail() {
    echo "test_vb_root: $*" >&2
    exit 1
}

mkdir -p "$TMPDIR_ROOT/root-project/nested/deep"
touch "$TMPDIR_ROOT/root-project/virtualboard.json"
actual=$($ROOT/bin/vb-root "$TMPDIR_ROOT/root-project/nested/deep")
[ "$actual" = "$TMPDIR_ROOT/root-project" ] || fail "root layout resolved to $actual"

mkdir -p "$TMPDIR_ROOT/installed-project/.virtualboard" "$TMPDIR_ROOT/installed-project/src"
touch "$TMPDIR_ROOT/installed-project/.virtualboard/virtualboard.json"
actual=$($ROOT/bin/vb-root "$TMPDIR_ROOT/installed-project/src")
[ "$actual" = "$TMPDIR_ROOT/installed-project/.virtualboard" ] ||
    fail "installed layout resolved to $actual"

actual=$(VIRTUALBOARD_ROOT="$TMPDIR_ROOT/root-project" "$ROOT/bin/vb-root" /)
[ "$actual" = "$TMPDIR_ROOT/root-project" ] || fail "environment override resolved to $actual"

if "$ROOT/bin/vb-root" "$TMPDIR_ROOT" >/dev/null 2>&1; then
    fail "missing workspace unexpectedly resolved"
fi

mkdir -p "$TMPDIR_ROOT/outside-workspace/features/backlog" "$TMPDIR_ROOT/symlink-project"
cp "$ROOT/virtualboard.json" "$TMPDIR_ROOT/outside-workspace/virtualboard.json"
ln -s "$TMPDIR_ROOT/outside-workspace" "$TMPDIR_ROOT/symlink-project/.virtualboard"
if resolved=$($ROOT/bin/vb-root "$TMPDIR_ROOT/symlink-project" 2>/dev/null); then
    "$ROOT/.state/bin/vb" --root "$resolved" --actor resolver-probe new "Must Not Escape" >/dev/null 2>&1 || true
    fail "repository-controlled .virtualboard symlink resolved to $resolved"
fi
if find "$TMPDIR_ROOT/outside-workspace/features" -type f -name 'FTR-*.md' -print -quit | grep -q .; then
    fail "resolver-to-CLI probe mutated the symlink target"
fi

echo "vb-root contract tests passed"
