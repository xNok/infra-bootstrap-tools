#!/usr/bin/env bash
set -euo pipefail
EVENT_NAME="$1"
INPUT_TAG="$2"
RELEASE_TAG="$3"
if [ "$EVENT_NAME" == "workflow_dispatch" ] || [ "$EVENT_NAME" == "workflow_call" ]; then
  ./bin/ci/extract-version-from-tag.sh "$EVENT_NAME" "$INPUT_TAG"
else
  ./bin/ci/extract-version-from-tag.sh "$EVENT_NAME" "$RELEASE_TAG"
fi
