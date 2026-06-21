#!/usr/bin/env bash

set -e

FLUX_TEST_SCRIPT="${FLUX_TEST_SCRIPT:-./bin/tests/flux-d2/test.sh}"

echo "Running Flux D2 test script: ${FLUX_TEST_SCRIPT}"

set +e
"${FLUX_TEST_SCRIPT}" 2>&1 | tee test-results.log
EXIT_CODE=${PIPESTATUS[0]}
set -e

if [ -n "$GITHUB_STEP_SUMMARY" ]; then
  if [ "$EXIT_CODE" -eq 0 ]; then
    echo "### :white_check_mark: Flux Bootstrap Test Succeeded" >> "$GITHUB_STEP_SUMMARY"
  else
    echo "### :x: Flux Bootstrap Test Failed" >> "$GITHUB_STEP_SUMMARY"
  fi

  echo "<details><summary>Test Logs (last 100 lines)</summary>" >> "$GITHUB_STEP_SUMMARY"
  echo "" >> "$GITHUB_STEP_SUMMARY"
  echo '```' >> "$GITHUB_STEP_SUMMARY"
  tail -n 100 test-results.log >> "$GITHUB_STEP_SUMMARY"
  echo '```' >> "$GITHUB_STEP_SUMMARY"
  echo "</details>" >> "$GITHUB_STEP_SUMMARY"
fi

exit "$EXIT_CODE"
