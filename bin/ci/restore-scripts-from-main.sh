#!/usr/bin/env bash
set -euo pipefail

DEFAULT_BRANCH="${1:-main}"
[ -z "$DEFAULT_BRANCH" ] && DEFAULT_BRANCH="main"

echo "Restoring CI scripts from default branch: ${DEFAULT_BRANCH}..."

# Fetch the default branch if not already available locally
if ! git rev-parse --verify "origin/${DEFAULT_BRANCH}" >/dev/null 2>&1; then
  git fetch origin "${DEFAULT_BRANCH}":refs/remotes/origin/"${DEFAULT_BRANCH}" --depth=1
fi

# Restore bin/ci directory from origin/DEFAULT_BRANCH
git checkout "origin/${DEFAULT_BRANCH}" -- bin/ci/

echo "CI scripts successfully restored from ${DEFAULT_BRANCH}."
