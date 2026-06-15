#!/usr/bin/env bats

setup() {
  export MOCK_DIR="$(mktemp -d)"

  # Mock GITHUB_STEP_SUMMARY
  export GITHUB_STEP_SUMMARY="$(mktemp)"

  # Mock bin/tests/flux-d2/test.sh inside the test workspace to avoid running actual integration tests
  export WORKSPACE_DIR="$MOCK_DIR/workspace"
  mkdir -p "$WORKSPACE_DIR/bin/tests/flux-d2"

  cat << 'SCRIPT' > "$WORKSPACE_DIR/bin/tests/flux-d2/test.sh"
#!/usr/bin/env bash
echo "Mock flux-d2/test.sh executed successfully."
exit 0
SCRIPT
  chmod +x "$WORKSPACE_DIR/bin/tests/flux-d2/test.sh"

  # Copy the script to test into the workspace
  mkdir -p "$WORKSPACE_DIR/bin/ci"
  cp "bin/ci/flux-test.sh" "$WORKSPACE_DIR/bin/ci/flux-test.sh"
}

teardown() {
  rm -rf "$MOCK_DIR"
  rm -f "$GITHUB_STEP_SUMMARY"
}

@test "flux-test.sh writes to GITHUB_STEP_SUMMARY if available and executes the underlying script" {
  cd "$WORKSPACE_DIR"

  run ./bin/ci/flux-test.sh

  [ "$status" -eq 0 ]
  [[ "$output" == *"Mock flux-d2/test.sh executed successfully."* ]]

  # Check if GITHUB_STEP_SUMMARY was populated
  summary_content=$(cat "$GITHUB_STEP_SUMMARY")
  [[ "$summary_content" == *"### Flux D2 Integration Test"* ]]
  [[ "$summary_content" == *"Running the flux bootstrap test script..."* ]]
}

@test "flux-test.sh works if GITHUB_STEP_SUMMARY is not set" {
  cd "$WORKSPACE_DIR"

  unset GITHUB_STEP_SUMMARY

  run ./bin/ci/flux-test.sh

  [ "$status" -eq 0 ]
  [[ "$output" == *"Mock flux-d2/test.sh executed successfully."* ]]
}
