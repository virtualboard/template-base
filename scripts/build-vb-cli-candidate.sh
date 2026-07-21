#!/usr/bin/env bash

# Build the exact reviewed CLI source candidate selected by
# .vb-cli-source-ref. The template archive digest is compiled into the result,
# so the same binary can exercise an unpublished template candidate.

set -Eeuo pipefail

if [[ $# -ne 3 ]]; then
    echo "usage: $0 <vb-cli-source> <template-archive> <output-binary>" >&2
    exit 2
fi

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
CLI_SOURCE=$(cd -- "$1" && pwd -P)
ARCHIVE=$(cd -- "$(dirname -- "$2")" && pwd -P)/$(basename -- "$2")
mkdir -p "$(dirname -- "$3")"
OUTPUT_DIR=$(cd -- "$(dirname -- "$3")" && pwd -P)
OUTPUT="$OUTPUT_DIR/$(basename -- "$3")"
GO_BIN=${GO:-go}

SOURCE_REF=$(tr -d '[:space:]' < "$ROOT/.vb-cli-source-ref")
[[ "$SOURCE_REF" =~ ^[0-9a-f]{40}$ ]] || {
    echo ".vb-cli-source-ref must contain one lowercase 40-hex commit SHA" >&2
    exit 1
}
[[ "$SOURCE_REF" != 0000000000000000000000000000000000000000 ]] || {
    echo ".vb-cli-source-ref still contains the release-blocking placeholder" >&2
    exit 1
}
ACTUAL_REF=$(git -C "$CLI_SOURCE" rev-parse HEAD)
[[ "$ACTUAL_REF" == "$SOURCE_REF" ]] || {
    echo "CLI checkout $ACTUAL_REF does not match selected source $SOURCE_REF" >&2
    exit 1
}
CLI_TOP=$(git -C "$CLI_SOURCE" rev-parse --show-toplevel)
CLI_TOP=$(cd -- "$CLI_TOP" && pwd -P)
[[ "$CLI_TOP" == "$CLI_SOURCE" ]] || {
    echo "CLI source must be the checkout root: $CLI_SOURCE" >&2
    exit 1
}
CHECKOUT_CHANGES=$(git -C "$CLI_SOURCE" status --porcelain=v1 --untracked-files=all --ignore-submodules=none)
[[ -z "$CHECKOUT_CHANGES" ]] || {
    echo "CLI checkout must be clean before building selected source $SOURCE_REF" >&2
    exit 1
}

# Build from an archive of the exact selected commit. A clean checkout check
# makes local review state explicit; the archive additionally excludes ignored
# and otherwise untracked files that `go build` would consume from a directory.
BUILD_SOURCE=$(mktemp -d "${TMPDIR:-/tmp}/vb-cli-source.XXXXXX")
cleanup() {
    rm -rf -- "$BUILD_SOURCE"
}
trap cleanup EXIT
git -C "$CLI_SOURCE" archive --format=tar "$SOURCE_REF" \
    | tar -xf - -C "$BUILD_SOURCE"

SELECTED_VERSION=$(tr -d '[:space:]' < "$ROOT/.vb-version")
SOURCE_VERSION=$(sed -n 's/^const Current = "\([^"]*\)"$/\1/p' "$BUILD_SOURCE/internal/version/version.go")
[[ -n "$SOURCE_VERSION" && "$SOURCE_VERSION" == "$SELECTED_VERSION" ]] || {
    echo "CLI source version ${SOURCE_VERSION:-missing} does not match $SELECTED_VERSION" >&2
    exit 1
}
[[ "$($GO_BIN env GOVERSION)" == go1.25.0 ]] || {
    echo "exact Go 1.25.0 is required to build the CLI candidate" >&2
    exit 1
}
[[ -f "$ARCHIVE" && ! -L "$ARCHIVE" ]] || {
    echo "template archive is not a regular file: $ARCHIVE" >&2
    exit 1
}
if command -v sha256sum >/dev/null 2>&1; then
    TEMPLATE_SHA256=$(sha256sum "$ARCHIVE" | awk '{print $1}')
else
    TEMPLATE_SHA256=$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')
fi
[[ "$TEMPLATE_SHA256" =~ ^[0-9a-f]{64}$ ]]

(
    cd "$BUILD_SOURCE"
    "$GO_BIN" build -trimpath -buildvcs=false \
        -ldflags="-s -w -X github.com/virtualboard/vb-cli/cmd.templateArchiveSHA256=${TEMPLATE_SHA256}" \
        -o "$OUTPUT" .
)
[[ "$($OUTPUT version)" == "$SELECTED_VERSION" ]] || {
    echo "built candidate does not report $SELECTED_VERSION" >&2
    exit 1
}

printf 'Built %s from %s with template SHA-256 %s\n' \
    "$OUTPUT" "$SOURCE_REF" "$TEMPLATE_SHA256"
