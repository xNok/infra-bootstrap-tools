#!/usr/bin/env bash
set -euo pipefail

yq -i ".version = \"${VERSION}\"" "${COLLECTION_DIR}/galaxy.yml"

echo "✅ Updated galaxy.yml version to **${VERSION}**." >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
