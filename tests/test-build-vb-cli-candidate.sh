#!/usr/bin/env bash

set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
SOURCE_SCRIPT="$ROOT/scripts/build-vb-cli-candidate.sh"
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/vb-build-candidate-test.XXXXXX")
TESTS_RUN=0

cleanup() {
    rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
    echo "not ok - $*" >&2
    exit 1
}

pass() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo "ok $TESTS_RUN - $*"
}

FIXTURE_ROOT="$TEST_ROOT/template"
FIXTURE_SCRIPT="$FIXTURE_ROOT/scripts/build-vb-cli-candidate.sh"
CLI_SOURCE="$TEST_ROOT/vb-cli"
FAKE_GO="$TEST_ROOT/fake-go"
ARCHIVE="$TEST_ROOT/template.tar.gz"
OUTPUT="$TEST_ROOT/out/vb"

mkdir -p "$FIXTURE_ROOT/scripts" "$CLI_SOURCE/internal/version"
cp "$SOURCE_SCRIPT" "$FIXTURE_SCRIPT"
chmod +x "$FIXTURE_SCRIPT"
printf 'v1.2.3\n' > "$FIXTURE_ROOT/.vb-version"
printf 'package version\n\nconst Current = "v1.2.3"\n' > "$CLI_SOURCE/internal/version/version.go"
printf 'package main\n\nfunc main() {}\n' > "$CLI_SOURCE/main.go"
printf 'ignored.go\n' > "$CLI_SOURCE/.gitignore"
git -C "$CLI_SOURCE" init -q
git -C "$CLI_SOURCE" add .
git -C "$CLI_SOURCE" \
    -c user.name=Automation-Test \
    -c user.email=automation-test@example.invalid \
    -c commit.gpgsign=false \
    commit -qm 'reviewed source'
SOURCE_REF=$(git -C "$CLI_SOURCE" rev-parse HEAD)
printf '%s\n' "$SOURCE_REF" > "$FIXTURE_ROOT/.vb-cli-source-ref"
printf 'template archive fixture\n' > "$ARCHIVE"

cat > "$FAKE_GO" <<'FAKE_GO'
#!/usr/bin/env bash
set -Eeuo pipefail
if [[ ${1-} == env && ${2-} == GOVERSION ]]; then
    printf 'go1.25.0\n'
    exit 0
fi
[[ ${1-} == build ]] || exit 64
[[ ! -d .git ]] || {
    echo 'candidate was built from a live checkout' >&2
    exit 65
}
[[ ! -e ignored.go ]] || {
    echo 'ignored checkout content entered the exact-source build' >&2
    exit 66
}
output=
shift
while [[ $# -gt 0 ]]; do
    if [[ $1 == -o && $# -ge 2 ]]; then
        output=$2
        shift 2
    else
        shift
    fi
done
[[ -n "$output" ]]
mkdir -p "$(dirname -- "$output")"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "%s"\n' "$FAKE_VERSION" > "$output"
chmod +x "$output"
FAKE_GO
chmod +x "$FAKE_GO"

# Ignored checkout content is absent from the exact commit archive and cannot
# influence the candidate.
printf 'package main\n' > "$CLI_SOURCE/ignored.go"
GO="$FAKE_GO" FAKE_VERSION=v1.2.3 \
    "$FIXTURE_SCRIPT" "$CLI_SOURCE" "$ARCHIVE" "$OUTPUT" \
    >"$TEST_ROOT/clean.out" 2>"$TEST_ROOT/clean.err" \
    || fail "clean exact-source build failed"
[[ "$($OUTPUT version)" == v1.2.3 ]] || fail "candidate version was not verified"
pass "builds only the exact selected commit archive"

printf '// dirty\n' >> "$CLI_SOURCE/internal/version/version.go"
if GO="$FAKE_GO" FAKE_VERSION=v1.2.3 \
    "$FIXTURE_SCRIPT" "$CLI_SOURCE" "$ARCHIVE" "$OUTPUT" \
    >"$TEST_ROOT/dirty.out" 2>"$TEST_ROOT/dirty.err"; then
    fail "dirty tracked source was accepted"
fi
grep -q 'checkout must be clean' "$TEST_ROOT/dirty.err" \
    || fail "dirty tracked source error was not useful"
git -C "$CLI_SOURCE" restore internal/version/version.go
pass "rejects tracked source changes"

printf 'package main\n' > "$CLI_SOURCE/untracked.go"
if GO="$FAKE_GO" FAKE_VERSION=v1.2.3 \
    "$FIXTURE_SCRIPT" "$CLI_SOURCE" "$ARCHIVE" "$OUTPUT" \
    >"$TEST_ROOT/untracked.out" 2>"$TEST_ROOT/untracked.err"; then
    fail "untracked source was accepted"
fi
grep -q 'checkout must be clean' "$TEST_ROOT/untracked.err" \
    || fail "untracked source error was not useful"
pass "rejects untracked source changes"

echo "1..$TESTS_RUN"
