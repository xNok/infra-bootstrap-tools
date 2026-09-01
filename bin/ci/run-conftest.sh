#!/bin/bash
# Description: Wrapper script to install and execute conftest against GitHub Actions workflows.

set -euo pipefail

CONFTEST_VERSION="v0.69.0"
CONFTEST_OS="Linux"
CONFTEST_ARCH="x86_64"
CONFTEST_TAR="conftest_${CONFTEST_VERSION#v}_${CONFTEST_OS}_${CONFTEST_ARCH}.tar.gz"
CONFTEST_URL="https://github.com/open-policy-agent/conftest/releases/download/${CONFTEST_VERSION}/${CONFTEST_TAR}"

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
WORKFLOWS_DIR="${ROOT_DIR}/.github/workflows"
POLICIES_DIR="${ROOT_DIR}/policies/ci"

# Download and extract conftest in a temporary directory
TEMP_DIR=$(mktemp -d)
OUTPUT_FILE=$(mktemp)

trap 'rm -rf "${TEMP_DIR}" "${OUTPUT_FILE}"' EXIT

echo "Downloading conftest ${CONFTEST_VERSION}..."
wget -q "${CONFTEST_URL}" -O "${TEMP_DIR}/${CONFTEST_TAR}"
tar -xzf "${TEMP_DIR}/${CONFTEST_TAR}" -C "${TEMP_DIR}"

CONFTEST_BIN="${TEMP_DIR}/conftest"

echo "Running conftest..."
set +e
"${CONFTEST_BIN}" test "${WORKFLOWS_DIR}"/*.yml -p "${POLICIES_DIR}" --all-namespaces --output tap > "${OUTPUT_FILE}" 2>&1
EXIT_CODE=$?
set -e

# Output the results to the console
cat "${OUTPUT_FILE}"

# If running in GitHub Actions, append the results to the step summary
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  echo "### Conftest Results" >> "$GITHUB_STEP_SUMMARY"
  echo "<details><summary>Click to expand</summary>" >> "$GITHUB_STEP_SUMMARY"
  echo "" >> "$GITHUB_STEP_SUMMARY"
  echo '```tap' >> "$GITHUB_STEP_SUMMARY"
  cat "${OUTPUT_FILE}" >> "$GITHUB_STEP_SUMMARY"
  echo '```' >> "$GITHUB_STEP_SUMMARY"
  echo "</details>" >> "$GITHUB_STEP_SUMMARY"
fi

exit ${EXIT_CODE}
