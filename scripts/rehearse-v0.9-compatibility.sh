#!/usr/bin/env bash

# Prove whether the exact template candidate remains usable by the immutable
# v0.9.0 client that downloads moving main. This is a main-promotion gate, not
# a template-release gate: an incompatible candidate must remain on its release
# branch even after its immutable release is published.

set -Eeuo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <vb-v0.9-source> <template-archive>" >&2
    exit 2
fi

V09_REF=d0d05d656c721ade944ad4dd61e1aa7d3ffb0f8a
SOURCE=$(cd -- "$1" && pwd -P)
ARCHIVE=$(cd -- "$(dirname -- "$2")" && pwd -P)/$(basename -- "$2")
GO_BIN=${GO:-go}

[[ "$(git -C "$SOURCE" rev-parse HEAD)" == "$V09_REF" ]] || {
    echo "legacy rehearsal requires vb-cli v0.9.0 commit $V09_REF" >&2
    exit 1
}
[[ "$($GO_BIN env GOVERSION)" == go1.25.0 ]] || {
    echo "exact Go 1.25.0 is required for the v0.9 rehearsal" >&2
    exit 1
}
[[ -f "$ARCHIVE" && ! -L "$ARCHIVE" ]] || {
    echo "template archive is not a regular file: $ARCHIVE" >&2
    exit 1
}

WORK=$(mktemp -d "${TMPDIR:-/tmp}/vb-v09-rehearsal.XXXXXX")
SERVER_PID=""
cleanup() {
    if [[ -n "$SERVER_PID" ]]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
    rm -rf "$WORK"
}
trap cleanup EXIT

mkdir -p "$WORK/source" "$WORK/server" "$WORK/app"
git -C "$SOURCE" archive "$V09_REF" | tar -x -C "$WORK/source"
cp "$ARCHIVE" "$WORK/server/template.zip"
VERSION_ENTRY=$(unzip -Z1 "$ARCHIVE" | awk -F/ '$2 == "version.txt" && NF == 2 { print }')
test "$(printf '%s\n' "$VERSION_ENTRY" | sed '/^$/d' | wc -l | tr -d ' ')" = 1
unzip -p "$ARCHIVE" "$VERSION_ENTRY" > "$WORK/server/version.txt"

python3 - "$WORK/server" "$WORK/port" <<'PY' &
import functools
import http.server
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
port_file = pathlib.Path(sys.argv[2])
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(root))
server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
port_file.write_text(str(server.server_port), encoding="ascii")
server.serve_forever()
PY
SERVER_PID=$!

for _ in $(seq 1 100); do
    [[ -s "$WORK/port" ]] && break
    sleep 0.05
done
[[ -s "$WORK/port" ]] || { echo "local rehearsal server did not start" >&2; exit 1; }
PORT=$(cat "$WORK/port")

python3 - "$WORK/source/cmd/init.go" "$PORT" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
port = sys.argv[2]
source = path.read_text(encoding="utf-8")
old_archive = 'const templateZipURL = "https://github.com/virtualboard/template-base/archive/refs/heads/main.zip"'
old_version = 'const templateVersionURL = "https://raw.githubusercontent.com/virtualboard/template-base/main/version.txt"'
if source.count(old_archive) != 1 or source.count(old_version) != 1:
    raise SystemExit("v0.9 source no longer matches the immutable rehearsal patch")
source = source.replace(old_archive, f'const templateZipURL = "http://127.0.0.1:{port}/template.zip"')
source = source.replace(old_version, f'const templateVersionURL = "http://127.0.0.1:{port}/version.txt"')
path.write_text(source, encoding="utf-8")
PY

(
    cd "$WORK/source"
    "$GO_BIN" build -trimpath -buildvcs=false -o "$WORK/vb-v0.9.0" .
)
"$WORK/vb-v0.9.0" --root "$WORK/app" init
VIRTUALBOARD_ROOT="$WORK/app/.virtualboard"
"$WORK/vb-v0.9.0" --root "$VIRTUALBOARD_ROOT" validate
"$WORK/vb-v0.9.0" --root "$VIRTUALBOARD_ROOT" new "Legacy compatibility probe" compatibility
"$WORK/vb-v0.9.0" --root "$VIRTUALBOARD_ROOT" validate
"$WORK/vb-v0.9.0" --root "$VIRTUALBOARD_ROOT" index

echo "v0.9.0 moving-main compatibility rehearsal passed"
