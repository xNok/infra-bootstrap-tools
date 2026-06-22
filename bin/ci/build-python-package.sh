#!/usr/bin/env bash
set -euo pipefail
DIR="$1"
cd "$DIR"
python -m build
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  echo "Successfully built python package in $DIR" >> "$GITHUB_STEP_SUMMARY"
fi
