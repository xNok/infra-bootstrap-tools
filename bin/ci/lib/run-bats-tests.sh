#!/usr/bin/env bash

# Run bats and capture output while preserving the exit code
exit_code=0
bats_output=$(bats --formatter tap bin/tests/ci) || exit_code=$?

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :test_tube: BATS Test Results" >> "$GITHUB_STEP_SUMMARY"
  echo '```tap' >> "$GITHUB_STEP_SUMMARY"
  echo "$bats_output" >> "$GITHUB_STEP_SUMMARY"
  echo '```' >> "$GITHUB_STEP_SUMMARY"
fi

# Print it so we can see the results in CI logs
echo "$bats_output"

# Exit with the actual result of the bats command
exit "$exit_code"
