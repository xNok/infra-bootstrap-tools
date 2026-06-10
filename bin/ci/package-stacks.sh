#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <stacks_dir> <version> <dist_dir>"
  exit 1
fi

DIR="$1"
VERSION="$2"
DIST_DIR="$3"

mkdir -p "$DIST_DIR"

# Create individual stack archives
for stack in "$DIR"/*/; do
  if [ -d "$stack" ] && [ "$(basename "$stack")" != "node_modules" ]; then
    stack_name=$(basename "$stack")
    echo "Creating archive for $stack_name"
    (cd "$(dirname "$stack")" && zip -r "$DIST_DIR/${stack_name}-${VERSION}.zip" "$stack_name" -x "*/node_modules/*" "*.git/*")
  fi
done

# Create a complete stacks archive
echo "Creating complete stacks archive"
(cd "$DIR" && zip -r "$DIST_DIR/infra-bootstrap-tools-stacks-${VERSION}.zip" . -x "node_modules/*" "*.git/*" "*/node_modules/*")

ls -lh "$DIST_DIR/"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :package: Stacks Packaged" >> "$GITHUB_STEP_SUMMARY"
  echo "**Version**: \`$VERSION\`" >> "$GITHUB_STEP_SUMMARY"
fi
