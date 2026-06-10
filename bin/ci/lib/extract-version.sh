#!/usr/bin/env bash
set -euo pipefail

if [ "${EVENT_NAME:-}" == "workflow_dispatch" ] || [ "${EVENT_NAME:-}" == "workflow_call" ]; then
  TAG="${INPUTS_RELEASE_TAG:-}"
else
  TAG="${GITHUB_REF_NAME:-}"
fi

# Handle both v1.0.0 and workspace@1.0.0 formats
VERSION=$(echo "$TAG" | sed 's/^.*@//' | sed 's/^v//')

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "VERSION=$VERSION" >> "$GITHUB_OUTPUT"
fi

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :label: Extracted Version" >> "$GITHUB_STEP_SUMMARY"
  echo "Tag: \`$TAG\`" >> "$GITHUB_STEP_SUMMARY"
  echo "Version: \`$VERSION\`" >> "$GITHUB_STEP_SUMMARY"
fi

echo "Version: $VERSION"
