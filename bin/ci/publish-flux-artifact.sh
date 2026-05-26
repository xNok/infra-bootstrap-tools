#!/usr/bin/env bash

set -euo pipefail

# This script is used by GitHub Actions to publish and tag Flux OCI artifacts.
# Usage: ./bin/ci/publish-flux-artifact.sh <repository_owner> <artifact_path> <source_url> <artifact_name>
#
# Arguments:
#   repository_owner: The GitHub repository owner (e.g., github.repository_owner)
#   artifact_path: The local path to the artifact manifests (e.g., ./kubernetes/fleet/kind)
#   source_url: The source URL of the repository (e.g., github.event.repository.html_url)
#   artifact_name: The name of the artifact to publish (e.g., fleet/kind or infra-addons)

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <repository_owner> <artifact_path> <source_url> <artifact_name>"
  exit 1
fi

OWNER="$1"
ARTIFACT_PATH="$2"
SOURCE_URL="$3"
ARTIFACT_NAME="$4"

# Ensure owner is lowercase for Docker registry compatibility
OWNER_LC=$(echo "$OWNER" | tr '[:upper:]' '[:lower:]')

OCI_REPO="oci://ghcr.io/$OWNER_LC/manifests/kubernetes/$ARTIFACT_NAME"

SHORT_SHA=$(git rev-parse --short HEAD)
HEAD_SHA=$(git rev-parse HEAD)

echo "Publishing Flux artifact to $OCI_REPO:$SHORT_SHA..."

# Push the artifact
flux push artifact "$OCI_REPO:$SHORT_SHA" \
    --path="$ARTIFACT_PATH" \
    --source="$SOURCE_URL" \
    --revision="$HEAD_SHA"

# Tag the artifact as latest
flux tag artifact "$OCI_REPO:$SHORT_SHA" --tag latest

# Output summary to GitHub step summary if running in CI
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :rocket: Flux Artifact Published" >> "$GITHUB_STEP_SUMMARY"
  echo "**Artifact Name**: \`$ARTIFACT_NAME\`" >> "$GITHUB_STEP_SUMMARY"
  echo "**OCI Repository**: \`$OCI_REPO\`" >> "$GITHUB_STEP_SUMMARY"
  echo "**Revision**: \`$SHORT_SHA\`" >> "$GITHUB_STEP_SUMMARY"
  echo "**Source Path**: \`$ARTIFACT_PATH\`" >> "$GITHUB_STEP_SUMMARY"
fi
