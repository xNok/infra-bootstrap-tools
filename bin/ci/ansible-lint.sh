#!/bin/bash
set -euo pipefail

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### Ansible Lint Run :rocket:" >> "$GITHUB_STEP_SUMMARY"
  echo "Running make install-collection and ansible-lint ansible..." >> "$GITHUB_STEP_SUMMARY"
fi

make install-collection
ansible-lint ansible

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "Lint completed successfully :heavy_check_mark:" >> "$GITHUB_STEP_SUMMARY"
fi