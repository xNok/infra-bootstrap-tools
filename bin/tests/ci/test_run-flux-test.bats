#!/usr/bin/env bats

setup() {
  export GITHUB_STEP_SUMMARY="$(mktemp)"
  export MOCK_DIR="$(mktemp -d)"
  export MOCK_BIN_DIR="${MOCK_DIR}/bin"
  export MOCK_TEST_DIR="${MOCK_DIR}/bin/tests/flux-d2"

  mkdir -p "$MOCK_BIN_DIR"
  mkdir -p "$MOCK_TEST_DIR"

  export SCRIPT_TO_TEST="${BATS_TEST_DIRNAME}/../../ci/run-flux-test.sh"
  export ROOT_DIR="$MOCK_DIR"

  export TEST_SCRIPT="${MOCK_DIR}/run-flux-test.sh"
  cp "$SCRIPT_TO_TEST" "$TEST_SCRIPT"
}

teardown() {
  rm -f "$GITHUB_STEP_SUMMARY"
  rm -rf "$MOCK_DIR"
}

@test "run-flux-test.sh succeeds and generates summary on success" {
  cat << 'EOF' > "${MOCK_TEST_DIR}/test.sh"
#!/usr/bin/env bash
echo "Mock Flux Test Script Execution: SUCCESS"
exit 0
EOF
  chmod +x "${MOCK_TEST_DIR}/test.sh"

  run "$TEST_SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Mock Flux Test Script Execution: SUCCESS"* ]]

  # Check summary
  cat "$GITHUB_STEP_SUMMARY"
  summary_content=$(cat "$GITHUB_STEP_SUMMARY")
  [[ "$summary_content" == *"## Flux D2 Bootstrap Test Results"* ]]
  [[ "$summary_content" == *"✅ **Status:** Passed"* ]]
  [[ "$summary_content" == *"Mock Flux Test Script Execution: SUCCESS"* ]]
}

@test "run-flux-test.sh fails and generates summary on failure" {
  cat << 'EOF' > "${MOCK_TEST_DIR}/test.sh"
#!/usr/bin/env bash
echo "Mock Flux Test Script Execution: FAILURE"
exit 1
EOF
  chmod +x "${MOCK_TEST_DIR}/test.sh"

  run "$TEST_SCRIPT"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Mock Flux Test Script Execution: FAILURE"* ]]

  # Check summary
  summary_content=$(cat "$GITHUB_STEP_SUMMARY")
  [[ "$summary_content" == *"## Flux D2 Bootstrap Test Results"* ]]
  [[ "$summary_content" == *"❌ **Status:** Failed"* ]]
  [[ "$summary_content" == *"Mock Flux Test Script Execution: FAILURE"* ]]
}
