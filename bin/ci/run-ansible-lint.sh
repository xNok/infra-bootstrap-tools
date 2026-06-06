#!/usr/bin/env bash
set -euo pipefail
make install-collection
ansible-lint ansible
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :white_check_mark: Ansible Lint Passed" >> "$GITHUB_STEP_SUMMARY"
fi
