#!/usr/bin/env bats

setup() {
  export MOCK_DIR="$(mktemp -d)"
  export GITHUB_STEP_SUMMARY="$(mktemp)"
  export ROOT_DIR="$MOCK_DIR"

  # Create mock target directory
  mkdir -p "${ROOT_DIR}/bin/tests/flux-d2"
}

teardown() {
  rm -rf "$MOCK_DIR"
  rm -f "$GITHUB_STEP_SUMMARY"
}

@test "run-flux-test.sh completes successfully and writes success to summary" {
  # Mock the inner script to succeed
  cat << 'EOF' > "${ROOT_DIR}/bin/tests/flux-d2/test.sh"
#!/usr/bin/env bash
echo "Mock success"
exit 0
EOF
  chmod +x "${ROOT_DIR}/bin/tests/flux-d2/test.sh"

  run ./bin/ci/run-flux-test.sh

  [ "$status" -eq 0 ]
  [[ "$output" == *"Mock success"* ]]

  # Verify summary
  run cat "$GITHUB_STEP_SUMMARY"
  [[ "$output" == *"### :white_check_mark: Flux D2 tests completed successfully"* ]]
  [[ "$output" == *"Mock success"* ]]
}

@test "run-flux-test.sh fails and writes error to summary" {
  # Mock the inner script to fail
  cat << 'EOF' > "${ROOT_DIR}/bin/tests/flux-d2/test.sh"
#!/usr/bin/env bash
echo "Mock failure"
exit 1
EOF
  chmod +x "${ROOT_DIR}/bin/tests/flux-d2/test.sh"

  run ./bin/ci/run-flux-test.sh

  [ "$status" -eq 1 ]
  [[ "$output" == *"Mock failure"* ]]

  # Verify summary
  run cat "$GITHUB_STEP_SUMMARY"
  [[ "$output" == *"### :x: Flux D2 tests failed"* ]]
  [[ "$output" == *"Mock failure"* ]]
}
