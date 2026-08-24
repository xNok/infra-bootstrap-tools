#!/usr/bin/env bash
set -euo pipefail

echo "Running yarn to install Node.js dependencies..."
yarn

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :package: Node.js Dependencies Installed" >> "$GITHUB_STEP_SUMMARY"
  echo "Dependencies were successfully installed using \`yarn\`." >> "$GITHUB_STEP_SUMMARY"
fi
