#!/usr/bin/env bash
set -euo pipefail

yarn

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :yarn: Yarn Install" >> "$GITHUB_STEP_SUMMARY"
  echo "Successfully ran \`yarn\`." >> "$GITHUB_STEP_SUMMARY"
fi
