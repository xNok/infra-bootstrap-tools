#!/usr/bin/env bash
set -euo pipefail
DIR="$1"
TAG="$2"
gh release upload "$TAG" "$DIR"/dist/* --clobber
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  echo "Uploaded python package artifacts from $DIR to release tag $TAG" >> "$GITHUB_STEP_SUMMARY"
fi
