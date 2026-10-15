#!/bin/bash

# install-vb-cli.sh - Install Virtual Board CLI tool
# Usage: ./install-vb-cli.sh [install-path]
#
# If install-path is provided, the binary will be installed there.
# If not provided, it will be installed to /usr/local/bin (requires sudo)
# If --local is specified, it will be installed to ./vb in the current directory

set -e

GITHUB_REPO="virtualboard/vb-cli"
INSTALL_TO_PATH=true
LOCAL_INSTALL=false
INSTALL_PATH="/usr/local/bin"
ENSURE_LATEST=false
NONINTERACTIVE=false
ALLOW_SUDO=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --local|-l)
            LOCAL_INSTALL=true
            INSTALL_TO_PATH=false
            INSTALL_PATH="."
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
            echo "Usage: $0 [options] [install-path]"
            echo ""
            echo "Options:"
            echo "  --local, -l        Install to current directory (./vb)"
            echo "  --ensure-latest    Install or enforce the selected release (non-interactive)"
            echo "  --allow-sudo       Permit installation to a protected system path"
            echo "  --yes, -y          Non-interactive mode; auto-confirm all prompts"
            echo "  --help, -h         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                       # Install to /usr/local/bin (requires sudo)"
            echo "  $0 --local               # Install to ./vb in current directory"
            echo "  $0 --ensure-latest       # Used by agents/CI to guarantee pinned vb"
            exit 0
            ;;
        *)
            INSTALL_PATH="$1"
            shift
            ;;
    esac
done

# Read pinned version from .vb-version if it exists
PINNED_VERSION=""
VB_VERSION_FILE=".vb-version"
if [[ -f "$VB_VERSION_FILE" ]]; then
    PINNED_VERSION=$(tr -d '[:space:]' < "$VB_VERSION_FILE")
    if [[ -n "$PINNED_VERSION" ]]; then
        echo "Pinned version: $PINNED_VERSION (from $VB_VERSION_FILE)"
    fi
fi

# Detect OS
OS=""
OS_NAME=""  # For binary name (macos vs darwin)
ARCH=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="darwin"
    OS_NAME="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    OS_NAME="linux"
else
    echo "Error: Unsupported OS: $OSTYPE"
    echo "This script supports macOS (darwin) and Linux only."
    exit 1
fi

# Detect architecture
if [[ "$(uname -m)" == "x86_64" ]]; then
    ARCH="amd64"
elif [[ "$(uname -m)" == "arm64" ]] || [[ "$(uname -m)" == "aarch64" ]]; then
    ARCH="arm64"
else
    echo "Error: Unsupported architecture: $(uname -m)"
    echo "This script supports amd64 and arm64 architectures only."
    exit 1
fi

BINARY_NAME="vb-${OS_NAME}-${ARCH}"

# Determine install location
if [[ "$LOCAL_INSTALL" == true ]]; then
    TARGET_FILE="./vb"
    INSTALL_DESCRIPTION="current directory (./vb)"
    NEEDS_SUDO=false
elif [[ "$INSTALL_TO_PATH" == true ]]; then
    TARGET_FILE="${INSTALL_PATH}/vb"
    INSTALL_DESCRIPTION="$TARGET_FILE"
    if [[ ! -w "$(dirname "$TARGET_FILE")" ]] && [[ "$EUID" -ne 0 ]]; then
        NEEDS_SUDO=true
    else
        NEEDS_SUDO=false
    fi
else
    TARGET_FILE="${INSTALL_PATH}/vb"
    INSTALL_DESCRIPTION="$TARGET_FILE"
    NEEDS_SUDO=false
fi

# Function to prompt for yes/no (auto-yes when NONINTERACTIVE=true)
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response

    if [[ "$NONINTERACTIVE" == true ]]; then
        echo "$prompt [auto: yes]"
        return 0
    fi

    while true; do
        if [[ "$default" == "y" ]]; then
            read -p "$prompt [Y/n]: " response
        else
            read -p "$prompt [y/N]: " response
        fi

        response="${response:-$default}"
        case "$response" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo])
                return 1
                ;;
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
}

