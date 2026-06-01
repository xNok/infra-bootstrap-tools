#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${HUGO_VERSION:-}" ]]; then
  echo "HUGO_VERSION is not set"
  exit 1
fi

if [[ -z "${RUNNER_TEMP:-}" ]]; then
  echo "RUNNER_TEMP is not set"
  exit 1
fi

wget -O "${RUNNER_TEMP}/hugo.deb" "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb"
sudo dpkg -i "${RUNNER_TEMP}/hugo.deb"

# Output summary to GitHub step summary if running in CI
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :hammer: Hugo Installed" >> "$GITHUB_STEP_SUMMARY"
  echo "**Version**: \`${HUGO_VERSION}\`" >> "$GITHUB_STEP_SUMMARY"
fi
