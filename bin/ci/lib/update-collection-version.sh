#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <version> <collection_dir>"
  exit 1
fi

VERSION="$1"
COLLECTION_DIR="$2"

yq -i ".version = \"${VERSION}\"" "${COLLECTION_DIR}/galaxy.yml"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :label: Updated Collection Version" >> "$GITHUB_STEP_SUMMARY"
  echo "Set version to \`${VERSION}\` in \`${COLLECTION_DIR}/galaxy.yml\`" >> "$GITHUB_STEP_SUMMARY"
fi
