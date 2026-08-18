#!/usr/bin/env bash

set -euo pipefail

# This script is used by GitHub Actions to build the website with the Hugo
# version provided by the active environment.
# Usage: ./bin/ci/build-website.sh <base_url>
#
# Arguments:
#   base_url: The base URL for the website (e.g., ${{ steps.pages.outputs.base_url }})

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <base_url>"
  exit 1
fi

BASE_URL="$1"
HUGO_VERSION="$(hugo version | head -n 1)"

echo "Building website with Hugo..."
cd website
hugo \
  --gc \
  --minify \
  --baseURL "${BASE_URL}/"

# Output summary to GitHub step summary if running in CI
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :rocket: Website Built Successfully" >> "$GITHUB_STEP_SUMMARY"
  echo "**Hugo Version**: \`${HUGO_VERSION}\`" >> "$GITHUB_STEP_SUMMARY"
  echo "**Base URL**: \`${BASE_URL}\`" >> "$GITHUB_STEP_SUMMARY"
fi
