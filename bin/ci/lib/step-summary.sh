#!/usr/bin/env bash
set -euo pipefail

# Writes a message to the GitHub Step Summary if it's available
write_step_summary() {
  local message="$1"
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "✅ $message" >> "$GITHUB_STEP_SUMMARY"
  fi
}
