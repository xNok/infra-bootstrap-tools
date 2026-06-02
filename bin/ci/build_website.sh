#!/usr/bin/env bash
set -euo pipefail

HUGO_VERSION="${HUGO_VERSION:-0.147.3}"
RUNNER_TEMP="${RUNNER_TEMP:-/tmp}"
BASE_URL="${BASE_URL:-/}"

echo "Installing Hugo CLI version ${HUGO_VERSION}..."
wget -q -O "${RUNNER_TEMP}/hugo.deb" "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb"
sudo dpkg -i "${RUNNER_TEMP}/hugo.deb"

echo "Building website with Hugo..."
cd website
export HUGO_ENVIRONMENT="production"
export HUGO_ENV="production"
hugo --gc --minify --baseURL "${BASE_URL}"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "### Website Build Successful :rocket:" >> "$GITHUB_STEP_SUMMARY"
    echo "- **Hugo Version:** ${HUGO_VERSION}" >> "$GITHUB_STEP_SUMMARY"
    echo "- **Base URL:** ${BASE_URL}" >> "$GITHUB_STEP_SUMMARY"
fi
