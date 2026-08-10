#!/usr/bin/env bash
set -euo pipefail

# Install ansible-core
pip install ansible-core

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :hammer_and_wrench: Installed ansible-core" >> "$GITHUB_STEP_SUMMARY"
  # ansible-galaxy --version or pip show ansible-core could be used for version,
  # but ansible --version is probably safest to extract the core version.
  # Assuming ansible or ansible-core is accessible in PATH if pip installs it.
  echo "ansible-core version: $(pip show ansible-core | grep Version | awk '{print $2}')" >> "$GITHUB_STEP_SUMMARY"
fi
