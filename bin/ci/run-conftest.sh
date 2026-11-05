#!/usr/bin/env bash
# Description: Wrapper script to execute conftest against GitHub Actions workflows.

set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
WORKFLOWS_DIR="${ROOT_DIR}/.github/workflows"
POLICIES_DIR="${ROOT_DIR}/policies/ci"

OUTPUT_FILE=$(mktemp)

trap 'rm -f "${OUTPUT_FILE}"' EXIT

echo "Running conftest for GitHub Actions workflows..."
set +e
conftest test "${WORKFLOWS_DIR}"/*.yml -p "${POLICIES_DIR}" --all-namespaces --output tap >> "${OUTPUT_FILE}" 2>&1
WORKFLOW_EXIT_CODE=$?

K8S_EXIT_CODE=0
if [ -d "${ROOT_DIR}/kubernetes/infra-addons" ] && [ -d "${ROOT_DIR}/policies/kubernetes" ]; then
  echo "Running conftest for Kubernetes infra-addons..."
  kubectl kustomize "${ROOT_DIR}/kubernetes/infra-addons" | conftest test - -p "${ROOT_DIR}/policies/kubernetes" --data "${ROOT_DIR}/kubernetes/infra-addons/policy-exceptions.yaml" --all-namespaces --output tap >> "${OUTPUT_FILE}" 2>&1
  K8S_EXIT_CODE=$?
fi

if [ ${WORKFLOW_EXIT_CODE} -ne 0 ] || [ ${K8S_EXIT_CODE} -ne 0 ]; then
  EXIT_CODE=1
else
  EXIT_CODE=0
fi
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
