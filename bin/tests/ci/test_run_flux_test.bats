#!/usr/bin/env bats

setup() {
  export TEST_TEMP_DIR="$(mktemp -d)"
  export MOCK_BIN_DIR="$TEST_TEMP_DIR/bin"
  mkdir -p "$MOCK_BIN_DIR"
  export PATH="$MOCK_BIN_DIR:$PATH"

  export GITHUB_STEP_SUMMARY="$TEST_TEMP_DIR/step_summary.md"

  # Create a mock for bin/tests/flux-d2/test.sh
  export MOCK_FLUX_TEST_DIR="$TEST_TEMP_DIR/mock_root/bin/tests/flux-d2"
  mkdir -p "$MOCK_FLUX_TEST_DIR"
  cat << 'MOCK_EOF' > "$MOCK_FLUX_TEST_DIR/test.sh"
#!/usr/bin/env bash
if [ "${MOCK_FLUX_TEST_EXIT:-0}" -eq 0 ]; then
  echo "Mock Flux Test Success"
  exit 0
else
  echo "Mock Flux Test Failure"
  exit 1
fi
MOCK_EOF
  chmod +x "$MOCK_FLUX_TEST_DIR/test.sh"

  # We need to temporarily replace the ROOT_DIR in run-flux-test.sh to our mock root
  export ORIGINAL_SCRIPT="$BATS_TEST_DIRNAME/../../ci/run-flux-test.sh"
  export MOCK_SCRIPT="$TEST_TEMP_DIR/run-flux-test.sh"

  # Replace ROOT_DIR definition
  sed "s|ROOT_DIR=.*|ROOT_DIR=\"$TEST_TEMP_DIR/mock_root\"|" "$ORIGINAL_SCRIPT" > "$MOCK_SCRIPT"
  chmod +x "$MOCK_SCRIPT"
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

@test "run-flux-test.sh executes successfully and updates step summary" {
  export MOCK_FLUX_TEST_EXIT=0

  run "$MOCK_SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Starting Flux D2 integration test..."* ]]
  [[ "$output" == *"Mock Flux Test Success"* ]]

  [ -f "$GITHUB_STEP_SUMMARY" ]
  run cat "$GITHUB_STEP_SUMMARY"
  [[ "$output" == *"### :test_tube: Flux Bootstrap Test Results"* ]]
  [[ "$output" == *"✅ **Status**: Success"* ]]
  [[ "$output" == *"The Flux D2 bootstrap test completed successfully!"* ]]
}

@test "run-flux-test.sh handles failure and updates step summary" {
  export MOCK_FLUX_TEST_EXIT=1

  run "$MOCK_SCRIPT"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Starting Flux D2 integration test..."* ]]
  [[ "$output" == *"Mock Flux Test Failure"* ]]

  [ -f "$GITHUB_STEP_SUMMARY" ]
  run cat "$GITHUB_STEP_SUMMARY"
  [[ "$output" == *"### :test_tube: Flux Bootstrap Test Results"* ]]
  [[ "$output" == *"❌ **Status**: Failed"* ]]
  [[ "$output" == *"The Flux D2 bootstrap test failed with exit code \`1\`."* ]]
}
