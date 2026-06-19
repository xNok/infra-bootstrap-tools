#!/usr/bin/env bash
set -euo pipefail

# This script runs the Flux D2 bootstrap test

# Output summary to GitHub step summary if running in CI
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :test_tube: Running Flux D2 Bootstrap Test" >> "$GITHUB_STEP_SUMMARY"
fi

# Run the test script and capture the exit code
EXIT_CODE=0
./bin/tests/flux-d2/test.sh || EXIT_CODE=$?

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  # Parse the generated test-results.log if it exists
  if [[ -f "test-results.log" ]]; then
    echo "#### Test Results:" >> "$GITHUB_STEP_SUMMARY"
    echo '```' >> "$GITHUB_STEP_SUMMARY"
    cat test-results.log >> "$GITHUB_STEP_SUMMARY"
    echo '```' >> "$GITHUB_STEP_SUMMARY"
  fi

  if [[ $EXIT_CODE -eq 0 ]]; then
    echo "### :white_check_mark: Flux D2 Bootstrap Test Completed Successfully" >> "$GITHUB_STEP_SUMMARY"
    echo "All resources have been bootstrapped and validated." >> "$GITHUB_STEP_SUMMARY"
  else
    echo "### :x: Flux D2 Bootstrap Test Failed!" >> "$GITHUB_STEP_SUMMARY"
    echo "The test script exited with code $EXIT_CODE. Check the workflow logs for more details." >> "$GITHUB_STEP_SUMMARY"
  fi
fi

# Exit with the actual status of the test script
exit $EXIT_CODE