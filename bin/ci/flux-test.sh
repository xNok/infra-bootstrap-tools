#!/usr/bin/env bash
set -euo pipefail

# Add a summary header to the GITHUB_STEP_SUMMARY if available
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### Flux D2 Integration Test" >> "$GITHUB_STEP_SUMMARY"
  echo "Running the flux bootstrap test script..." >> "$GITHUB_STEP_SUMMARY"
fi

./bin/tests/flux-d2/test.sh
