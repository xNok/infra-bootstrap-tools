#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/../.." && pwd)

echo "Starting Flux D2 integration test..."

# Execute the test script
set +e
"${ROOT_DIR}/bin/tests/flux-d2/test.sh"
TEST_EXIT_CODE=$?
set -e

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :test_tube: Flux Bootstrap Test Results" >> "$GITHUB_STEP_SUMMARY"
  if [ "$TEST_EXIT_CODE" -eq 0 ]; then
    echo "✅ **Status**: Success" >> "$GITHUB_STEP_SUMMARY"
    echo "The Flux D2 bootstrap test completed successfully!" >> "$GITHUB_STEP_SUMMARY"
  else
    echo "❌ **Status**: Failed" >> "$GITHUB_STEP_SUMMARY"
    echo "The Flux D2 bootstrap test failed with exit code \`$TEST_EXIT_CODE\`." >> "$GITHUB_STEP_SUMMARY"
  fi
fi

exit "$TEST_EXIT_CODE"
