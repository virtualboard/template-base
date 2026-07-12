#!/usr/bin/env bash

set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
INSTALLER="$ROOT/scripts/install-vb-cli.sh"
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/vb-installer-test.XXXXXX")
# macOS exposes /var and /tmp as compatibility symlinks. Pass the physical path
# so the installer can enforce its no-symlink destination invariant.
TEST_ROOT=$(cd -- "$TEST_ROOT" && pwd -P)
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

hash_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

binary_name() {
    local os arch
    case "$(uname -s)" in
        Darwin) os=macos ;;
        Linux) os=linux ;;
        *) fail "unsupported test OS" ;;
    esac
    case "$(uname -m)" in
        x86_64|amd64) arch=amd64 ;;
        arm64|aarch64) arch=arm64 ;;
        *) fail "unsupported test architecture" ;;
    esac
    printf 'vb-%s-%s\n' "$os" "$arch"
}

make_binary() {
    local path=$1
    local version=$2
    cat > "$path" <<EOF
#!/usr/bin/env bash
case "\${1-}" in
    version) echo "v$version" ;;
    upgrade)
        [[ -n "\${MOCK_UPGRADE_MARKER:-}" ]] && : > "\$MOCK_UPGRADE_MARKER"
        exit 91
        ;;
    *) exit 2 ;;
esac
EOF
    chmod +x "$path"
}

make_curl_mock() {
    local path=$1
    cat > "$path" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
destination=
url=
while [[ $# -gt 0 ]]; do
    case "$1" in
        --output)
            destination=$2
            shift 2
            ;;
        --connect-timeout|--max-time|--max-filesize|--retry|--retry-delay)
            shift 2
            ;;
        --fail|--silent|--show-error|--location)
            shift
            ;;
        *)
            url=$1
            shift
            ;;
    esac
done
[[ -n "$destination" && -n "$url" ]]
printf '%s\n' "$url" >> "$MOCK_CURL_LOG"
if [[ "$url" == */checksums.txt ]]; then
    [[ "${MOCK_FAIL_CHECKSUM_DOWNLOAD:-0}" != 1 ]] || exit 22
    cp "$MOCK_CHECKSUMS" "$destination"
else
    cp "$MOCK_ASSET" "$destination"
fi
EOF
    chmod +x "$path"
}

new_case() {
    local name=$1
    local selected_version=$2
    local downloaded_version=$3
    CASE_DIR="$TEST_ROOT/$name"
    mkdir -p "$CASE_DIR/bin" "$CASE_DIR/dest" "$CASE_DIR/work"
    VERSION_FILE="$CASE_DIR/version"
    ASSET="$CASE_DIR/asset"
    CHECKSUMS="$CASE_DIR/checksums.txt"
    CURL_LOG="$CASE_DIR/curl.log"
    printf 'v%s\n' "$selected_version" > "$VERSION_FILE"
    make_binary "$ASSET" "$downloaded_version"
    printf '%s  %s\n' "$(hash_file "$ASSET")" "$(binary_name)" > "$CHECKSUMS"
    make_curl_mock "$CASE_DIR/bin/curl"
    : > "$CURL_LOG"
}

run_installer() {
    env \
        PATH="$CASE_DIR/bin:$PATH" \
        VB_VERSION_FILE="$VERSION_FILE" \
        MOCK_ASSET="$ASSET" \
        MOCK_CHECKSUMS="$CHECKSUMS" \
        MOCK_CURL_LOG="$CURL_LOG" \
        MOCK_FAIL_CHECKSUM_DOWNLOAD="${MOCK_FAIL_CHECKSUM_DOWNLOAD:-0}" \
        MOCK_UPGRADE_MARKER="$CASE_DIR/upgrade-called" \
        VB_INSTALLER_TESTING="${VB_INSTALLER_TESTING:-0}" \
        VB_INSTALLER_TEST_FAIL_ACTIVATION="${VB_INSTALLER_TEST_FAIL_ACTIVATION:-0}" \
        "$INSTALLER" "$@"
}

# Exact version install works from a directory unrelated to the repository.
REPOSITORY_VERSION=$(tr -d '[:space:]v' < "$ROOT/.vb-version")
new_case cwd-independent "$REPOSITORY_VERSION" "$REPOSITORY_VERSION"
(
    cd "$CASE_DIR/work"
    env \
        PATH="$CASE_DIR/bin:$PATH" \
        MOCK_ASSET="$ASSET" \
        MOCK_CHECKSUMS="$CHECKSUMS" \
        MOCK_CURL_LOG="$CURL_LOG" \
        "$INSTALLER" --ensure-latest "$CASE_DIR/dest"
) >/dev/null
[[ "$("$CASE_DIR/dest/vb" version)" == "v$REPOSITORY_VERSION" ]] || fail "exact version was not installed"
pass "installs and verifies the selected version from any working directory"

