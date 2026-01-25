#!/bin/bash
# PARA Link Validation Script
# Checks that all related_projects, related_areas, and related_resources exist

set -e

PARA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ERRORS=0

echo "🔍 Validating PARA cross-references..."
echo ""

# Extract related items from frontmatter
check_references() {
    local file="$1"
    local type="$2"
    local target_dir="$3"
    
    # Extract items from frontmatter
    local items=$(awk '/^related_'$type':$/,/^[a-z_]+:$|^---$/ {print}' "$file" | grep '  -' | sed 's/  - //')
    
    if [ -z "$items" ]; then
        return 0
    fi
    
    echo "📄 Checking $file ($type)..."
    
    for item in $items; do
        # Check if a matching file exists
        local found=0
        for dir in "$PARA_DIR/$target_dir"/*; do
            if [ -d "$dir" ]; then
                continue
            fi
            local basename=$(basename "$dir" .md)
            if [ "$basename" = "$item" ]; then
                found=1
                break
            fi
        done
        
        if [ $found -eq 0 ]; then
            echo "  ❌ Missing: $item (expected in $target_dir/)"
            ERRORS=$((ERRORS + 1))
        else
            echo "  ✅ Found: $item"
        fi
    done
    echo ""
}

# Check all markdown files
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
