#!/usr/bin/env bash

# install-vb-cli.sh - Install the exact Virtual Board CLI release selected by
# .vb-version. The version file is resolved relative to this script so callers
# may invoke the installer from any working directory.

set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd -P)
CALLER_DIR=$(pwd -P)

GITHUB_REPO=${VB_GITHUB_REPO:-virtualboard/vb-cli}
VERSION_FILE=${VB_VERSION_FILE:-$REPO_ROOT/.vb-version}
INSTALL_PATH=/usr/local/bin
INSTALL_PATH_EXPLICIT=false
LOCAL_INSTALL=false
ENSURE_LATEST=false
NONINTERACTIVE=false
ALLOW_SUDO=false
NEEDS_SUDO=false
TEMP_FILE=
CHECKSUMS_FILE=
STAGE_FILE=

usage() {
    cat <<EOF
Usage: $0 [options] [install-directory]

Options:
  --local, -l        Install to ./vb in the caller's current directory
  --ensure-latest    Non-interactively ensure the exact selected version
  --allow-sudo       Permit explicit sudo use when the destination is not writable
  --yes, -y          Non-interactive mode; auto-confirm prompts
  --help, -h         Show this help message

Environment:
  VB_VERSION_FILE          Override the version file (primarily for testing)
  VB_GITHUB_REPO           Override the GitHub owner/repository
  VB_CURL_CONNECT_TIMEOUT  Curl connection timeout in seconds (default: 10)
  VB_CURL_MAX_TIME         Curl total timeout in seconds (default: 120)
  VB_BINARY_MAX_BYTES      Maximum downloaded binary size (default: 104857600)
  VB_CHECKSUMS_MAX_BYTES   Maximum checksum-manifest size (default: 1048576)
EOF
}

die() {
    echo "Error: $*" >&2
    exit 1
}

remove_stage_file() {
    [[ -n "$STAGE_FILE" && -e "$STAGE_FILE" ]] || return 0
    if [[ "$NEEDS_SUDO" == true ]]; then
        sudo rm -f -- "$STAGE_FILE" >/dev/null 2>&1 || true
    else
        rm -f -- "$STAGE_FILE" >/dev/null 2>&1 || true
    fi
}

