#!/usr/bin/env bash
set -euo pipefail

pip install ansible-core

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :hammer_and_wrench: Installed Ansible Core" >> "$GITHUB_STEP_SUMMARY"
  if command -v ansible >/dev/null 2>&1; then
    echo "Ansible version: $(ansible --version | head -n 1)" >> "$GITHUB_STEP_SUMMARY"
  fi
fi
