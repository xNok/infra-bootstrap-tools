#!/usr/bin/env bash
set -euo pipefail
python -m pip install --upgrade pip
pip install ansible-core
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  echo "### :package: Installed Ansible Dependencies" >> "$GITHUB_STEP_SUMMARY"
  echo "Installed \`ansible-core\`" >> "$GITHUB_STEP_SUMMARY"
fi
