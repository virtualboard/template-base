#!/bin/bash

# ftr-new.sh - Create a new feature spec from template
# Usage: ./ftr-new.sh "Feature Title" label1 label2

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 \"Feature Title\" [label1] [label2] ..."
    exit 1
fi

TITLE="$1"
shift
LABELS="$@"

# Get next available ID
NEXT_ID=$(find features -name "FTR-*.md" 2>/dev/null | \
    grep -o 'FTR-[0-9]\+' | \
    sed 's/FTR-//' | \
    sort -n | \
    tail -1 | \
    awk '{printf "%04d", $1+1}')

if [ -z "$NEXT_ID" ]; then
    NEXT_ID="0001"
fi

# Create kebab-case filename
FILENAME=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
FTR_ID="FTR-$NEXT_ID"
FILE_PATH="features/backlog/$FTR_ID-$FILENAME.md"

# Create feature spec from template
cp templates/feature.md "$FILE_PATH"

# Update frontmatter
TODAY=$(date +%Y-%m-%d)
LABELS_YAML=""
if [ ${#LABELS[@]} -gt 0 ]; then
    LABELS_YAML="[$(printf '"%s",' "${LABELS[@]}" | sed 's/,$//')]"
else
    LABELS_YAML="[]"
fi

# Replace template values
sed -i.bak \
    -e "s/FTR-XXXX/$FTR_ID/g" \
    -e "s/<Feature Title>/$TITLE/g" \
    -e "s/YYYY-MM-DD/$TODAY/g" \
    -e "s/^labels: \[\].*/labels: $LABELS_YAML/" \
    "$FILE_PATH"

rm "$FILE_PATH.bak"

echo "Created feature spec: $FILE_PATH"
echo "ID: $FTR_ID"
echo "Title: $TITLE"
echo "Labels: $LABELS_YAML"
