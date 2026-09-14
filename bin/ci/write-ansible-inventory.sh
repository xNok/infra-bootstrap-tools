#!/usr/bin/env bash
set -euo pipefail

echo "$INVENTORY" > inventory/extra

echo "✅ Ansible inventory extra written." >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
