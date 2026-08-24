#!/usr/bin/env bats

setup() {
  export MOCK_BIN_DIR="$(mktemp -d)"
  export PATH="${MOCK_BIN_DIR}:${PATH}"

  export GITHUB_STEP_SUMMARY="$(mktemp)"

  # Create a mock for yarn
  cat << 'EOF' > "${MOCK_BIN_DIR}/yarn"
#!/usr/bin/env bash
echo "mock yarn executed"
EOF
  chmod +x "${MOCK_BIN_DIR}/yarn"
}

teardown() {
  rm -rf "${MOCK_BIN_DIR}"
  rm -f "${GITHUB_STEP_SUMMARY}"
}

@test "install-node-deps.sh runs yarn and outputs to GITHUB_STEP_SUMMARY" {
  run ./bin/ci/install-node-deps.sh

  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == "Running yarn to install Node.js dependencies..." ]]
  [[ "${lines[1]}" == "mock yarn executed" ]]

  # Check GITHUB_STEP_SUMMARY content
  run cat "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == "### :package: Node.js Dependencies Installed" ]]
  [[ "${lines[1]}" == "Dependencies were successfully installed using \`yarn\`." ]]
}

@test "install-node-deps.sh fails if yarn fails" {
  # Modify mock yarn to fail
  cat << 'EOF' > "${MOCK_BIN_DIR}/yarn"
#!/usr/bin/env bash
echo "mock yarn failing"
exit 1
EOF

  run ./bin/ci/install-node-deps.sh

  [ "$status" -eq 1 ]
  [[ "${lines[0]}" == "Running yarn to install Node.js dependencies..." ]]
  [[ "${lines[1]}" == "mock yarn failing" ]]
}
