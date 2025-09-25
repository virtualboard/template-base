#!/bin/bash

# ftr-move.sh - Move feature across lifecycle with validation
# Usage: ./ftr-move.sh FTR-XXXX new-status [owner]

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 FTR-XXXX new-status [owner]"
    echo "Statuses: backlog, in-progress, blocked, review, done"
    exit 1
fi

FTR_ID="$1"
NEW_STATUS="$2"
OWNER="${3:-unassigned}"

# Validate status
case "$NEW_STATUS" in
    backlog|in-progress|blocked|review|done)
        ;;
    *)
        echo "Error: Invalid status '$NEW_STATUS'"
        echo "Valid statuses: backlog, in-progress, blocked, review, done"
        exit 1
        ;;
esac

# Find the feature file
FEATURE_FILE=$(find features -name "$FTR_ID-*.md" 2>/dev/null | head -1)

if [ -z "$FEATURE_FILE" ]; then
    echo "Error: Feature $FTR_ID not found"
    exit 1
fi

# Get current status from frontmatter
CURRENT_STATUS=$(grep "^status:" "$FEATURE_FILE" | sed 's/^status: *//')

echo "Moving $FTR_ID from $CURRENT_STATUS to $NEW_STATUS"

# Validate transition
case "$CURRENT_STATUS" in
    backlog)
        if [ "$NEW_STATUS" != "in-progress" ]; then
            echo "Error: Can only move from backlog to in-progress"
            exit 1
        fi
        ;;
    in-progress)
        if [[ "$NEW_STATUS" != "blocked" && "$NEW_STATUS" != "review" ]]; then
            echo "Error: Can only move from in-progress to blocked or review"
            exit 1
        fi
        ;;
    blocked)
        if [ "$NEW_STATUS" != "in-progress" ]; then
            echo "Error: Can only move from blocked to in-progress"
            exit 1
        fi
        ;;
    review)
        if [[ "$NEW_STATUS" != "in-progress" && "$NEW_STATUS" != "done" ]]; then
            echo "Error: Can only move from review to in-progress or done"
            exit 1
        fi
        ;;
    done)
        echo "Error: Cannot move from done status"
        exit 1
        ;;
esac

# Check dependencies if moving to in-progress
if [ "$NEW_STATUS" = "in-progress" ]; then
    DEPS=$(grep -A 1 "^dependencies:" "$FEATURE_FILE" | tail -1 | sed 's/^[[:space:]]*//' | sed 's/\[//g' | sed 's/\]//g' | sed 's/,/ /g' | grep -o 'FTR-[0-9]\+' || true)
    for dep in $DEPS; do
        if [ "$dep" != "" ] && [ "$dep" != "[]" ]; then
            DEP_STATUS=$(find features -name "$dep-*.md" 2>/dev/null | head -1 | xargs grep -A 1 "^status:" | tail -1 | sed 's/^[[:space:]]*//')
            if [ "$DEP_STATUS" != "done" ]; then
                echo "Error: Dependency $dep is not done (status: $DEP_STATUS)"
                exit 1
            fi
        fi
    done
fi

# Move file to new directory
NEW_DIR="features/$NEW_STATUS"
mkdir -p "$NEW_DIR"

# Update frontmatter
TODAY=$(date +%Y-%m-%d)
echo "Updating frontmatter..."
sed -i '' \
    -e "s/^status: .*/status: $NEW_STATUS/" \
    -e "s/^owner: .*/owner: $OWNER/" \
    -e "s/^updated: .*/updated: $TODAY/" \
    "$FEATURE_FILE"

echo "Moving file..."
# Move file
mv "$FEATURE_FILE" "$NEW_DIR/"

echo "Successfully moved $FTR_ID to $NEW_STATUS"
echo "File: $NEW_DIR/$(basename "$FEATURE_FILE")"
echo "Script completed successfully"
