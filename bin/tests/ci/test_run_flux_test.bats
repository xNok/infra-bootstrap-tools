#!/usr/bin/env bats

setup() {
  export GITHUB_STEP_SUMMARY="$(mktemp)"
  export MOCK_BIN_DIR="$(mktemp -d)"
  export PATH="$MOCK_BIN_DIR:$PATH"

  # Create a full mock workspace
  export MOCK_WORKSPACE="$(mktemp -d)"
  cd "$MOCK_WORKSPACE"

  mkdir -p bin/ci/lib
  cp "$BATS_TEST_DIRNAME/../../ci/run-flux-test.sh" bin/ci/
  cp "$BATS_TEST_DIRNAME/../../ci/lib/step-summary.sh" bin/ci/lib/

  mkdir -p bin/tests/flux-d2
  cat << 'MOCK' > bin/tests/flux-d2/test.sh
#!/bin/bash
echo "Mock flux test script called"
MOCK
  chmod +x bin/tests/flux-d2/test.sh
}

teardown() {
  rm -f "$GITHUB_STEP_SUMMARY"
  rm -rf "$MOCK_BIN_DIR"
  rm -rf "$MOCK_WORKSPACE"
}

@test "run-flux-test.sh calls flux test script and writes to summary" {
  run ./bin/ci/run-flux-test.sh
  [ "$status" -eq 0 ]

  # Check if output contains mock calls
  [[ "${lines[0]}" == "Mock flux test script called" ]]

  # Check if summary was written
  grep "Flux D2 bootstrap test completed successfully" "$GITHUB_STEP_SUMMARY"
}
