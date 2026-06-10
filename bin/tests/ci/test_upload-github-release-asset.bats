#!/usr/bin/env bats

setup() {
  export GITHUB_STEP_SUMMARY="$(mktemp)"

  export MOCK_BIN_DIR="$(mktemp -d)"
  export PATH="${MOCK_BIN_DIR}:${PATH}"

  export ASSET_PATH="mock-asset.tar.gz"
}

teardown() {
  rm -f "$GITHUB_STEP_SUMMARY"
  rm -rf "$MOCK_BIN_DIR"
}

@test "upload-github-release-asset.sh uploads when release exists" {
  export EVENT_NAME="push"
  export GITHUB_REF_NAME="v1.0.0"

  # Mock gh to succeed for view and upload
  cat << 'EOF' > "${MOCK_BIN_DIR}/gh"
#!/usr/bin/env bash
if [ "$1" = "release" ] && [ "$2" = "view" ]; then
  exit 0
elif [ "$1" = "release" ] && [ "$2" = "upload" ]; then
  exit 0
fi
EOF
  chmod +x "${MOCK_BIN_DIR}/gh"

  run ./bin/ci/lib/upload-github-release-asset.sh

  [ "$status" -eq 0 ]
  run grep "### :rocket: Uploaded to GitHub Release" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
}

@test "upload-github-release-asset.sh skips when release does not exist" {
  export EVENT_NAME="push"
  export GITHUB_REF_NAME="v1.0.0"

  # Mock gh to fail for view
  cat << 'EOF' > "${MOCK_BIN_DIR}/gh"
#!/usr/bin/env bash
if [ "$1" = "release" ] && [ "$2" = "view" ]; then
  exit 1
fi
EOF
  chmod +x "${MOCK_BIN_DIR}/gh"

  run ./bin/ci/lib/upload-github-release-asset.sh

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "No GitHub Release found for tag v1.0.0, skipping upload" ]

  run grep "### :warning: Release not found" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
}
