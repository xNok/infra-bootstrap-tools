#!/usr/bin/env bats

@test "sign-docker-image.sh errors when TAGS is not set" {
  run ./bin/ci/sign-docker-image.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Error: TAGS and DIGEST environment variables must be set." ]]
}

@test "sign-docker-image.sh errors when DIGEST is not set" {
  export TAGS="some-tag"
  run ./bin/ci/sign-docker-image.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Error: TAGS and DIGEST environment variables must be set." ]]
  unset TAGS
}

@test "sign-docker-image.sh calls cosign and generates summary" {
  export TAGS="test-tag"
  export DIGEST="sha256:12345"

  # Create a dummy summary file
  export GITHUB_STEP_SUMMARY="$(mktemp)"

  # Mock cosign by placing a dummy cosign in PATH
  MOCK_DIR="$(mktemp -d)"
  cat << 'EOF' > "${MOCK_DIR}/cosign"
#!/usr/bin/env bash
echo "mock cosign called with: $@"
EOF
  chmod +x "${MOCK_DIR}/cosign"
  export PATH="${MOCK_DIR}:${PATH}"

  run ./bin/ci/sign-docker-image.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "mock cosign called with: sign --yes test-tag@sha256:12345" ]]

  # Verify summary
  run cat "$GITHUB_STEP_SUMMARY"
  [[ "$output" =~ "### :closed_lock_with_key: Docker Image Signed" ]]
  [[ "$output" =~ "**Digest**: \`sha256:12345\`" ]]
  [[ "$output" =~ "**Tags**:" ]]
  [[ "$output" =~ "- \`test-tag\`" ]]

  rm -f "$GITHUB_STEP_SUMMARY"
  rm -rf "$MOCK_DIR"
  unset TAGS
  unset DIGEST
  unset GITHUB_STEP_SUMMARY
}
