#!/usr/bin/env bash
set -euo pipefail

# This script signs published Docker images using cosign and writes a summary.
#
# Environment variables expected:
#   TAGS - The newline separated tags to sign
#   DIGEST - The docker image digest
#   GITHUB_STEP_SUMMARY - (Optional) Path to the github step summary file

if [[ -z "${TAGS:-}" || -z "${DIGEST:-}" ]]; then
  echo "Error: TAGS and DIGEST environment variables must be set."
  exit 1
fi

echo "Signing Docker image digest ${DIGEST} with tags:"
echo "${TAGS}"

echo "${TAGS}" | xargs -I {} cosign sign --yes {}@"${DIGEST}"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :closed_lock_with_key: Docker Image Signed" >> "$GITHUB_STEP_SUMMARY"
  echo "**Digest**: \`${DIGEST}\`" >> "$GITHUB_STEP_SUMMARY"

  # Format tags as a list for the summary
  echo "**Tags**:" >> "$GITHUB_STEP_SUMMARY"
  echo "${TAGS}" | while IFS= read -r tag; do
    if [[ -n "$tag" ]]; then
      echo "- \`$tag\`" >> "$GITHUB_STEP_SUMMARY"
    fi
  done
fi
