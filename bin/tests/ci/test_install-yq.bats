#!/usr/bin/env bats

setup() {
  export GITHUB_STEP_SUMMARY="$(mktemp)"

  # Create mock bin dir
  export MOCK_BIN_DIR="$(mktemp -d)"
  export PATH="${MOCK_BIN_DIR}:${PATH}"

  # Mock sudo to avoid requiring root for tests
  cat << 'EOF' > "${MOCK_BIN_DIR}/sudo"
#!/usr/bin/env bash
# Just run the command
"$@"
EOF
  chmod +x "${MOCK_BIN_DIR}/sudo"

  # Mock wget
  cat << 'EOF' > "${MOCK_BIN_DIR}/wget"
#!/usr/bin/env bash
echo "mock wget called" >&2
# Note: we are trying to output to /usr/local/bin/yq, but we don't have permission.
# We don't actually need to create the file because we also mock chmod and yq.
# So just do nothing.
EOF
  chmod +x "${MOCK_BIN_DIR}/wget"

  # Set up a fake /usr/local/bin/yq so chmod doesn't fail
  # Note: The script installs to /usr/local/bin/yq. We need to mock that location or mock chmod too.
  # Let's mock chmod so it doesn't fail if we don't have root
  cat << 'EOF' > "${MOCK_BIN_DIR}/chmod"
#!/usr/bin/env bash
echo "mock chmod called" >&2
EOF
  chmod +x "${MOCK_BIN_DIR}/chmod"

  # Mock yq for the version check
  cat << 'EOF' > "${MOCK_BIN_DIR}/yq"
#!/usr/bin/env bash
echo "yq (https://github.com/mikefarah/yq/) version 4.44.3"
EOF
  chmod +x "${MOCK_BIN_DIR}/yq"
}

teardown() {
  rm -f "$GITHUB_STEP_SUMMARY"
  rm -rf "$MOCK_BIN_DIR"
}

@test "install-yq.sh downloads yq, sets executable, and writes to summary" {
  run ./bin/ci/lib/install-yq.sh

  [ "$status" -eq 0 ]

  # Check that summary was written
  run grep "### :hammer_and_wrench: Installed yq" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]

  run grep "yq version: yq (https://github.com/mikefarah/yq/) version 4.44.3" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
}
