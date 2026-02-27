#!/bin/bash

# worktree-setup.sh - Setup git worktree for feature development
# Usage: ./worktree-setup.sh <feature_id> <feature_slug> [worktree_base_path]
#
# Creates a git worktree with branch naming convention:
#   feature/<feature_id>/<feature_slug>
#
# Returns JSON with worktree status for Claude to parse.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage check
if [ $# -lt 2 ]; then
    echo "Usage: $0 <feature_id> <feature_slug> [worktree_base_path] [base_branch]"
    echo ""
    echo "Arguments:"
    echo "  feature_id        Feature ID (e.g., FTR-0042)"
    echo "  feature_slug      Feature slug from filename (e.g., user-authentication)"
    echo "  worktree_base_path  Optional base path (default: /tmp/virtualboard-worktrees)"
    echo "  base_branch       Optional base branch to branch from (default: auto-detect or main)"
    echo ""
    echo "Environment Variables:"
    echo "  VIRTUALBOARD_WORKTREE_PATH  Base path for worktrees"
    echo "  VIRTUALBOARD_BASE_BRANCH    Base branch to create feature branches from"
    echo ""
    echo "Example:"
    echo "  $0 FTR-0042 user-authentication"
    echo "  $0 FTR-0042 user-authentication ~/worktrees"
    echo "  $0 FTR-0042 user-authentication ~/worktrees develop"
    exit 1
fi

FEATURE_ID="$1"
FEATURE_SLUG="$2"
WORKTREE_BASE="${3:-${VIRTUALBOARD_WORKTREE_PATH:-/tmp/virtualboard-worktrees}}"
BASE_BRANCH="${4:-${VIRTUALBOARD_BASE_BRANCH:-}}"

# Get repository name from git remote or directory name
REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || basename "$(pwd)")

# Validate feature ID format
if ! echo "$FEATURE_ID" | grep -qE '^FTR-[0-9]{4}$'; then
    echo -e "${RED}Error: Invalid feature ID format '$FEATURE_ID'${NC}"
    echo "Expected format: FTR-XXXX (e.g., FTR-0042)"
    exit 1
fi

# Construct paths
BRANCH_NAME="feature/$FEATURE_ID/$FEATURE_SLUG"
WORKTREE_DIR="$WORKTREE_BASE/$REPO_NAME/$FEATURE_ID"

echo -e "${BLUE}Setting up worktree for $FEATURE_ID (repo: $REPO_NAME)${NC}"
echo "  Branch: $BRANCH_NAME"
echo "  Directory: $WORKTREE_DIR"
echo ""

# Ensure we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Get the base branch name (configurable, auto-detect, or default to main)
if [ -n "$BASE_BRANCH" ]; then
    MAIN_BRANCH="$BASE_BRANCH"
else
    MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
fi

# Fetch latest from remote
echo -e "${BLUE}Fetching latest from remote...${NC}"
git fetch origin --prune 2>/dev/null || true

