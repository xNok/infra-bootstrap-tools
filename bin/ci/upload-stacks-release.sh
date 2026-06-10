#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <tag> <dist_dir>"
  exit 1
fi

TAG="$1"
DIST_DIR="$2"

if gh release view "$TAG" > /dev/null 2>&1; then
  gh release upload "$TAG" \
    "$DIST_DIR"/*.zip \
    --clobber

  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "### :rocket: Stacks Uploaded" >> "$GITHUB_STEP_SUMMARY"
    echo "**Release Tag**: \`$TAG\`" >> "$GITHUB_STEP_SUMMARY"
  fi
else
  echo "No GitHub Release found for tag $TAG, skipping upload"
fi
