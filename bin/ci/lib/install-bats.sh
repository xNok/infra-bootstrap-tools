#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y bats

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :hammer_and_wrench: Installed BATS" >> "$GITHUB_STEP_SUMMARY"
  echo "BATS version: $(bats -v)" >> "$GITHUB_STEP_SUMMARY"
fi