# Release manifests may use the standard sha256sum `./asset` filename form.
new_case dot-slash-checksum 1.2.3 1.2.3
printf '%s  ./%s\n' "$(hash_file "$ASSET")" "$(binary_name)" > "$CHECKSUMS"
run_installer --ensure-latest "$CASE_DIR/dest" >/dev/null
[[ "$("$CASE_DIR/dest/vb" version)" == v1.2.3 ]] || fail "./ checksum entry was not accepted"
pass "accepts the release manifest's optional ./ filename prefix"

# A mismatched vb already on PATH must not trigger `vb upgrade` to an unpinned release.
new_case mismatch-does-not-upgrade 2.3.4 2.3.4
make_binary "$CASE_DIR/bin/vb" 9.9.9
run_installer --ensure-latest "$CASE_DIR/dest" >/dev/null
[[ ! -e "$CASE_DIR/upgrade-called" ]] || fail "installer invoked vb upgrade"
[[ "$("$CASE_DIR/dest/vb" version)" == v2.3.4 ]] || fail "selected version did not replace mismatch"
pass "replaces mismatches directly without invoking unpinned upgrade logic"

# Exact installed bytes are trusted only after the release checksum manifest is
# fetched and matched; the binary asset itself need not be downloaded.
new_case exact-is-manifest-verified 3.4.5 3.4.5
cp "$ASSET" "$CASE_DIR/bin/vb"
chmod +x "$CASE_DIR/bin/vb"
run_installer --ensure-latest >/dev/null
[[ "$(wc -l < "$CURL_LOG" | tr -d ' ')" == 1 ]] || fail "verified no-op fetched an unexpected number of artifacts"
grep -q '/checksums.txt$' "$CURL_LOG" || fail "verified no-op did not authenticate through the checksum manifest"
pass "exact installed bytes are accepted only after manifest verification"

# An explicit workspace destination is authenticated independently of a
# different PATH entry.
new_case explicit-destination-is-verified 3.4.6 3.4.6
cp "$ASSET" "$CASE_DIR/dest/vb"
chmod +x "$CASE_DIR/dest/vb"
make_binary "$CASE_DIR/bin/vb" 9.9.9
run_installer --ensure-latest "$CASE_DIR/dest" >/dev/null
[[ "$(wc -l < "$CURL_LOG" | tr -d ' ')" == 1 ]] || fail "explicit verified destination fetched an unexpected number of artifacts"
[[ "$("$CASE_DIR/dest/vb" version)" == v3.4.6 ]] || fail "explicit destination changed"
pass "exact workspace-local destination is manifest-verified despite PATH mismatch"

# A tampered destination cannot win by printing the selected version and must
# not execute before its bytes match the trusted manifest.
new_case self-report-is-not-integrity 3.4.7 3.4.7
cat > "$CASE_DIR/dest/vb" <<EOF
#!/usr/bin/env bash
: > "$CASE_DIR/tampered-executed"
echo v3.4.7
EOF
chmod +x "$CASE_DIR/dest/vb"
run_installer --ensure-latest "$CASE_DIR/dest" >/dev/null
[[ ! -e "$CASE_DIR/tampered-executed" ]] || fail "unverified destination executed during integrity probe"
[[ "$("$CASE_DIR/dest/vb" version)" == v3.4.7 ]] || fail "manifest asset did not replace tampered destination"
pass "self-reported version never substitutes for destination integrity"

# Checksum mismatches fail before replacing an existing destination.
new_case checksum-fails-closed 4.5.6 4.5.6
make_binary "$CASE_DIR/dest/vb" 7.7.7
printf '%064d  %s\n' 0 "$(binary_name)" > "$CHECKSUMS"
if run_installer --ensure-latest "$CASE_DIR/dest" >/dev/null 2>&1; then
    fail "checksum mismatch was accepted"
fi
[[ "$("$CASE_DIR/dest/vb" version)" == v7.7.7 ]] || fail "failed checksum replaced destination"
pass "checksum mismatch fails closed without replacing the destination"

