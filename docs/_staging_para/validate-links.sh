#!/bin/bash
# PARA Link Validation Script
# Checks that all related_projects, related_areas, and related_resources exist

set -euo pipefail

PARA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ERRORS=0

echo "🔍 Validating PARA cross-references..."
echo ""

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
        # Check if a matching file exists
        local found=0
        local search_pattern="$PARA_DIR/$target_dir/*.md"
        
        # Check if any .md files exist first
        if compgen -G "$search_pattern" > /dev/null; then
            for target_file in $search_pattern; do
                if [ ! -f "$target_file" ]; then
                    continue
                fi
                local basename=$(basename "$target_file" .md)
                if [ "$basename" = "$item" ]; then
                    found=1
                    break
                fi
            done
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
