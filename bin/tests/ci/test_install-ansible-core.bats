#!/usr/bin/env bats

setup() {
  export GITHUB_STEP_SUMMARY="$(mktemp)"
  export MOCK_BIN_DIR="$(mktemp -d)"
  export PATH="${MOCK_BIN_DIR}:${PATH}"

  # Mock pip
  cat << 'EOF' > "${MOCK_BIN_DIR}/pip"
#!/usr/bin/env bash
if [ "$1" = "install" ] && [ "$2" = "ansible-core" ]; then
  echo "Successfully installed ansible-core"
elif [ "$1" = "show" ] && [ "$2" = "ansible-core" ]; then
  echo "Name: ansible-core"
  echo "Version: 2.15.3"
  echo "Summary: Radically simple IT automation"
else
  echo "mock pip $@"
fi
EOF
  chmod +x "${MOCK_BIN_DIR}/pip"
}

teardown() {
  rm -f "$GITHUB_STEP_SUMMARY"
  rm -rf "$MOCK_BIN_DIR"
}

@test "install-ansible-core.sh installs and reports version" {
  run ./bin/ci/lib/install-ansible-core.sh

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "Successfully installed ansible-core" ]

  run grep "### :hammer_and_wrench: Installed ansible-core" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]

  run grep "ansible-core version: 2.15.3" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
}
