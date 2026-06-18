#!/usr/bin/env bash
set -euo pipefail

# This script runs the Flux D2 bootstrap test

# Output summary to GitHub step summary if running in CI
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :test_tube: Running Flux D2 Bootstrap Test" >> "$GITHUB_STEP_SUMMARY"
fi

./bin/tests/flux-d2/test.sh

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :white_check_mark: Flux D2 Bootstrap Test Completed Successfully" >> "$GITHUB_STEP_SUMMARY"
fi
