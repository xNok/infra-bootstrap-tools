#!/usr/bin/env bash
# Description: Execute pre-commit checks with local Ansible collection installed.

set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "${ROOT_DIR}"

echo "Installing local Ansible collection for ansible-lint..."
make install-collection

echo "Executing pre-commit hooks across all files..."
pre-commit run --all-files
