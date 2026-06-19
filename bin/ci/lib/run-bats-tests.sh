#!/usr/bin/env bash
set -euo pipefail

bats --formatter tap bin/tests/ci > test_results.tap

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :test_tube: BATS Test Results" >> "$GITHUB_STEP_SUMMARY"
  echo '```tap' >> "$GITHUB_STEP_SUMMARY"
  cat test_results.tap >> "$GITHUB_STEP_SUMMARY"
  echo '```' >> "$GITHUB_STEP_SUMMARY"
fi

# Print it so we can see the results in CI logs
cat test_results.tap
