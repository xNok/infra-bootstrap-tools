#!/usr/bin/env bash
set -euo pipefail
ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/main.yml
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :rocket: Ansible Playbook Executed Successfully" >> "$GITHUB_STEP_SUMMARY"
fi
