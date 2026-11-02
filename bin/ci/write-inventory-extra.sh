#!/usr/bin/env bash
set -euo pipefail

# This script writes the extra inventory to a file for ansible.

if [[ -z "${INVENTORY:-}" ]]; then
  echo "Error: INVENTORY environment variable is required." >&2
  exit 1
fi

mkdir -p inventory
echo "$INVENTORY" > inventory/extra

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :gear: Setup Ansible Extra Inventory" >> "$GITHUB_STEP_SUMMARY"
  echo "Wrote inventory extra configuration to \`inventory/extra\`." >> "$GITHUB_STEP_SUMMARY"
fi
