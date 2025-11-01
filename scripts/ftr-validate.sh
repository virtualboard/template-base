#!/bin/bash

# ftr-validate.sh - Validate feature specs and enforce rules
# Usage: ./ftr-validate.sh [feature-file]

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURES_DIR="${SCRIPT_DIR}/../features"
SCHEMA_FILE="${SCRIPT_DIR}/frontmatter.schema.json"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Track errors
HAS_ERRORS=0

# Function to extract frontmatter field
extract_field() {
    local file="$1"
    local field="$2"

    awk '/^---$/,/^---$/' "$file" | sed '1d;$d' | grep "^${field}:" | sed "s/^${field}: *//" | tr -d '"' || echo ""
}

# Function to extract array field
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
                gsub(/, */, \"|\"
                print
            } else {
                # Multi-line array
                getline
                while (\$0 ~ /^  - /) {
                    gsub(/^  - /, \"\")
                    gsub(/['\"]/, \"\")
                    printf \"%s|\", \$0
                    getline
                }
            }
        }
    " | sed 's/|$//'
}

# Function to check if frontmatter exists
has_frontmatter() {
    local file="$1"
    grep -q "^---$" "$file" && {
        local count=$(grep -c "^---$" "$file")
        [[ $count -ge 2 ]]
    }
}

# Function to validate a single feature file
validate_feature() {
    local file="$1"
    local errors=()

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}File not found: $file${NC}"
        return 1
    fi

    # Check for frontmatter
    if ! has_frontmatter "$file"; then
        errors+=("Missing frontmatter section")
    else
        # Extract fields
        local id=$(extract_field "$file" "id")
        local title=$(extract_field "$file" "title")
        local status=$(extract_field "$file" "status")
        local owner=$(extract_field "$file" "owner")
        local priority=$(extract_field "$file" "priority")
        local complexity=$(extract_field "$file" "complexity")
        local created=$(extract_field "$file" "created")
        local updated=$(extract_field "$file" "updated")
        local dependencies=$(extract_array "$file" "dependencies")

        # Validate required fields
        [[ -z "$id" ]] && errors+=("Missing required field: id")
        [[ -z "$title" ]] && errors+=("Missing required field: title")
        [[ -z "$status" ]] && errors+=("Missing required field: status")
        [[ -z "$created" ]] && errors+=("Missing required field: created")
        [[ -z "$updated" ]] && errors+=("Missing required field: updated")

        # Validate ID format (FTR-XXXX)
        if [[ -n "$id" ]] && ! [[ "$id" =~ ^FTR-[0-9]{4}$ ]]; then
            errors+=("Invalid ID format: $id (expected FTR-XXXX)")
        fi

        # Validate status enum
        if [[ -n "$status" ]]; then
            case "$status" in
                backlog|in-progress|blocked|review|done)
                    ;;
                *)
                    errors+=("Invalid status: $status")
                    ;;
            esac

            # Check if file is in correct folder
            local expected_dir="${FEATURES_DIR}/${status}"
            local actual_dir=$(dirname "$file")
            if [[ "$actual_dir" != "$expected_dir" ]]; then
                errors+=("Status '$status' does not match folder location. Expected: $expected_dir")
            fi
        fi

        # Validate priority enum
        if [[ -n "$priority" ]]; then
            case "$priority" in
                P0|P1|P2|P3)
                    ;;
                *)
                    errors+=("Invalid priority: $priority")
                    ;;
            esac
        fi

        # Validate complexity enum
        if [[ -n "$complexity" ]]; then
            case "$complexity" in
                XS|S|M|L|XL)
                    ;;
                *)
                    errors+=("Invalid complexity: $complexity")
                    ;;
            esac
        fi

        # Validate date formats (YYYY-MM-DD)
        if [[ -n "$created" ]] && ! [[ "$created" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            errors+=("Invalid created date format: $created (expected YYYY-MM-DD)")
        fi
        if [[ -n "$updated" ]] && ! [[ "$updated" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            errors+=("Invalid updated date format: $updated (expected YYYY-MM-DD)")
        fi

        # Validate dependencies
        if [[ -n "$dependencies" ]]; then
            IFS='|' read -ra DEPS <<< "$dependencies"
            for dep in "${DEPS[@]}"; do
                # Check dependency ID format
                if ! [[ "$dep" =~ ^FTR-[0-9]{4}$ ]]; then
                    errors+=("Invalid dependency format: $dep")
                else
                    # Check if dependency file exists
                    local dep_found=0
                    for subdir in backlog in-progress blocked review done; do
                        if [[ -f "${FEATURES_DIR}/${subdir}/${dep}.md" ]]; then
                            dep_found=1

                            # If current status is in-progress, dependency should be done
                            if [[ "$status" == "in-progress" ]]; then
                                local dep_status=$(extract_field "${FEATURES_DIR}/${subdir}/${dep}.md" "status")
                                if [[ "$dep_status" != "done" ]]; then
                                    errors+=("Dependency $dep is not done (status: $dep_status)")
                                fi
                            fi
                            break
                        fi
                    done
                    if [[ $dep_found -eq 0 ]]; then
                        errors+=("Dependency $dep not found")
                    fi
                fi
            done
        fi
    fi

    # Report errors
    if [[ ${#errors[@]} -gt 0 ]]; then
        echo -e "\n${RED}Validation errors in $file:${NC}"
        for error in "${errors[@]}"; do
            echo -e "  - $error"
        done
        return 1
    else
        echo -e "${GREEN}✓ $file${NC}"
        return 0
    fi
}

# Function to check for circular dependencies
check_circular_deps() {
    local id="$1"
    local visited="$2"

    # Check if we've already visited this ID (circular dependency)
    if [[ "$visited" == *"$id"* ]]; then
        echo "Circular dependency detected: $visited -> $id"
        return 1
    fi

    # Add current ID to visited chain
    local new_visited="${visited}${id} -> "

    # Find the feature file
    local file=""
    for subdir in backlog in-progress blocked review done; do
        if [[ -f "${FEATURES_DIR}/${subdir}/${id}.md" ]]; then
            file="${FEATURES_DIR}/${subdir}/${id}.md"
            break
        fi
    done

    if [[ -z "$file" ]]; then
        return 0  # File not found, already reported in validate_feature
    fi

    # Get dependencies
    local dependencies=$(extract_array "$file" "dependencies")
    if [[ -n "$dependencies" ]]; then
        IFS='|' read -ra DEPS <<< "$dependencies"
        for dep in "${DEPS[@]}"; do
            if ! check_circular_deps "$dep" "$new_visited"; then
                return 1
            fi
        done
    fi

    return 0
}

# Main execution
main() {
    local files_to_validate=()

    if [[ $# -gt 0 ]]; then
        # Validate specific file
        files_to_validate=("$1")
    else
        # Validate all feature files
        for subdir in backlog in-progress blocked review done; do
            local dir_path="${FEATURES_DIR}/${subdir}"
            if [[ -d "$dir_path" ]]; then
                for file in "${dir_path}"/*.md 2>/dev/null; do
                    if [[ -f "$file" ]]; then
                        files_to_validate+=("$file")
                    fi
                done
            fi
        done
    fi

    # Validate each file
    for file in "${files_to_validate[@]}"; do
        if ! validate_feature "$file"; then
            HAS_ERRORS=1
        fi
    done

    # Check for circular dependencies
    echo -e "\n${GREEN}Checking for circular dependencies...${NC}"
    local processed_ids=()
    for file in "${files_to_validate[@]}"; do
        if [[ -f "$file" ]]; then
            local id=$(extract_field "$file" "id")
            if [[ -n "$id" ]]; then
                # Only check each ID once
                if [[ ! " ${processed_ids[@]} " =~ " ${id} " ]]; then
                    processed_ids+=("$id")
                    if ! check_circular_deps "$id" ""; then
                        HAS_ERRORS=1
                    fi
                fi
            fi
        fi
    done

    # Final result
    if [[ $HAS_ERRORS -eq 1 ]]; then
        echo -e "\n${RED}Validation failed!${NC}"
        exit 1
    else
        echo -e "\n${GREEN}All validations passed!${NC}"
        exit 0
    fi
}

main "$@"