# Function to normalize version string (remove 'v' prefix, trim whitespace)
normalize_version() {
    echo "$1" | sed 's/^v//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Check if vb CLI is already installed
VB_INSTALLED=false
VB_VERSION=""
VB_VERSION_NORMALIZED=""
if command -v vb &> /dev/null; then
    VB_INSTALLED=true
    # Try to get version
    if VB_VERSION_OUTPUT=$(vb version 2>/dev/null); then
        VB_VERSION="$VB_VERSION_OUTPUT"
        VB_VERSION_NORMALIZED=$(normalize_version "$VB_VERSION")
    else
        VB_VERSION="(unable to determine version)"
    fi
fi

# Determine target version: pinned version takes priority over GitHub API latest
TARGET_VERSION=""
TARGET_VERSION_NORMALIZED=""
if [[ -n "$PINNED_VERSION" ]]; then
    TARGET_VERSION="$PINNED_VERSION"
    TARGET_VERSION_NORMALIZED=$(normalize_version "$PINNED_VERSION")
    if [[ ! "$TARGET_VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]]; then
        echo "Error: invalid version in $VB_VERSION_FILE: $TARGET_VERSION" >&2
        exit 1
    fi
else
    echo "Checking for latest version..." >&2
    if command -v jq &> /dev/null; then
        # Use jq if available (more reliable)
        API_RESPONSE=$(curl -s -L "https://api.github.com/repos/${GITHUB_REPO}/releases/latest")
        if [[ -n "$API_RESPONSE" ]]; then
            TARGET_VERSION=$(echo "$API_RESPONSE" | jq -r '.tag_name // empty' 2>/dev/null)
            if [[ -n "$TARGET_VERSION" ]] && [[ "$TARGET_VERSION" != "null" ]]; then
                TARGET_VERSION_NORMALIZED=$(normalize_version "$TARGET_VERSION")
            else
                TARGET_VERSION=""
            fi
        fi
    elif command -v grep &> /dev/null && command -v sed &> /dev/null; then
        # Fallback: parse JSON with grep/sed
        API_RESPONSE=$(curl -s -L "https://api.github.com/repos/${GITHUB_REPO}/releases/latest")
        if [[ -n "$API_RESPONSE" ]]; then
            TARGET_VERSION=$(echo "$API_RESPONSE" | grep -o '"tag_name":\s*"[^"]*"' | sed 's/"tag_name":\s*"\([^"]*\)"/\1/' | head -1)
            if [[ -n "$TARGET_VERSION" ]]; then
                TARGET_VERSION_NORMALIZED=$(normalize_version "$TARGET_VERSION")
            fi
        fi
    fi
fi
if [[ ! "$TARGET_VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]]; then
    echo "Error: release metadata did not contain a valid version tag: ${TARGET_VERSION:-<empty>}" >&2
    exit 1
fi
# Backward-compat aliases used by the rest of the script
LATEST_VERSION="$TARGET_VERSION"
LATEST_VERSION_NORMALIZED="$TARGET_VERSION_NORMALIZED"

if [[ -z "$TARGET_VERSION" ]]; then
    echo "Error: could not resolve an exact VirtualBoard CLI release version." >&2
    exit 1
fi
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${TARGET_VERSION}/${BINARY_NAME}"
CHECKSUMS_URL="https://github.com/${GITHUB_REPO}/releases/download/${TARGET_VERSION}/checksums.txt"

# Display information and get confirmation
echo "Virtual Board CLI Installer"
echo "=========================="
echo ""

# --ensure-latest: non-interactive install path for agents/CI
if [[ "$ENSURE_LATEST" == true ]] && [[ "$VB_INSTALLED" == true ]]; then
    echo "Virtual Board CLI is already installed."
    if [[ -n "$VB_VERSION" ]] && [[ "$VB_VERSION" != "(unable to determine version)" ]]; then
        echo "Current version: $VB_VERSION"
    fi

    # If we couldn't determine the target version, trust what's installed and exit.
    if [[ -z "$LATEST_VERSION_NORMALIZED" ]]; then
        echo "Warning: unable to determine target version — keeping installed version." >&2
        exit 0
    fi

    echo "Target version: $LATEST_VERSION"

    # Already at target — nothing to do.
    if [[ -n "$VB_VERSION_NORMALIZED" ]] && [[ "$VB_VERSION_NORMALIZED" == "$LATEST_VERSION_NORMALIZED" ]]; then
        echo "✓ Already up to date."
        exit 0
    fi

    # Use the selected immutable release URL. `vb upgrade` targets latest and
    # could silently ignore a project pin.
    echo "Installing the selected release $LATEST_VERSION..."
fi

# If already installed, check version and suggest upgrade
if [[ "$VB_INSTALLED" == true ]]; then
    echo "Virtual Board CLI is already installed!"
    if [[ -n "$VB_VERSION" ]] && [[ "$VB_VERSION" != "(unable to determine version)" ]]; then
        echo "Current version: $VB_VERSION"
    fi

    # Check if already on latest version
    if [[ -n "$VB_VERSION_NORMALIZED" ]] && [[ -n "$LATEST_VERSION_NORMALIZED" ]] && [[ "$VB_VERSION_NORMALIZED" == "$LATEST_VERSION_NORMALIZED" ]]; then
        echo "Latest version: $LATEST_VERSION"
        echo ""
        echo "✓ You already have the latest version installed!"
        echo "No installation needed."
        exit 0
    fi

    # Show latest version if available
    if [[ -n "$LATEST_VERSION" ]]; then
        echo "Latest version: $LATEST_VERSION"
    fi

    echo ""
    echo "To upgrade to the latest version, you can run:"
    # Check if vb is likely in a system directory that requires sudo
    VB_PATH=$(command -v vb)
    if [[ "$VB_PATH" == "/usr/local/bin/vb" ]] || [[ "$VB_PATH" == "/usr/bin/vb" ]] && [[ "$EUID" -ne 0 ]]; then
        echo "  sudo vb upgrade"
    else
        echo "  vb upgrade"
    fi
    echo ""
    if ! prompt_yes_no "Do you want to proceed with a fresh installation anyway?" "n"; then
        echo "Installation cancelled. Use 'vb upgrade' to update your existing installation."
        exit 0
    fi
    echo ""
fi

if [[ "$NEEDS_SUDO" == true && "$ALLOW_SUDO" != true ]]; then
    echo "Error: installing to $TARGET_FILE requires elevated privileges." >&2
    echo "Pass --allow-sudo explicitly or choose a user-writable install path." >&2
    exit 1
fi

echo "System Information:"
echo "  OS: $OS_NAME"
echo "  Architecture: $ARCH"
echo "  Binary: $BINARY_NAME"
echo ""
echo "Installation Plan:"
echo "  1. Download the latest Virtual Board CLI binary from:"
echo "     $DOWNLOAD_URL"
echo ""
echo "  2. Install the binary to: $INSTALL_DESCRIPTION"
if [[ "$NEEDS_SUDO" == true ]]; then
    echo "     (This will require sudo privileges)"
fi
echo ""
echo "  3. Make the binary executable"
echo ""
echo "  4. Verify the installation by running 'vb version'"
echo ""

if ! prompt_yes_no "Do you want to proceed with the installation?" "y"; then
    echo "Installation cancelled."
    exit 0
fi

# Download the binary
echo ""
echo "Downloading Virtual Board CLI..."
TEMP_FILE=$(mktemp)
if curl -s -L -f -o "$TEMP_FILE" "$DOWNLOAD_URL"; then
    echo "Download successful!"
else
    echo "Error: Failed to download from $DOWNLOAD_URL"
    echo ""
    echo "Please check:"
    echo "  1. Your internet connection"
    echo "  2. That the repository exists: https://github.com/${GITHUB_REPO}"
    echo "  3. That releases are available"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Verify SHA-256 checksum
echo "Verifying checksum..."
CHECKSUMS_FILE=$(mktemp)
if curl -s -L -f -o "$CHECKSUMS_FILE" "$CHECKSUMS_URL"; then
    EXPECTED_HASH=$(awk -v name="$BINARY_NAME" '$2 == name || (substr($2, 1, 2) == "./" && substr($2, 3) == name) { print $1 }' "$CHECKSUMS_FILE")
    if [[ -z "$EXPECTED_HASH" || ! "$EXPECTED_HASH" =~ ^[[:xdigit:]]{64}$ ]]; then
        echo "Error: missing or invalid SHA-256 entry for $BINARY_NAME in checksums.txt." >&2
        rm -f "$TEMP_FILE" "$CHECKSUMS_FILE"
        exit 1
    else
        if command -v sha256sum &> /dev/null; then
            ACTUAL_HASH=$(sha256sum "$TEMP_FILE" | awk '{print $1}')
        elif command -v shasum &> /dev/null; then
            ACTUAL_HASH=$(shasum -a 256 "$TEMP_FILE" | awk '{print $1}')
        else
            echo "Error: neither sha256sum nor shasum is available; refusing an unverified binary." >&2
            rm -f "$TEMP_FILE" "$CHECKSUMS_FILE"
            exit 1
        fi
        if [[ -n "$ACTUAL_HASH" ]]; then
            if [[ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]]; then
                echo "Error: SHA-256 checksum mismatch!" >&2
                echo "  Expected: $EXPECTED_HASH" >&2
                echo "  Actual:   $ACTUAL_HASH" >&2
                echo "The downloaded binary may have been tampered with. Aborting." >&2
                rm -f "$TEMP_FILE" "$CHECKSUMS_FILE"
                exit 1
            fi
            echo "Checksum verified (SHA-256)."
        fi
    fi
else
    echo "Error: could not download checksums.txt; refusing an unverified binary." >&2
    rm -f "$TEMP_FILE" "$CHECKSUMS_FILE"
    exit 1
fi
rm -f "$CHECKSUMS_FILE"

# Make executable
chmod +x "$TEMP_FILE"
echo "Binary prepared and made executable."

# Validate the downloaded program and ensure the release asset matches its tag.
if ! DOWNLOADED_VERSION=$("$TEMP_FILE" version 2>/dev/null); then
    echo "Error: downloaded binary failed its version check." >&2
    rm -f "$TEMP_FILE"
    exit 1
fi
if [[ "$(normalize_version "$DOWNLOADED_VERSION")" != "$TARGET_VERSION_NORMALIZED" ]]; then
    echo "Error: release tag $TARGET_VERSION does not match binary version $DOWNLOADED_VERSION." >&2
    rm -f "$TEMP_FILE"
    exit 1
fi

# Stage in the target directory so the final rename is atomic on one filesystem.
TARGET_DIR=$(dirname "$TARGET_FILE")
if [[ "$NEEDS_SUDO" == true ]]; then
    if [[ "$ALLOW_SUDO" != true ]]; then
        rm -f "$TEMP_FILE"
        echo "Error: installing to $TARGET_FILE requires elevated privileges." >&2
        echo "Pass --allow-sudo explicitly or choose a user-writable install path." >&2
        exit 1
    fi
    echo ""
    if ! prompt_yes_no "Do you want to install to $INSTALL_PATH? (This requires sudo privileges)" "y"; then
        rm -f "$TEMP_FILE"
        echo "Installation cancelled. The existing installation was preserved."
        exit 0
    fi
    sudo mkdir -p "$TARGET_DIR"
    STAGED_TARGET=$(sudo mktemp "$TARGET_DIR/.vb.XXXXXX")
    if ! sudo install -m 0755 "$TEMP_FILE" "$STAGED_TARGET"; then
        sudo rm -f "$STAGED_TARGET"
        rm -f "$TEMP_FILE"
        echo "Error: could not stage the verified binary in $TARGET_DIR." >&2
        exit 1
    fi
else
    mkdir -p "$TARGET_DIR"
    STAGED_TARGET=$(mktemp "$TARGET_DIR/.vb.XXXXXX")
    if ! install -m 0755 "$TEMP_FILE" "$STAGED_TARGET"; then
        rm -f "$STAGED_TARGET" "$TEMP_FILE"
        echo "Error: could not stage the verified binary in $TARGET_DIR." >&2
        exit 1
    fi
fi
rm -f "$TEMP_FILE"

if [[ "$NEEDS_SUDO" == true ]]; then
    sudo mv -f "$STAGED_TARGET" "$TARGET_FILE"
else
    mv -f "$STAGED_TARGET" "$TARGET_FILE"
fi
echo "Installed to $TARGET_FILE"

echo ""
echo "Installation complete!"
echo ""

# Verify installation
if "$TARGET_FILE" version &>/dev/null; then
    echo "Verification: Virtual Board CLI is installed and working!"
    "$TARGET_FILE" version
    echo ""
    echo "You can now use 'vb' commands:"
    echo "  vb new \"Feature Title\" label1 label2"
    echo "  vb move FTR-0001 in-progress --owner agent-name"
    echo "  vb validate"
    echo "  vb index"
    echo "  vb help"
else
    echo "Warning: Installation may have succeeded, but 'vb version' command failed."
    echo "You may need to:"
    if [[ "$LOCAL_INSTALL" == false ]]; then
        echo "  1. Add $INSTALL_PATH to your PATH"
        echo "  2. Run: export PATH=\"\$PATH:$(dirname "$TARGET_FILE")\""
    else
        echo "  1. Check the file permissions: ls -l $TARGET_FILE"
    fi
    exit 1
fi

