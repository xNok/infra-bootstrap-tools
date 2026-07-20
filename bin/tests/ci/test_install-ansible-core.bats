#!/usr/bin/env bats

setup() {
  export GITHUB_STEP_SUMMARY="$(mktemp)"
  export MOCK_BIN_DIR="$(mktemp -d)"
  export PATH="${MOCK_BIN_DIR}:${PATH}"

  cat << 'EOF' > "${MOCK_BIN_DIR}/python"
#!/usr/bin/env bash
echo "Mock python $@"
EOF
  chmod +x "${MOCK_BIN_DIR}/python"

  cat << 'EOF' > "${MOCK_BIN_DIR}/pip"
#!/usr/bin/env bash
echo "Mock pip $@"
EOF
  chmod +x "${MOCK_BIN_DIR}/pip"
}

teardown() {
  rm -f "$GITHUB_STEP_SUMMARY"
  rm -rf "$MOCK_BIN_DIR"
}

@test "install-ansible-core.sh installs dependencies and writes summary" {
  run ./bin/ci/install-ansible-core.sh

  [ "$status" -eq 0 ]
  grep -q "### :package: Installed Ansible Dependencies" "$GITHUB_STEP_SUMMARY"
  grep -q "Installed \`ansible-core\`" "$GITHUB_STEP_SUMMARY"
}
