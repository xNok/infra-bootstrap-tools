#!/usr/bin/env bash
set -euo pipefail
DIR="$1"
NAME="$2"
VERSION="$3"
cd "$DIR"
sed -i "s/^version = .*/version = \"$VERSION\"/" pyproject.toml
sed -i "s/^name = .*/name = \"$NAME\"/" pyproject.toml
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  echo "Updated pyproject.toml in $DIR: name=$NAME, version=$VERSION" >> "$GITHUB_STEP_SUMMARY"
fi
