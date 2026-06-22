#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/../.." && pwd)

LOG_FILE=$(mktemp)

echo "Running Flux D2 integration tests..."

# Temporarily disable set -e to capture the exit code
set +e
"${ROOT_DIR}/bin/tests/flux-d2/test.sh" > "$LOG_FILE" 2>&1
TEST_EXIT_CODE=$?
set -e

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :test_tube: Flux D2 Test Results" >> "$GITHUB_STEP_SUMMARY"

  if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "**Status:** :white_check_mark: Passed" >> "$GITHUB_STEP_SUMMARY"
  else
    echo "**Status:** :x: Failed" >> "$GITHUB_STEP_SUMMARY"
  fi

  echo "<details><summary>Test Logs</summary>" >> "$GITHUB_STEP_SUMMARY"
  echo "" >> "$GITHUB_STEP_SUMMARY"
  echo '```text' >> "$GITHUB_STEP_SUMMARY"
  cat "$LOG_FILE" >> "$GITHUB_STEP_SUMMARY"
  echo '```' >> "$GITHUB_STEP_SUMMARY"
  echo "</details>" >> "$GITHUB_STEP_SUMMARY"
fi

cat "$LOG_FILE"
rm -f "$LOG_FILE"

exit $TEST_EXIT_CODE
