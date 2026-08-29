#!/usr/bin/env bash

set -euo pipefail

# This script is used by GitHub Actions to install Hugo and build the website.
# Usage: ./bin/ci/build-website.sh <hugo_version> <runner_temp> <base_url>
#
# Arguments:
#   hugo_version: The version of Hugo to install (e.g., 0.147.3)
#   runner_temp: The temporary directory on the runner (e.g., ${{ runner.temp }})
#   base_url: The base URL for the website (e.g., ${{ steps.pages.outputs.base_url }})

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <hugo_version> <runner_temp> <base_url>"
  exit 1
fi

HUGO_VERSION="$1"
RUNNER_TEMP="$2"
BASE_URL="$3"

echo "Installing Hugo v${HUGO_VERSION}..."
wget -O "${RUNNER_TEMP}/hugo.deb" "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb"
sudo dpkg -i "${RUNNER_TEMP}/hugo.deb"

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
