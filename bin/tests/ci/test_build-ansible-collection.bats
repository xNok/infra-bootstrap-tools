#!/usr/bin/env bats

setup() {
  export GITHUB_STEP_SUMMARY="$(mktemp)"
  export GITHUB_OUTPUT="$(mktemp)"

  export MOCK_BIN_DIR="$(mktemp -d)"
  export PATH="${MOCK_BIN_DIR}:${PATH}"

  # Mock ansible-galaxy
  cat << 'EOF' > "${MOCK_BIN_DIR}/ansible-galaxy"
#!/usr/bin/env bash
if [ "$1" = "collection" ] && [ "$2" = "build" ]; then
  echo "Created collection file my_namespace-my_collection-1.0.0.tar.gz"
fi
EOF
  chmod +x "${MOCK_BIN_DIR}/ansible-galaxy"
}

teardown() {
  rm -f "$GITHUB_STEP_SUMMARY"
  rm -f "$GITHUB_OUTPUT"
  rm -rf "$MOCK_BIN_DIR"
}

@test "build-ansible-collection.sh builds collection and extracts tarball name" {
  export COLLECTION_DIR="mock_dir"

  run ./bin/ci/build-ansible-collection.sh

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "Created tarball: my_namespace-my_collection-1.0.0.tar.gz" ]

  run grep "TARBALL=my_namespace-my_collection-1.0.0.tar.gz" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]

  run grep "Tarball: \`my_namespace-my_collection-1.0.0.tar.gz\`" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
}
