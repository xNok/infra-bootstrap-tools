#!/bin/bash
set -euo pipefail

echo "### Ansible Lint Run :rocket:" >> "$GITHUB_STEP_SUMMARY"
echo "Running make install-collection and ansible-lint ansible..." >> "$GITHUB_STEP_SUMMARY"

make install-collection
ansible-lint ansible

echo "Lint completed successfully :heavy_check_mark:" >> "$GITHUB_STEP_SUMMARY"
