#!/usr/bin/env bash
# run-flux-test.sh
# Wrapper script to run Flux D2 tests and report the summary to GitHub Actions

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR="${ROOT_DIR:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"

LOG_FILE=$(mktemp)
GITHUB_STEP_SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"

echo "Running Flux D2 tests..."
set +e
"${ROOT_DIR}/bin/tests/flux-d2/test.sh" > "$LOG_FILE" 2>&1
EXIT_CODE=$?
set -e

if [ $EXIT_CODE -eq 0 ]; then
  echo "### :white_check_mark: Flux D2 tests completed successfully" >> "$GITHUB_STEP_SUMMARY"
else
  echo "### :x: Flux D2 tests failed" >> "$GITHUB_STEP_SUMMARY"
fi

echo "<details><summary>Test Output</summary>" >> "$GITHUB_STEP_SUMMARY"
echo "" >> "$GITHUB_STEP_SUMMARY"
echo "\`\`\`" >> "$GITHUB_STEP_SUMMARY"
cat "$LOG_FILE" >> "$GITHUB_STEP_SUMMARY"
echo "\`\`\`" >> "$GITHUB_STEP_SUMMARY"
echo "" >> "$GITHUB_STEP_SUMMARY"
echo "</details>" >> "$GITHUB_STEP_SUMMARY"

cat "$LOG_FILE"
rm -f "$LOG_FILE"

exit $EXIT_CODE
