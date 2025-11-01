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

# Parse arguments
if [[ $# -gt 0 ]]; then
    if [[ "$1" == "--local" ]] || [[ "$1" == "-l" ]]; then
        LOCAL_INSTALL=true
        INSTALL_TO_PATH=false
        INSTALL_PATH="."
    elif [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --local, -l    Install to current directory (./vb)"
        echo "  --help, -h     Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0              # Install to /usr/local/bin (requires sudo)"
        echo "  $0 --local      # Install to ./vb in current directory"
        exit 0
    else
        INSTALL_PATH="$1"
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

# Construct download URL
BINARY_NAME="vb-${OS_NAME}-${ARCH}"
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/latest/download/${BINARY_NAME}"

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

# Function to prompt for yes/no
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
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

# Fetch latest version from GitHub
LATEST_VERSION=""
LATEST_VERSION_NORMALIZED=""
echo "Checking for latest version..." >&2
if command -v jq &> /dev/null; then
    # Use jq if available (more reliable)
    API_RESPONSE=$(curl -s -L "https://api.github.com/repos/${GITHUB_REPO}/releases/latest")
    if [[ -n "$API_RESPONSE" ]]; then
        LATEST_VERSION=$(echo "$API_RESPONSE" | jq -r '.tag_name // empty' 2>/dev/null)
        if [[ -n "$LATEST_VERSION" ]] && [[ "$LATEST_VERSION" != "null" ]]; then
            LATEST_VERSION_NORMALIZED=$(normalize_version "$LATEST_VERSION")
        fi
    fi
elif command -v grep &> /dev/null && command -v sed &> /dev/null; then
    # Fallback: parse JSON with grep/sed
    API_RESPONSE=$(curl -s -L "https://api.github.com/repos/${GITHUB_REPO}/releases/latest")
    if [[ -n "$API_RESPONSE" ]]; then
        LATEST_VERSION=$(echo "$API_RESPONSE" | grep -o '"tag_name":\s*"[^"]*"' | sed 's/"tag_name":\s*"\([^"]*\)"/\1/' | head -1)
        if [[ -n "$LATEST_VERSION" ]]; then
            LATEST_VERSION_NORMALIZED=$(normalize_version "$LATEST_VERSION")
        fi
    fi
fi

# Display information and get confirmation
echo "Virtual Board CLI Installer"
echo "=========================="
echo ""

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

# Make executable
chmod +x "$TEMP_FILE"
echo "Binary prepared and made executable."

# Install to target location
if [[ "$LOCAL_INSTALL" == true ]]; then
    # Local install - no confirmation needed
    mv "$TEMP_FILE" "$TARGET_FILE"
    echo "Installed to $TARGET_FILE"
elif [[ "$NEEDS_SUDO" == true ]]; then
    # Need sudo - ask for confirmation before requesting password
    echo ""
    if prompt_yes_no "Do you want to install to $INSTALL_PATH? (This requires sudo privileges)" "y"; then
        echo ""
        echo "Installing to $TARGET_FILE (sudo required)..."
        sudo mv "$TEMP_FILE" "$TARGET_FILE"
        echo "Installed to $TARGET_FILE"
    else
        echo ""
        echo "Installation cancelled. The downloaded binary is available at: $TEMP_FILE"
        echo "You can manually install it later or run this script again."
        exit 0
    fi
else
    # No sudo needed
    mkdir -p "$(dirname "$TARGET_FILE")" 2>/dev/null || true
    mv "$TEMP_FILE" "$TARGET_FILE"
    echo "Installed to $TARGET_FILE"
fi

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

