#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :rocket: Docker Image Build" >> "$GITHUB_STEP_SUMMARY"
  echo "**Image:** \`$1\`" >> "$GITHUB_STEP_SUMMARY"
  echo "**Pushed:** \`$2\`" >> "$GITHUB_STEP_SUMMARY"
  echo "**Tags:** \`$3\`" >> "$GITHUB_STEP_SUMMARY"
  echo "**Digest:** \`$4\`" >> "$GITHUB_STEP_SUMMARY"
fi
