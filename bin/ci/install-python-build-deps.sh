#!/usr/bin/env bash
set -euo pipefail
python -m pip install --upgrade pip
pip install build twine
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  echo "Installed Python build dependencies: build, twine" >> "$GITHUB_STEP_SUMMARY"
fi
