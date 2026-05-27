#!/usr/bin/env bash

set -euo pipefail

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

BUNDLE_FULL_NAME="${RELEASE_TAG%@*}"
VERSION="${RELEASE_TAG#*@}"
BUNDLE_NAME="${BUNDLE_FULL_NAME#kubernetes-}"
SHORT_SHA=$(git rev-parse --short HEAD)
HEAD_SHA=$(git rev-parse HEAD)

echo "Publishing Kubernetes artifact $BUNDLE_NAME to $OCI_REPO..."

flux push artifact "$OCI_REPO/$BUNDLE_NAME:$SHORT_SHA" \
    --path="./$PACKAGE_DIR/$BUNDLE_NAME" \
    --source="$SOURCE_URL" \
    --revision="$HEAD_SHA"

flux tag artifact "$OCI_REPO/$BUNDLE_NAME:$SHORT_SHA" --tag latest --tag "$VERSION"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### :rocket: Kubernetes Artifact Published" >> "$GITHUB_STEP_SUMMARY"
  echo "**Artifact Name**: \`$BUNDLE_NAME\`" >> "$GITHUB_STEP_SUMMARY"
  echo "**Version**: \`$VERSION\`" >> "$GITHUB_STEP_SUMMARY"
  echo "**OCI Repository**: \`$OCI_REPO/$BUNDLE_NAME\`" >> "$GITHUB_STEP_SUMMARY"
  echo "**Revision**: \`$SHORT_SHA\`" >> "$GITHUB_STEP_SUMMARY"
  echo "**Source Path**: \`./$PACKAGE_DIR/$BUNDLE_NAME\`" >> "$GITHUB_STEP_SUMMARY"
fi
