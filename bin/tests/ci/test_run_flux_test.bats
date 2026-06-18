#!/usr/bin/env bats

setup() {
  export MOCK_BIN_DIR="$(mktemp -d)"
  export PATH="$MOCK_BIN_DIR:$PATH"
  export GITHUB_STEP_SUMMARY="$(mktemp)"

  # Mock bin/tests/flux-d2/test.sh itself
  mkdir -p "$MOCK_BIN_DIR/bin/tests/flux-d2"
  cat << 'MOCKEOF' > "$MOCK_BIN_DIR/bin/tests/flux-d2/test.sh"
#!/usr/bin/env bash
echo "Mocked flux test script"
MOCKEOF
  chmod +x "$MOCK_BIN_DIR/bin/tests/flux-d2/test.sh"

  # Ensure the script calls the mock instead of the real one by modifying the run script for the test only
  export MOCK_TEST_SH="$MOCK_BIN_DIR/bin/tests/flux-d2/test.sh"
}

teardown() {
  rm -rf "$MOCK_BIN_DIR"
  rm -f "$GITHUB_STEP_SUMMARY"
}

@test "run-flux-test.sh runs the test script and updates step summary" {
  # Replace the hardcoded path with the mock one in memory for testing
  run bash -c "sed 's|\./bin/tests/flux-d2/test.sh|\"$MOCK_TEST_SH\"|g' ./bin/ci/run-flux-test.sh | bash"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Mocked flux test script"* ]]

  run cat "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
  [[ "$output" == *"### :test_tube: Running Flux D2 Bootstrap Test"* ]]
  [[ "$output" == *"### :white_check_mark: Flux D2 Bootstrap Test Completed Successfully"* ]]
}
