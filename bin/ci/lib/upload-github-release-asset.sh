#!/usr/bin/env bash
set -euo pipefail

if [ "${EVENT_NAME:-}" == "workflow_dispatch" ] || [ "${EVENT_NAME:-}" == "workflow_call" ]; then
  TAG="${INPUTS_RELEASE_TAG:-}"
else
  TAG="${GITHUB_REF_NAME:-}"
fi

if gh release view "$TAG" > /dev/null 2>&1; then
  gh release upload "$TAG" \
    "$ASSET_PATH" \
    --clobber

  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "### :rocket: Uploaded to GitHub Release" >> "$GITHUB_STEP_SUMMARY"
    echo "Uploaded \`$ASSET_PATH\` to release \`$TAG\`" >> "$GITHUB_STEP_SUMMARY"
  fi
else
  echo "No GitHub Release found for tag $TAG, skipping upload"
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "### :warning: Release not found" >> "$GITHUB_STEP_SUMMARY"
    echo "No GitHub Release found for tag \`$TAG\`, skipping upload" >> "$GITHUB_STEP_SUMMARY"
  fi
fi
