#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <command> [args...]"
  exit 1
fi

COMMAND="$1"
shift
ARGS=("$@")

# Execute the command
set +e
output=$("${COMMAND}" "${ARGS[@]}" 2>&1)
exit_code=$?
set -e

# Write to summary if available
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### Command Execution Results: \`${COMMAND}\`" >> "$GITHUB_STEP_SUMMARY"
  if [ "$exit_code" -eq 0 ]; then
    echo "✅ Execution passed successfully" >> "$GITHUB_STEP_SUMMARY"
  else
    echo "❌ Execution failed" >> "$GITHUB_STEP_SUMMARY"
  fi
  echo "\`\`\`" >> "$GITHUB_STEP_SUMMARY"
  echo "$output" >> "$GITHUB_STEP_SUMMARY"
  echo "\`\`\`" >> "$GITHUB_STEP_SUMMARY"
fi

# Print output to console
echo "$output"

exit "$exit_code"
