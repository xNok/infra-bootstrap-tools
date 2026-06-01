#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${BASE_URL:-}" ]]; then
  echo "BASE_URL is not set"
  exit 1
fi

cd website
hugo \
  --gc \
  --minify \
  --baseURL "${BASE_URL}/"

# Output summary to GitHub step summary if running in CI
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :rocket: Website Built" >> "$GITHUB_STEP_SUMMARY"
  echo "Site successfully built with Hugo." >> "$GITHUB_STEP_SUMMARY"
fi