cleanup() {
    if [[ -n "$TEMP_FILE" && -e "$TEMP_FILE" ]]; then
        rm -f -- "$TEMP_FILE"
    fi
    if [[ -n "$CHECKSUMS_FILE" && -e "$CHECKSUMS_FILE" ]]; then
        rm -f -- "$CHECKSUMS_FILE"
    fi
    remove_stage_file
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

prompt_yes_no() {
    local prompt=$1
    local default=${2:-n}
    local response

    if [[ "$NONINTERACTIVE" == true ]]; then
        echo "$prompt [auto: yes]"
        return 0
    fi

    while true; do
        if [[ "$default" == y ]]; then
            read -r -p "$prompt [Y/n]: " response
        else
            read -r -p "$prompt [y/N]: " response
        fi
        response=${response:-$default}
        case "$response" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

normalize_version() {
    local value
    value=$(printf '%s' "$1" | tr -d '[:space:]')
    if [[ "$value" =~ ^[vV]?([0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?)$ ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "required command '$1' was not found"
}

curl_download() {
    local url=$1
    local destination=$2
    local max_bytes=$3
    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --proto '=https' \
        --proto-redir '=https' \
        --connect-timeout "${VB_CURL_CONNECT_TIMEOUT:-10}" \
        --max-time "${VB_CURL_MAX_TIME:-120}" \
        --max-filesize "$max_bytes" \
        --retry 3 \
        --retry-delay 1 \
        --output "$destination" \
        "$url"
}

require_bounded_file() {
    local path=$1
    local max_bytes=$2
    local label=$3
    local actual
    actual=$(wc -c < "$path" | tr -d '[:space:]')
    [[ "$actual" =~ ^[0-9]+$ ]] || die "could not determine $label size"
    (( actual <= max_bytes )) || die "$label exceeds the configured $max_bytes-byte limit"
}

sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        die "neither sha256sum nor shasum is available; refusing an unverified install"
    fi
}

# Return a lexical absolute path without following filesystem links. Parent
# traversal is rejected so every component inspected below is unambiguous.
normalize_destination_path() {
    local raw=$1
    local component
    local normalized=
    local -a components

    [[ "$raw" != *$'\n'* && "$raw" != *$'\r'* ]] || die "destination paths may not contain newlines"
    case "$raw" in
        /*) ;;
        *) raw="$CALLER_DIR/$raw" ;;
    esac

    local IFS='/'
    read -r -a components <<< "$raw"
    for component in "${components[@]}"; do
        case "$component" in
            ''|.) continue ;;
            ..) die "destination paths may not contain '..': $raw" ;;
        esac
        normalized="$normalized/$component"
    done
    printf '%s\n' "${normalized:-/}"
}

# Reject every existing link before any destination executable is run. This
# includes directory symlinks and a symlink at the final binary path.
assert_safe_existing_path() {
    local path=$1
    local final_kind=$2
    local current=
    local component
    local -a components

    local IFS='/'
    read -r -a components <<< "$path"
    for component in "${components[@]}"; do
        [[ -n "$component" ]] || continue
        current="$current/$component"
        if [[ -L "$current" ]]; then
            die "destination path contains a symbolic link: $current"
        fi
        if [[ -e "$current" ]]; then
            if [[ "$current" != "$path" || "$final_kind" == directory ]]; then
                [[ -d "$current" ]] || die "destination ancestor is not a directory: $current"
            else
                [[ -f "$current" ]] || die "destination is not a regular file: $current"
            fi
        else
            break
        fi
    done
}

ensure_safe_directory() {
    local path=$1
    local current=
    local component
    local -a components

    local IFS='/'
    read -r -a components <<< "$path"
    for component in "${components[@]}"; do
        [[ -n "$component" ]] || continue
        current="$current/$component"
        [[ ! -L "$current" ]] || die "destination path contains a symbolic link: $current"
        if [[ -e "$current" ]]; then
            [[ -d "$current" ]] || die "destination ancestor is not a directory: $current"
            continue
        fi
        if ! mkdir -- "$current" 2>/dev/null; then
            if [[ "$ALLOW_SUDO" != true ]]; then
                die "cannot create $current without elevated privileges; choose a writable directory or pass --allow-sudo"
            fi
            require_command sudo
            sudo mkdir -- "$current"
            NEEDS_SUDO=true
        fi
        [[ -d "$current" && ! -L "$current" ]] || die "destination directory was replaced during creation: $current"
    done

    [[ "$(cd -- "$path" && pwd -P)" == "$path" ]] \
        || die "destination directory does not resolve to itself: $path"
}

create_stage_file() {
    if [[ "$NEEDS_SUDO" == true ]]; then
        STAGE_FILE=$(sudo mktemp "$TARGET_DIR/.vb.install.XXXXXX")
    else
        STAGE_FILE=$(mktemp "$TARGET_DIR/.vb.install.XXXXXX")
    fi
    [[ -n "$STAGE_FILE" && "$STAGE_FILE" == "$TARGET_DIR/".vb.install.* ]] \
        || die "could not create a same-directory staging file"
    [[ -f "$STAGE_FILE" && ! -L "$STAGE_FILE" ]] || die "unsafe staging file: $STAGE_FILE"
}

# The helper opens the already-validated parent without following links, fsyncs
# the staged bytes, and invokes one same-directory os.replace. os.replace is the
# only operation that changes the destination name, so a failed activation
# leaves an existing binary untouched.
activate_stage_file() {
    local expected_hash=$1
    local python_bin
    python_bin=$(command -v python3)
    local -a command=(
        "$python_bin" - "$TARGET_DIR" "$(basename -- "$STAGE_FILE")" "$(basename -- "$TARGET_FILE")" "$expected_hash"
    )

    if [[ "$NEEDS_SUDO" == true ]]; then
        sudo "${command[@]}" <<'PY'
import hashlib
import os
import stat
import sys

parent, stage_name, target_name, expected_hash = sys.argv[1:]
if any(not name or name in {".", ".."} or "/" in name for name in (stage_name, target_name)):
    raise SystemExit("invalid activation basename")

flags = os.O_RDONLY | getattr(os, "O_CLOEXEC", 0) | getattr(os, "O_DIRECTORY", 0) | getattr(os, "O_NOFOLLOW", 0)
directory_fd = os.open(parent, flags)
try:
    stage_flags = os.O_RDONLY | getattr(os, "O_CLOEXEC", 0) | getattr(os, "O_NOFOLLOW", 0)
    stage_fd = os.open(stage_name, stage_flags, dir_fd=directory_fd)
    try:
        stage_stat = os.fstat(stage_fd)
        if not stat.S_ISREG(stage_stat.st_mode):
            raise SystemExit("staging path is not a regular file")
        digest = hashlib.sha256()
        while True:
            chunk = os.read(stage_fd, 1024 * 1024)
            if not chunk:
                break
            digest.update(chunk)
        if digest.hexdigest() != expected_hash:
            raise SystemExit("staging bytes changed before activation")
        os.fsync(stage_fd)

        current_stage = os.stat(stage_name, dir_fd=directory_fd, follow_symlinks=False)
        if not stat.S_ISREG(current_stage.st_mode) or (current_stage.st_dev, current_stage.st_ino) != (stage_stat.st_dev, stage_stat.st_ino):
            raise SystemExit("staging path identity changed before activation")

        try:
            target_stat = os.stat(target_name, dir_fd=directory_fd, follow_symlinks=False)
        except FileNotFoundError:
            target_stat = None
        if target_stat is not None and not stat.S_ISREG(target_stat.st_mode):
            raise SystemExit("destination is not a regular file")

        if os.environ.get("VB_INSTALLER_TESTING") == "1" and os.environ.get("VB_INSTALLER_TEST_FAIL_ACTIVATION") == "1":
            raise SystemExit("injected activation failure")

        os.replace(stage_name, target_name, src_dir_fd=directory_fd, dst_dir_fd=directory_fd)
    finally:
        os.close(stage_fd)
    os.fsync(directory_fd)
finally:
    os.close(directory_fd)
PY
    else
        "${command[@]}" <<'PY'
import hashlib
import os
import stat
import sys

parent, stage_name, target_name, expected_hash = sys.argv[1:]
if any(not name or name in {".", ".."} or "/" in name for name in (stage_name, target_name)):
    raise SystemExit("invalid activation basename")

flags = os.O_RDONLY | getattr(os, "O_CLOEXEC", 0) | getattr(os, "O_DIRECTORY", 0) | getattr(os, "O_NOFOLLOW", 0)
directory_fd = os.open(parent, flags)
try:
    stage_flags = os.O_RDONLY | getattr(os, "O_CLOEXEC", 0) | getattr(os, "O_NOFOLLOW", 0)
    stage_fd = os.open(stage_name, stage_flags, dir_fd=directory_fd)
    try:
        stage_stat = os.fstat(stage_fd)
        if not stat.S_ISREG(stage_stat.st_mode):
            raise SystemExit("staging path is not a regular file")
        digest = hashlib.sha256()
        while True:
            chunk = os.read(stage_fd, 1024 * 1024)
            if not chunk:
                break
            digest.update(chunk)
        if digest.hexdigest() != expected_hash:
            raise SystemExit("staging bytes changed before activation")
        os.fsync(stage_fd)

        current_stage = os.stat(stage_name, dir_fd=directory_fd, follow_symlinks=False)
        if not stat.S_ISREG(current_stage.st_mode) or (current_stage.st_dev, current_stage.st_ino) != (stage_stat.st_dev, stage_stat.st_ino):
            raise SystemExit("staging path identity changed before activation")

        try:
            target_stat = os.stat(target_name, dir_fd=directory_fd, follow_symlinks=False)
        except FileNotFoundError:
            target_stat = None
        if target_stat is not None and not stat.S_ISREG(target_stat.st_mode):
            raise SystemExit("destination is not a regular file")

        if os.environ.get("VB_INSTALLER_TESTING") == "1" and os.environ.get("VB_INSTALLER_TEST_FAIL_ACTIVATION") == "1":
            raise SystemExit("injected activation failure")

        os.replace(stage_name, target_name, src_dir_fd=directory_fd, dst_dir_fd=directory_fd)
    finally:
        os.close(stage_fd)
    os.fsync(directory_fd)
finally:
    os.close(directory_fd)
PY
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --local|-l)
            LOCAL_INSTALL=true
            INSTALL_PATH_EXPLICIT=true
            shift
            ;;
        --ensure-latest)
            ENSURE_LATEST=true
            NONINTERACTIVE=true
            shift
            ;;
        --allow-sudo)
            ALLOW_SUDO=true
            shift
            ;;
        --yes|-y)
            NONINTERACTIVE=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        --*)
            die "unknown option '$1'"
            ;;
        *)
            if [[ "$INSTALL_PATH_EXPLICIT" == true ]]; then
                die "only one install directory may be provided"
            fi
            INSTALL_PATH=$1
            INSTALL_PATH_EXPLICIT=true
            shift
            ;;
    esac
done

require_command curl
require_command mktemp
require_command uname
require_command install
require_command python3
require_command wc

[[ "$GITHUB_REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] \
    || die "VB_GITHUB_REPO must use the form owner/repository"

[[ -f "$VERSION_FILE" ]] || die "version file not found: $VERSION_FILE"
TARGET_TAG=$(tr -d '[:space:]' < "$VERSION_FILE")
[[ -n "$TARGET_TAG" ]] || die "version file is empty: $VERSION_FILE"
TARGET_VERSION=$(normalize_version "$TARGET_TAG") || die "invalid version '$TARGET_TAG' in $VERSION_FILE"

case "$(uname -s)" in
    Darwin) OS_NAME=macos ;;
    Linux) OS_NAME=linux ;;
    *) die "unsupported operating system '$(uname -s)'; use install-vb-cli.ps1 on Windows" ;;
esac

case "$(uname -m)" in
    x86_64|amd64) ARCH=amd64 ;;
    arm64|aarch64) ARCH=arm64 ;;
    *) die "unsupported architecture '$(uname -m)'; supported architectures are amd64 and arm64" ;;
esac

BINARY_NAME="vb-${OS_NAME}-${ARCH}"
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${TARGET_TAG}/${BINARY_NAME}"
CHECKSUMS_URL="https://github.com/${GITHUB_REPO}/releases/download/${TARGET_TAG}/checksums.txt"

VB_PATH=
if [[ "$LOCAL_INSTALL" == true ]]; then
    TARGET_FILE_INPUT="$CALLER_DIR/vb"
elif [[ "$INSTALL_PATH_EXPLICIT" == true ]]; then
    TARGET_FILE_INPUT="${INSTALL_PATH%/}/vb"
elif command -v vb >/dev/null 2>&1; then
    VB_PATH=$(command -v vb)
    if [[ "$VB_PATH" == */* ]]; then
        TARGET_FILE_INPUT=$VB_PATH
    else
        TARGET_FILE_INPUT="${INSTALL_PATH%/}/vb"
    fi
else
    TARGET_FILE_INPUT="${INSTALL_PATH%/}/vb"
fi

TARGET_FILE=$(normalize_destination_path "$TARGET_FILE_INPUT")
TARGET_DIR=$(dirname -- "$TARGET_FILE")
assert_safe_existing_path "$TARGET_DIR" directory
assert_safe_existing_path "$TARGET_FILE" file

echo "Virtual Board CLI Installer"
echo "==========================="
echo "Selected version: $TARGET_TAG ($VERSION_FILE)"

if [[ "$ENSURE_LATEST" != true ]]; then
    echo "Destination: $TARGET_FILE"
    if ! prompt_yes_no "Install exact version $TARGET_TAG?" y; then
        echo "Installation cancelled."
        exit 0
    fi
fi

ensure_safe_directory "$TARGET_DIR"
assert_safe_existing_path "$TARGET_FILE" file
if [[ ! -w "$TARGET_DIR" ]]; then
    if [[ "$ALLOW_SUDO" == true ]]; then
        require_command sudo
        NEEDS_SUDO=true
    else
        die "destination $TARGET_DIR is not writable; choose a writable directory or pass --allow-sudo"
    fi
fi

TEMP_FILE=$(mktemp "${TMPDIR:-/tmp}/vb.XXXXXX")
CHECKSUMS_FILE=$(mktemp "${TMPDIR:-/tmp}/vb-checksums.XXXXXX")
BINARY_MAX_BYTES=${VB_BINARY_MAX_BYTES:-104857600}
CHECKSUMS_MAX_BYTES=${VB_CHECKSUMS_MAX_BYTES:-1048576}
[[ "$BINARY_MAX_BYTES" =~ ^[1-9][0-9]*$ ]] || die "VB_BINARY_MAX_BYTES must be a positive integer"
[[ "$CHECKSUMS_MAX_BYTES" =~ ^[1-9][0-9]*$ ]] || die "VB_CHECKSUMS_MAX_BYTES must be a positive integer"

curl_download "$CHECKSUMS_URL" "$CHECKSUMS_FILE" "$CHECKSUMS_MAX_BYTES" || die "failed to download required checksum file $CHECKSUMS_URL"
require_bounded_file "$CHECKSUMS_FILE" "$CHECKSUMS_MAX_BYTES" "checksum manifest"

MATCH_COUNT=$(awk -v name="$BINARY_NAME" '
    {
        if (NF != 2) {
            next
        }
        file = $2
        sub(/^\*/, "", file)
        sub(/^\.\//, "", file)
        if (file == name) {
            count++
        }
    }
    END { print count + 0 }
' "$CHECKSUMS_FILE")
[[ "$MATCH_COUNT" == 1 ]] || die "expected exactly one checksum entry for $BINARY_NAME; found $MATCH_COUNT"
EXPECTED_HASH=$(awk -v name="$BINARY_NAME" '
    {
        if (NF != 2) {
            next
        }
        file = $2
        sub(/^\*/, "", file)
        sub(/^\.\//, "", file)
        if (file == name) {
            print $1
        }
    }
' "$CHECKSUMS_FILE")
[[ "$EXPECTED_HASH" =~ ^[[:xdigit:]]{64}$ ]] || die "checksum entry for $BINARY_NAME is not a valid SHA-256 digest"
EXPECTED_HASH=$(printf '%s' "$EXPECTED_HASH" | tr '[:upper:]' '[:lower:]')

# Never execute or trust a pre-existing destination until its bytes match the
# exact release manifest. A self-reported version is not an integrity proof.
if [[ -f "$TARGET_FILE" && ! -L "$TARGET_FILE" ]]; then
    TARGET_HASH=$(sha256_file "$TARGET_FILE")
    if [[ "$TARGET_HASH" == "$EXPECTED_HASH" ]]; then
        TARGET_VERSION_OUTPUT=$("$TARGET_FILE" version 2>/dev/null) || die "manifest-verified destination failed its version check"
        TARGET_CURRENT_VERSION=$(normalize_version "$TARGET_VERSION_OUTPUT") || die "manifest-verified destination returned an unrecognized version"
        [[ "$TARGET_CURRENT_VERSION" == "$TARGET_VERSION" ]] || die "manifest-verified destination version mismatch: expected v$TARGET_VERSION, got v$TARGET_CURRENT_VERSION"
        echo "✓ Exact manifest-verified version is already installed at $TARGET_FILE."
        exit 0
    fi
fi

echo "Downloading $DOWNLOAD_URL"
curl_download "$DOWNLOAD_URL" "$TEMP_FILE" "$BINARY_MAX_BYTES" || die "failed to download $DOWNLOAD_URL"
require_bounded_file "$TEMP_FILE" "$BINARY_MAX_BYTES" "downloaded binary"

ACTUAL_HASH=$(sha256_file "$TEMP_FILE")
[[ "$ACTUAL_HASH" == "$EXPECTED_HASH" ]] || die "SHA-256 checksum mismatch for $BINARY_NAME"
echo "Checksum verified."

chmod 0755 "$TEMP_FILE"
DOWNLOADED_VERSION_OUTPUT=$("$TEMP_FILE" version 2>/dev/null) || die "downloaded binary failed its version check"
DOWNLOADED_VERSION=$(normalize_version "$DOWNLOADED_VERSION_OUTPUT") || die "downloaded binary returned an unrecognized version: $DOWNLOADED_VERSION_OUTPUT"
[[ "$DOWNLOADED_VERSION" == "$TARGET_VERSION" ]] || die "downloaded binary version mismatch: expected v$TARGET_VERSION, got v$DOWNLOADED_VERSION"

# Copy already-verified bytes into the real target directory. Recheck both the
# digest and version there before the fsynced atomic activation.
assert_safe_existing_path "$TARGET_DIR" directory
assert_safe_existing_path "$TARGET_FILE" file
create_stage_file
if [[ "$NEEDS_SUDO" == true ]]; then
    sudo install -m 0755 "$TEMP_FILE" "$STAGE_FILE"
else
    install -m 0755 "$TEMP_FILE" "$STAGE_FILE"
fi
STAGED_HASH=$(sha256_file "$STAGE_FILE")
[[ "$STAGED_HASH" == "$EXPECTED_HASH" ]] || die "same-directory staged binary checksum mismatch"
STAGED_VERSION_OUTPUT=$("$STAGE_FILE" version 2>/dev/null) || die "same-directory staged binary failed its version check"
STAGED_VERSION=$(normalize_version "$STAGED_VERSION_OUTPUT") || die "same-directory staged binary returned an unrecognized version: $STAGED_VERSION_OUTPUT"
[[ "$STAGED_VERSION" == "$TARGET_VERSION" ]] || die "same-directory staged binary version mismatch: expected v$TARGET_VERSION, got v$STAGED_VERSION"

activate_stage_file "$EXPECTED_HASH" || die "atomic activation failed; any existing binary was preserved"
STAGE_FILE=

INSTALLED_HASH=$(sha256_file "$TARGET_FILE")
[[ "$INSTALLED_HASH" == "$EXPECTED_HASH" ]] || die "post-install binary checksum mismatch"
VERSION_OUTPUT=$("$TARGET_FILE" version 2>/dev/null) || die "installed binary failed its version check: $TARGET_FILE"
INSTALLED_VERSION=$(normalize_version "$VERSION_OUTPUT") || die "installed binary returned an unrecognized version: $VERSION_OUTPUT"
[[ "$INSTALLED_VERSION" == "$TARGET_VERSION" ]] || die "post-install version mismatch: expected v$TARGET_VERSION, got v$INSTALLED_VERSION"

echo "✓ Installed and verified $TARGET_TAG at $TARGET_FILE"
if [[ ":$PATH:" != *":$TARGET_DIR:"* ]]; then
    echo "Add $TARGET_DIR to PATH to invoke 'vb' directly."
fi
