#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <event_name> <tag>"
  exit 1
fi

EVENT_NAME="$1"
TAG="$2"

# Extract version from tag (format: package@1.0.0 or v1.0.0 or just 1.0.0)
VERSION=$(echo "$TAG" | sed 's/^.*@//' | sed 's/^v//')

# GitHub Actions standard mechanism to set outputs
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
  echo "VERSION=$VERSION" >> "$GITHUB_OUTPUT"
  echo "tag=$TAG" >> "$GITHUB_OUTPUT"
fi

echo "Version: $VERSION"
