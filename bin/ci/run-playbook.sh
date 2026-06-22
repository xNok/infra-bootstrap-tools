#!/bin/bash
set -euo pipefail

echo "### Ansible Playbook Run :rocket:" >> "$GITHUB_STEP_SUMMARY"
echo "Running main playbook on inventory..." >> "$GITHUB_STEP_SUMMARY"

ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/main.yml

echo "Playbook execution completed successfully :heavy_check_mark:" >> "$GITHUB_STEP_SUMMARY"