# Check if worktree already exists
if [ -d "$WORKTREE_DIR" ]; then
    echo -e "${YELLOW}Worktree already exists at $WORKTREE_DIR${NC}"

    # Verify it's a valid worktree
    if git worktree list | grep -q "$WORKTREE_DIR"; then
        echo -e "${GREEN}Existing worktree is valid${NC}"

        # Get current branch in worktree
        CURRENT_BRANCH=$(git -C "$WORKTREE_DIR" branch --show-current 2>/dev/null || echo "unknown")

        # Get commit info
        COMMITS_AHEAD=$(git -C "$WORKTREE_DIR" rev-list "$MAIN_BRANCH"..HEAD --count 2>/dev/null || echo "0")
        LAST_COMMIT=$(git -C "$WORKTREE_DIR" log -1 --format='%s' 2>/dev/null || echo "none")
        UNCOMMITTED=$(git -C "$WORKTREE_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

        echo ""
        echo -e "${GREEN}Worktree Status:${NC}"
        echo "  Branch: $CURRENT_BRANCH"
        echo "  Commits ahead of $MAIN_BRANCH: $COMMITS_AHEAD"
        echo "  Last commit: $LAST_COMMIT"
        echo "  Uncommitted changes: $UNCOMMITTED files"
        echo ""
        echo "WORKTREE_PATH=$WORKTREE_DIR"
        echo "WORKTREE_STATUS=existing"
        echo "COMMITS_AHEAD=$COMMITS_AHEAD"
        echo "UNCOMMITTED_FILES=$UNCOMMITTED"
        exit 0
    else
        echo -e "${YELLOW}Directory exists but is not a valid worktree. Removing...${NC}"
        rm -rf "$WORKTREE_DIR"
    fi
fi

# Create base directory if needed
mkdir -p "$WORKTREE_BASE"

# Check if branch exists locally
LOCAL_BRANCH_EXISTS=$(git branch --list "$BRANCH_NAME" | wc -l | tr -d ' ')

# Check if branch exists on remote
REMOTE_BRANCH_EXISTS=$(git ls-remote --heads origin "$BRANCH_NAME" 2>/dev/null | wc -l | tr -d ' ')

if [ "$LOCAL_BRANCH_EXISTS" -gt 0 ] || [ "$REMOTE_BRANCH_EXISTS" -gt 0 ]; then
    echo -e "${YELLOW}Branch '$BRANCH_NAME' already exists${NC}"

    if [ "$REMOTE_BRANCH_EXISTS" -gt 0 ] && [ "$LOCAL_BRANCH_EXISTS" -eq 0 ]; then
        echo "Creating local tracking branch from remote..."
        git branch --track "$BRANCH_NAME" "origin/$BRANCH_NAME" 2>/dev/null || true
    fi

    # Create worktree from existing branch
    echo -e "${BLUE}Creating worktree from existing branch...${NC}"
    git worktree add "$WORKTREE_DIR" "$BRANCH_NAME"

    # Pull latest if remote exists
    if [ "$REMOTE_BRANCH_EXISTS" -gt 0 ]; then
        echo "Pulling latest changes..."
        git -C "$WORKTREE_DIR" pull --rebase origin "$BRANCH_NAME" 2>/dev/null || true
    fi

    # Get commit info
    COMMITS_AHEAD=$(git -C "$WORKTREE_DIR" rev-list "$MAIN_BRANCH"..HEAD --count 2>/dev/null || echo "0")
    LAST_COMMIT=$(git -C "$WORKTREE_DIR" log -1 --format='%s' 2>/dev/null || echo "none")

    echo ""
    echo -e "${GREEN}Worktree created from existing branch${NC}"
    echo "  Commits ahead of $MAIN_BRANCH: $COMMITS_AHEAD"
    echo "  Last commit: $LAST_COMMIT"
    echo ""
    echo "WORKTREE_PATH=$WORKTREE_DIR"
    echo "WORKTREE_STATUS=existing_branch"
    echo "COMMITS_AHEAD=$COMMITS_AHEAD"
    echo "UNCOMMITTED_FILES=0"
else
    echo -e "${BLUE}Creating new branch '$BRANCH_NAME' from $MAIN_BRANCH${NC}"

    # Create worktree with new branch
    git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" "$MAIN_BRANCH"

    echo ""
    echo -e "${GREEN}Worktree created with new branch${NC}"
    echo ""
    echo "WORKTREE_PATH=$WORKTREE_DIR"
    echo "WORKTREE_STATUS=new"
    echo "COMMITS_AHEAD=0"
    echo "UNCOMMITTED_FILES=0"
fi

echo ""
echo -e "${GREEN}Success!${NC} Worktree ready at: $WORKTREE_DIR"
echo ""
echo "Next steps:"
echo "  cd $WORKTREE_DIR"
echo "  claude  # Start Claude Code session"
