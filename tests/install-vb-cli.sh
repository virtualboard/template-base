#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

CASE_DIR="$TMP/project"
FAKE_BIN="$TMP/bin"
INSTALL_DIR="$TMP/install"
mkdir -p "$CASE_DIR" "$FAKE_BIN" "$INSTALL_DIR"
printf 'v0.8.1\n' > "$CASE_DIR/.vb-version"

cat > "$TMP/release-vb" <<'EOF'
#!/bin/sh
[ "${1:-}" = version ] || exit 2
printf '%s\n' "$INSTALL_TEST_BINARY_VERSION"
EOF
chmod +x "$TMP/release-vb"

cat > "$FAKE_BIN/vb" <<'EOF'
#!/bin/sh
if [ "${1:-}" = version ]; then
  printf 'v0.7.0\n'
elif [ "${1:-}" = upgrade ]; then
  printf 'upgrade-called\n' >> "$INSTALL_TEST_LOG"
  exit 99
else
  exit 2
fi
EOF
chmod +x "$FAKE_BIN/vb"

cat > "$FAKE_BIN/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
out=""
url=""
while (($#)); do
  if [[ "$1" == -o ]]; then
    out="$2"
    shift 2
  else
    url="$1"
    shift
  fi
done
if [[ "$url" == *api.github.com* ]]; then
  printf '{"tag_name":"v9.9.9"}\n'
elif [[ "$url" == *checksums.txt ]]; then
  if [[ "${INSTALL_TEST_BAD_CHECKSUM:-0}" == 1 ]]; then
    printf '%064d  ./%s\n' 0 "$(cat "$INSTALL_TEST_ASSET")"
  else
    name=$(cat "$INSTALL_TEST_ASSET")
    digest=$(shasum -a 256 "$INSTALL_TEST_BINARY" | awk '{print $1}')
    printf '%s  ./%s\n' "$digest" "$name"
  fi > "$out"
elif [[ "$url" == */releases/download/* ]]; then
  printf '%s\n' "$url" >> "$INSTALL_TEST_LOG"
  printf '%s\n' "${url##*/}" > "$INSTALL_TEST_ASSET"
  cp "$INSTALL_TEST_BINARY" "$out"
else
  echo "unexpected installer URL: $url" >&2
  exit 1
fi
EOF
chmod +x "$FAKE_BIN/curl"

export INSTALL_TEST_BINARY="$TMP/release-vb"
export INSTALL_TEST_BINARY_VERSION="v0.8.1"
export INSTALL_TEST_LOG="$TMP/requests.log"
export INSTALL_TEST_ASSET="$TMP/asset-name"
export PATH="$FAKE_BIN:/usr/bin:/bin:/usr/sbin:/sbin"

(
  cd "$CASE_DIR"
  bash "$ROOT/scripts/install-vb-cli.sh" --ensure-latest "$INSTALL_DIR" > "$TMP/install.log"
)

grep -q '/releases/download/v0.8.1/vb-' "$INSTALL_TEST_LOG"
if grep -q 'upgrade-called' "$INSTALL_TEST_LOG"; then
  echo "installer used vb upgrade instead of the selected pinned release" >&2
  exit 1
fi
"$INSTALL_DIR/vb" version | grep -qx 'v0.8.1'

PROTECTED_DIR="$TMP/protected"
mkdir -p "$PROTECTED_DIR"
chmod 0555 "$PROTECTED_DIR"
if (
  cd "$CASE_DIR"
  bash "$ROOT/scripts/install-vb-cli.sh" --ensure-latest "$PROTECTED_DIR" > "$TMP/sudo-refusal.log" 2>&1
); then
  echo "installer accepted a protected path without --allow-sudo" >&2
  exit 1
fi
grep -q 'requires elevated privileges' "$TMP/sudo-refusal.log"
chmod 0755 "$PROTECTED_DIR"

mkdir -p "$TMP/unpinned-project"
export INSTALL_TEST_BINARY_VERSION="v9.9.9"
(
  cd "$TMP/unpinned-project"
  bash "$ROOT/scripts/install-vb-cli.sh" --ensure-latest "$INSTALL_DIR" > "$TMP/latest.log"
)
grep -q '/releases/download/v9.9.9/vb-' "$INSTALL_TEST_LOG"
"$INSTALL_DIR/vb" version | grep -qx 'v9.9.9'

printf 'preserve-me\n' > "$INSTALL_DIR/vb"
export INSTALL_TEST_BINARY_VERSION="v0.8.1"
if (
  cd "$CASE_DIR"
  INSTALL_TEST_BAD_CHECKSUM=1 bash "$ROOT/scripts/install-vb-cli.sh" --ensure-latest "$INSTALL_DIR" > "$TMP/bad-checksum.log" 2>&1
); then
  echo "installer accepted a bad checksum" >&2
  exit 1
fi
grep -q 'checksum mismatch' "$TMP/bad-checksum.log"
grep -qx 'preserve-me' "$INSTALL_DIR/vb"

export INSTALL_TEST_BINARY_VERSION="v0.8.2"
if (
  cd "$CASE_DIR"
  bash "$ROOT/scripts/install-vb-cli.sh" --ensure-latest "$INSTALL_DIR" > "$TMP/mismatched-version.log" 2>&1
); then
  echo "installer accepted a binary whose version disagreed with its release tag" >&2
  exit 1
fi
grep -q 'does not match binary version' "$TMP/mismatched-version.log"
grep -qx 'preserve-me' "$INSTALL_DIR/vb"

echo "installer: exact tags, checksum/version refusal, explicit privilege gate, and existing-file preservation passed"
