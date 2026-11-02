#!/usr/bin/env bash
set -euo pipefail

# This script sets the version of an ansible galaxy collection
# using the extracted version string.

if [[ -z "${VERSION:-}" ]]; then
  echo "Error: VERSION environment variable is required." >&2
  exit 1
fi

COLLECTION_DIR="${1:-ansible}"

if [[ ! -f "$COLLECTION_DIR/galaxy.yml" ]]; then
  echo "Error: $COLLECTION_DIR/galaxy.yml does not exist." >&2
  exit 1
fi

yq -i ".version = \"$VERSION\"" "$COLLECTION_DIR/galaxy.yml"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :gear: Updated Ansible Galaxy Version" >> "$GITHUB_STEP_SUMMARY"
  echo "Updated \`$COLLECTION_DIR/galaxy.yml\` to version \`$VERSION\`." >> "$GITHUB_STEP_SUMMARY"
fi
