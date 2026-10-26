#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../../.." && pwd)}"

OUTPUT_FILE=$(mktemp)
trap 'rm -f "${OUTPUT_FILE}"' EXIT

# Run bats and capture output while preserving the exit code
set +e
bats --formatter tap "${ROOT_DIR}/bin/tests/ci" > "${OUTPUT_FILE}" 2>&1
EXIT_CODE=$?
set -e

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :test_tube: BATS Test Results" >> "$GITHUB_STEP_SUMMARY"
  echo "<details><summary>Click to expand</summary>" >> "$GITHUB_STEP_SUMMARY"
  echo "" >> "$GITHUB_STEP_SUMMARY"
  echo '```tap' >> "$GITHUB_STEP_SUMMARY"
  cat "${OUTPUT_FILE}" >> "$GITHUB_STEP_SUMMARY"
  echo '```' >> "$GITHUB_STEP_SUMMARY"
  echo "</details>" >> "$GITHUB_STEP_SUMMARY"
fi

# Print it so we can see the results in CI logs
cat "${OUTPUT_FILE}"

# Exit with the actual result of the bats command
exit "$EXIT_CODE"
