#!/usr/bin/env bash
set -euo pipefail

COLLECTION_DIR="${COLLECTION_DIR:-ansible}"

OUTPUT=$(ansible-galaxy collection build "$COLLECTION_DIR")
TARBALL=$(echo "$OUTPUT" | grep -o 'Created collection file .*.tar.gz' | sed 's/Created collection file //')

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "TARBALL=$TARBALL" >> "$GITHUB_OUTPUT"
fi

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :package: Built Ansible Collection" >> "$GITHUB_STEP_SUMMARY"
  echo "Tarball: \`$TARBALL\`" >> "$GITHUB_STEP_SUMMARY"
fi

echo "Created tarball: $TARBALL"
