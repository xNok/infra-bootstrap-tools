#!/usr/bin/env bats

setup() {
  export GITHUB_STEP_SUMMARY="$(mktemp)"
  export MOCK_BIN_DIR="$(mktemp -d)"
  export PATH="${MOCK_BIN_DIR}:${PATH}"

  cat << 'EOF' > "${MOCK_BIN_DIR}/yq"
#!/usr/bin/env bash
echo "Mock yq $@"
EOF
  chmod +x "${MOCK_BIN_DIR}/yq"
}

teardown() {
  rm -f "$GITHUB_STEP_SUMMARY"
  rm -rf "$MOCK_BIN_DIR"
}

@test "update-collection-version.sh updates version and writes summary" {
  run ./bin/ci/update-collection-version.sh "1.0.0" "ansible"

  [ "$status" -eq 0 ]
  grep -q "### :pencil: Updated Collection Version" "$GITHUB_STEP_SUMMARY"
  grep -q "Updated \`ansible/galaxy.yml\` to version \`1.0.0\`" "$GITHUB_STEP_SUMMARY"
}
