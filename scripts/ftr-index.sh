#!/bin/bash

# ftr-index.sh - Generate features/INDEX.md
# Usage: ./ftr-index.sh

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURES_DIR="${SCRIPT_DIR}/../features"
INDEX_FILE="${FEATURES_DIR}/INDEX.md"

# Function to extract frontmatter field
extract_field() {
    local file="$1"
    local field="$2"

    # Extract frontmatter section
    awk '/^---$/,/^---$/' "$file" | sed '1d;$d' | grep "^${field}:" | sed "s/^${field}: *//" | tr -d '"' || echo ""
}

# Function to extract array field (like labels or dependencies)
extract_array() {
    local file="$1"
    local field="$2"

    awk '/^---$/,/^---$/' "$file" | awk "
        /^${field}:/ {
            if (\$0 ~ /\\[.*\\]/) {
                # Inline array
                gsub(/.*\\[/, \"\")
                gsub(/\\].*/, \"\")
                gsub(/['\"]/, \"\")
                print
            } else {
                # Multi-line array
                getline
                while (\$0 ~ /^  - /) {
                    gsub(/^  - /, \"\")
                    gsub(/['\"]/, \"\")
                    printf \"%s, \", \$0
                    getline
                }
            }
        }
    " | sed 's/, $//'
}

# Initialize markdown content
MARKDOWN="# Features Index

> Auto-generated on $(date +%Y-%m-%d) - Do not edit manually

| ID | Title | Status | Owner | P | C | Labels | Updated | File |
|---|---|---|---|---|---|---|---|
"

# Arrays to store features and status counts
declare -a FEATURES
declare -A STATUS_COUNTS
TOTAL_COUNT=0

# Process each status directory
for STATUS_DIR in backlog in-progress blocked review done; do
    DIR_PATH="${FEATURES_DIR}/${STATUS_DIR}"

    if [[ ! -d "$DIR_PATH" ]]; then
        continue
    fi

    # Process each markdown file
    for FILE in "${DIR_PATH}"/*.md 2>/dev/null; do
        if [[ ! -f "$FILE" ]]; then
            continue
        fi

        # Extract frontmatter fields
        ID=$(extract_field "$FILE" "id")

        # Skip if no ID
        if [[ -z "$ID" ]]; then
            continue
        fi

        TITLE=$(extract_field "$FILE" "title")
        STATUS=$(extract_field "$FILE" "status")
        OWNER=$(extract_field "$FILE" "owner")
        PRIORITY=$(extract_field "$FILE" "priority")
        COMPLEXITY=$(extract_field "$FILE" "complexity")
        LABELS=$(extract_array "$FILE" "labels")
        UPDATED=$(extract_field "$FILE" "updated")

        # Default values
        [[ -z "$OWNER" ]] && OWNER="unassigned"

        # Get relative path
        REL_PATH=$(realpath --relative-to="$FEATURES_DIR" "$FILE")

        # Store feature for sorting
        FEATURES+=("${ID}|${TITLE}|${STATUS}|${OWNER}|${PRIORITY}|${COMPLEXITY}|${LABELS}|${UPDATED}|${REL_PATH}")

        # Update status count
        if [[ -n "$STATUS" ]]; then
            STATUS_COUNTS["$STATUS"]=$((${STATUS_COUNTS["$STATUS"]:-0} + 1))
        fi
        TOTAL_COUNT=$((TOTAL_COUNT + 1))
    done
done

# Sort features by ID and add to markdown
IFS=$'\n' SORTED=($(printf "%s\n" "${FEATURES[@]}" | sort -t'|' -k1,1))

for FEATURE in "${SORTED[@]}"; do
    IFS='|' read -r ID TITLE STATUS OWNER PRIORITY COMPLEXITY LABELS UPDATED REL_PATH <<< "$FEATURE"
    MARKDOWN+="| ${ID} | ${TITLE} | ${STATUS} | ${OWNER} | ${PRIORITY} | ${COMPLEXITY} | ${LABELS} | ${UPDATED} | [${REL_PATH}](../features/${REL_PATH}) |
"
done

# Add summary
MARKDOWN+="
## Summary

"

# Add status counts
for STATUS in backlog in-progress blocked review done; do
    if [[ ${STATUS_COUNTS["$STATUS"]+isset} ]]; then
        MARKDOWN+="- **${STATUS}**: ${STATUS_COUNTS["$STATUS"]}
"
    fi
done

MARKDOWN+="
**Total**: ${TOTAL_COUNT} features
"

# Write to file
echo "$MARKDOWN" > "$INDEX_FILE"

echo "Generated features/INDEX.md"