#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR="${ROOT_DIR:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"

# Output summary to GitHub Actions if GITHUB_STEP_SUMMARY is set
GITHUB_STEP_SUMMARY=${GITHUB_STEP_SUMMARY:-""}

LOG_FILE=$(mktemp)
trap 'rm -f "$LOG_FILE"' EXIT

echo "Running Flux D2 bootstrap test..."
set +e
"${ROOT_DIR}/bin/tests/flux-d2/test.sh" 2>&1 | tee "$LOG_FILE"
EXIT_CODE=${PIPESTATUS[0]}
set -e

if [[ -n "$GITHUB_STEP_SUMMARY" ]]; then
  {
    echo "## Flux D2 Bootstrap Test Results"
    echo ""
    if [[ $EXIT_CODE -eq 0 ]]; then
      echo "✅ **Status:** Passed"
    else
      echo "❌ **Status:** Failed"
    fi
    echo ""
    echo "<details><summary>Test Output</summary>"
    echo ""
    echo '```text'
    cat "$LOG_FILE"
    echo '```'
    echo "</details>"
  } >> "$GITHUB_STEP_SUMMARY"
fi

exit $EXIT_CODE
