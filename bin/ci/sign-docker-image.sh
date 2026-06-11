#!/usr/bin/env bash

set -euo pipefail

# This script signs a Docker image digest with given tags using cosign
# Usage: ./bin/ci/sign-docker-image.sh <tags> <digest>

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <tags> <digest>"
  exit 1
fi

TAGS="$1"
DIGEST="$2"

echo "Signing image digest $DIGEST with tags:"
echo "$TAGS"

echo "${TAGS}" | xargs -I {} cosign sign --yes {}@${DIGEST}

# Output summary to GitHub step summary if running in CI
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :closed_lock_with_key: Docker Image Signed" >> "$GITHUB_STEP_SUMMARY"
  echo "**Digest**: \`$DIGEST\`" >> "$GITHUB_STEP_SUMMARY"
  echo "**Tags**:" >> "$GITHUB_STEP_SUMMARY"
  echo "$TAGS" | while read -r tag; do
    if [[ -n "$tag" ]]; then
      echo "- \`$tag\`" >> "$GITHUB_STEP_SUMMARY"
    fi
  done
fi
