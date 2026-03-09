#!/bin/bash
# PARA Link Validation Script
# Checks that all related_projects, related_areas, and related_resources exist

set -euo pipefail

PARA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ERRORS=0

echo "🔍 Validating PARA cross-references..."
echo ""

# Initialize cache for file existence
# Key format: "target_dir/item"
declare -A file_cache

# Populate cache for all potential target directories
for dir in "$PARA_DIR"/*/; do
    dir_name=$(basename "$dir")
    for f in "$dir"/*.md; do
        if [ -f "$f" ]; then
            # Extract basename without .md using string manipulation
            bn="${f##*/}"
            item="${bn%.md}"
            file_cache["$dir_name/$item"]=1
        fi
    done
done

# Extract related items from frontmatter
check_references() {
    local file="$1"
    local type="$2"
    local target_dir="$3"
    
    # Extract items from frontmatter (related_projects, related_areas, etc.)
    local items=$(awk -v type="related_${type}:" '
        $0 ~ type { in_section=1; next }
        in_section && /^[a-z_]+:$/ { in_section=0 }
        in_section && /^---$/ { in_section=0 }
        in_section && /^  - / { sub(/^  - /, ""); print }
    ' "$file")
    
    if [ -z "$items" ]; then
        return 0
    fi
    
    echo "📄 Checking $file ($type)..."
    
    for item in $items; do
        # Check if a matching file exists using the cache
        local found=0
        if [[ ${file_cache["$target_dir/$item"]:-} ]]; then
            found=1
        fi
        
        if [ $found -eq 0 ]; then
            echo "  ❌ Missing: $item (expected in $target_dir/)"
            ERRORS=$((ERRORS + 1))
        else
            echo "  ✅ Found: $item"
        fi
    done
    echo ""
}

# Check all markdown files in projects and areas
for file in "$PARA_DIR"/{1-projects,2-areas}/*.md; do
    if [ -f "$file" ]; then
        check_references "$file" "projects" "1-projects"
        check_references "$file" "areas" "2-areas"
        check_references "$file" "resources" "3-resources"
    fi
done

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ All cross-references are valid!"
    exit 0
else
    echo "❌ Found $ERRORS broken reference(s)"
    exit 1
fi
