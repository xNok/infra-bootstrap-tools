#!/usr/bin/env bats

setup() {
  export MOCK_DIR="$(mktemp -d)"
  export PATH="${MOCK_DIR}:$PATH"
  export GITHUB_STEP_SUMMARY="$(mktemp)"

  # Create mock collection dir and galaxy.yml
  export MOCK_COLLECTION_DIR="${MOCK_DIR}/ansible"
  mkdir -p "$MOCK_COLLECTION_DIR"
  echo "version: \"0.0.0\"" > "$MOCK_COLLECTION_DIR/galaxy.yml"

  # Mock yq
  cat << 'EOF' > "${MOCK_DIR}/yq"
#!/usr/bin/env bash
if [[ "$1" == "-i" ]]; then
  shift
  # naive mock: replace version
  sed -i "s/version: .*/version: \"${VERSION}\"/" "$2"
fi
EOF
  chmod +x "${MOCK_DIR}/yq"
}

teardown() {
  rm -rf "$MOCK_DIR"
  rm -f "$GITHUB_STEP_SUMMARY"
}

@test "update-galaxy-version sets correct version" {
  export VERSION="1.2.3"

  run ./bin/ci/update-galaxy-version.sh "$MOCK_COLLECTION_DIR"

  [ "$status" -eq 0 ]

  # Check if galaxy.yml was updated
  grep 'version: "1.2.3"' "$MOCK_COLLECTION_DIR/galaxy.yml"

  # Check if github summary was generated
  grep "Updated Ansible Galaxy Version" "$GITHUB_STEP_SUMMARY"
}

@test "update-galaxy-version fails when VERSION is not set" {
  unset VERSION

  run ./bin/ci/update-galaxy-version.sh "$MOCK_COLLECTION_DIR"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "VERSION environment variable is required" ]]
}

@test "update-galaxy-version fails when galaxy.yml is missing" {
  export VERSION="1.2.3"
  rm "$MOCK_COLLECTION_DIR/galaxy.yml"

  run ./bin/ci/update-galaxy-version.sh "$MOCK_COLLECTION_DIR"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "galaxy.yml does not exist" ]]
}
