#!/usr/bin/env bash
set -e

# Define root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${ROOT_DIR:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
CONFTEST_VERSION="0.69.0"
CONFTEST_TAR="conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz"

echo "Checking for conftest..."
if ! command -v conftest &> /dev/null; then
    echo "conftest not found. Installing locally..."
    TMP_DIR=$(mktemp -d)
    wget -q "https://github.com/open-policy-agent/conftest/releases/download/v${CONFTEST_VERSION}/${CONFTEST_TAR}" -O "${TMP_DIR}/${CONFTEST_TAR}"
    tar xzf "${TMP_DIR}/${CONFTEST_TAR}" -C "${TMP_DIR}"

    # Use the local executable for this run
    CONFTEST_BIN="${TMP_DIR}/conftest"
else
    CONFTEST_BIN="conftest"
fi

echo "Running conftest..."
cd "${ROOT_DIR}"

LOG_FILE=$(mktemp)
set +e
"${CONFTEST_BIN}" test .github/workflows/*.yml -p policies/ci/ > "${LOG_FILE}" 2>&1
EXIT_CODE=$?
set -e

cat "${LOG_FILE}"

if [[ -n "${GITHUB_STEP_SUMMARY}" ]]; then
    {
        echo "### Conftest Policy Validation Results"
        if [[ $EXIT_CODE -eq 0 ]]; then
            echo "✅ All policies passed successfully!"
        else
            echo "❌ Policy violations detected:"
        fi
        echo "<details><summary>Test Details</summary>"
        echo ""
        echo '```text'
        cat "${LOG_FILE}"
        echo '```'
        echo ""
        echo "</details>"
    } >> "${GITHUB_STEP_SUMMARY}"
fi

# Generate Documentation
echo "Generating policy documentation..."
"${CONFTEST_BIN}" doc policies/ci/ > policies/POLICIES_REFERENCE.md

rm -f "${LOG_FILE}"
if [[ -n "${TMP_DIR:-}" && -d "${TMP_DIR}" ]]; then
    rm -rf "${TMP_DIR}"
fi

(return $EXIT_CODE 2>/dev/null) || command exit $EXIT_CODE
