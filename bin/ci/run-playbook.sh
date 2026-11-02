#!/bin/bash
set -euo pipefail

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### Ansible Playbook Run :rocket:" >> "$GITHUB_STEP_SUMMARY"
  echo "Running main playbook on inventory..." >> "$GITHUB_STEP_SUMMARY"
fi

ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/main.yml

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "Playbook execution completed successfully :heavy_check_mark:" >> "$GITHUB_STEP_SUMMARY"
fi