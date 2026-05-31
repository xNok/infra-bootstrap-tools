#!/usr/bin/env bash

set -euo pipefail

# This script is used by GitHub Actions to publish and tag Kubernetes components using Flux.
# Usage: ./bin/ci/publish-kubernetes-release.sh <repository_owner> <release_tag> <package_dir> <source_url>
#
# Arguments:
#   repository_owner: The GitHub repository owner (e.g., github.repository_owner)
#   release_tag: The tag that triggered the release (e.g., kubernetes-infra-addons@1.0.0)
#   package_dir: The directory of the package (e.g., kubernetes)
#   source_url: The source URL of the repository (e.g., github.event.repository.html_url)

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <repository_owner> <release_tag> <package_dir> <source_url>"
  exit 1
fi

OWNER="$1"
RELEASE_TAG="$2"
PACKAGE_DIR="$3"
SOURCE_URL="$4"

OWNER_LC=$(echo "$OWNER" | tr '[:upper:]' '[:lower:]')
OCI_REPO="oci://ghcr.io/$OWNER_LC/manifests/kubernetes"

# The tag provides the version, e.g., kubernetes-infra-addons@1.0.0
BUNDLE_FULL_NAME="${RELEASE_TAG%@*}"
VERSION="${RELEASE_TAG#*@}"

# Remove 'kubernetes-' prefix
BUNDLE_NAME="${BUNDLE_FULL_NAME#kubernetes-}"

SHORT_SHA=$(git rev-parse --short HEAD)
HEAD_SHA=$(git rev-parse HEAD)

echo "Publishing Flux artifact to $OCI_REPO/$BUNDLE_NAME:$SHORT_SHA..."

# Publish
flux push artifact "$OCI_REPO/$BUNDLE_NAME:$SHORT_SHA" \
    --path="./${PACKAGE_DIR}/$BUNDLE_NAME" \
    --source="$SOURCE_URL" \
    --revision="$HEAD_SHA"

# Tag with version from the git tag and latest
flux tag artifact "$OCI_REPO/$BUNDLE_NAME:$SHORT_SHA" --tag latest --tag "$VERSION"

# Output summary to GitHub step summary if running in CI
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :rocket: Kubernetes Component Published" >> "$GITHUB_STEP_SUMMARY"
  echo "**Component Name**: \`$BUNDLE_NAME\`" >> "$GITHUB_STEP_SUMMARY"
  echo "**Version**: \`$VERSION\`" >> "$GITHUB_STEP_SUMMARY"
  echo "**OCI Repository**: \`$OCI_REPO/$BUNDLE_NAME\`" >> "$GITHUB_STEP_SUMMARY"
  echo "**Revision**: \`$SHORT_SHA\`" >> "$GITHUB_STEP_SUMMARY"
fi