# A missing checksum artifact is fatal.
new_case checksum-download-required 5.6.7 5.6.7
if MOCK_FAIL_CHECKSUM_DOWNLOAD=1 run_installer --ensure-latest "$CASE_DIR/dest" >/dev/null 2>&1; then
    fail "missing checksum artifact was accepted"
fi
[[ ! -e "$CASE_DIR/dest/vb" ]] || fail "binary installed without checksum artifact"
pass "checksum artifact is mandatory"

# The downloaded binary is version-checked before replacement as well as after it.
new_case downloaded-version-mismatch 6.7.8 6.7.9
make_binary "$CASE_DIR/dest/vb" 8.8.8
if run_installer --ensure-latest "$CASE_DIR/dest" >/dev/null 2>&1; then
    fail "downloaded version mismatch was accepted"
fi
[[ "$("$CASE_DIR/dest/vb" version)" == v8.8.8 ]] || fail "wrong-version download replaced destination"
pass "downloaded version mismatch fails before replacement"

# Download size bounds are enforced even when a server omits Content-Length or
# a curl implementation cannot reject the transfer early.
new_case oversized-download 7.8.9 7.8.9
make_binary "$CASE_DIR/dest/vb" 9.9.8
if VB_BINARY_MAX_BYTES=1 run_installer --ensure-latest "$CASE_DIR/dest" >/dev/null 2>&1; then
    fail "oversized binary download was accepted"
fi
[[ "$("$CASE_DIR/dest/vb" version)" == v9.9.8 ]] || fail "oversized download replaced destination"
pass "download bounds fail closed without replacing the destination"

# A linked destination ancestor is rejected before download and cannot redirect
# the installation outside the selected tree.
new_case linked-ancestor 8.9.0 8.9.0
mkdir -p "$CASE_DIR/escape"
ln -s "$CASE_DIR/escape" "$CASE_DIR/linked"
if run_installer --ensure-latest "$CASE_DIR/linked/nested" >/dev/null 2>&1; then
    fail "symlinked destination ancestor was accepted"
fi
[[ ! -e "$CASE_DIR/escape/nested/vb" ]] || fail "installer escaped through a destination symlink"
[[ ! -s "$CURL_LOG" ]] || fail "symlinked destination was rejected only after network access"
pass "rejects linked destination ancestors before network access"

# A symlink at the destination leaf is also rejected rather than replaced or
# executed as part of the exact-version probe.
new_case linked-leaf 9.0.1 9.0.1
make_binary "$CASE_DIR/outside-vb" 9.0.1
ln -s "$CASE_DIR/outside-vb" "$CASE_DIR/dest/vb"
if run_installer --ensure-latest "$CASE_DIR/dest" >/dev/null 2>&1; then
    fail "symlinked destination binary was accepted"
fi
[[ "$("$CASE_DIR/outside-vb" version)" == v9.0.1 ]] || fail "symlink target was modified"
[[ ! -s "$CURL_LOG" ]] || fail "symlinked leaf was rejected only after network access"
pass "rejects a linked destination binary before executing it"

# Failure immediately before the atomic rename preserves the prior executable.
# This also proves staging and cleanup occur without exposing a half-written vb.
new_case activation-failure 9.1.2 9.1.2
make_binary "$CASE_DIR/dest/vb" 1.0.0
if VB_INSTALLER_TESTING=1 VB_INSTALLER_TEST_FAIL_ACTIVATION=1 \
    run_installer --ensure-latest "$CASE_DIR/dest" >/dev/null 2>&1; then
    fail "injected activation failure unexpectedly succeeded"
fi
[[ "$("$CASE_DIR/dest/vb" version)" == v1.0.0 ]] || fail "activation failure damaged the existing binary"
if find "$CASE_DIR/dest" -maxdepth 1 -name '.vb.install.*' -print -quit | grep -q .; then
    fail "activation failure left a staging file behind"
fi
pass "atomic activation failure preserves the existing binary and cleans staging"

# Parent traversal is not accepted as an alternate way to evade component
# checks, even if it would resolve to an otherwise writable directory.
new_case parent-traversal 9.2.3 9.2.3
if run_installer --ensure-latest "$CASE_DIR/work/../dest" >/dev/null 2>&1; then
    fail "destination containing parent traversal was accepted"
fi
[[ ! -s "$CURL_LOG" ]] || fail "parent traversal was rejected only after network access"
pass "rejects parent traversal in destination paths"

echo "1..$TESTS_RUN"
