#!/usr/bin/env bats

setup() {
  export GITHUB_STEP_SUMMARY="$(mktemp)"
  export MOCK_DIR="$(mktemp -d)"

  # Create a mock success script
  export MOCK_SUCCESS_SCRIPT="${MOCK_DIR}/mock-success.sh"
  cat << 'EOF' > "$MOCK_SUCCESS_SCRIPT"
#!/usr/bin/env bash
echo "Mock successful test"
exit 0
EOF
  chmod +x "$MOCK_SUCCESS_SCRIPT"

  # Create a mock failure script
  export MOCK_FAILURE_SCRIPT="${MOCK_DIR}/mock-failure.sh"
  cat << 'EOF' > "$MOCK_FAILURE_SCRIPT"
#!/usr/bin/env bash
echo "Mock failing test"
exit 1
EOF
  chmod +x "$MOCK_FAILURE_SCRIPT"
}

teardown() {
  rm -f "$GITHUB_STEP_SUMMARY"
  rm -f test-results.log
  rm -rf "$MOCK_DIR"
}

@test "run-flux-test.sh captures successful exit code and writes success summary" {
  export FLUX_TEST_SCRIPT="$MOCK_SUCCESS_SCRIPT"
  run ./bin/ci/run-flux-test.sh

  [ "$status" -eq 0 ]

  run grep "### :white_check_mark: Flux Bootstrap Test Succeeded" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]

  run grep "Mock successful test" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
}

@test "run-flux-test.sh captures failing exit code and writes failure summary" {
  export FLUX_TEST_SCRIPT="$MOCK_FAILURE_SCRIPT"
  run ./bin/ci/run-flux-test.sh

  [ "$status" -eq 1 ]

  run grep "### :x: Flux Bootstrap Test Failed" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]

  run grep "Mock failing test" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
}
