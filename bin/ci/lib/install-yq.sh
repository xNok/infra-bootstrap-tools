#!/usr/bin/env bash
set -euo pipefail

# Download and install yq
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :hammer_and_wrench: Installed yq" >> "$GITHUB_STEP_SUMMARY"
  echo "yq version: $(yq --version)" >> "$GITHUB_STEP_SUMMARY"
fi
