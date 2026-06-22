#!/usr/bin/env bats

setup() {
  export MOCK_DIR="$(mktemp -d)"
  export MOCK_BIN_DIR="${MOCK_DIR}/bin"
  mkdir -p "${MOCK_BIN_DIR}"
  export PATH="${MOCK_BIN_DIR}:$PATH"

  export GITHUB_STEP_SUMMARY="$(mktemp)"

  # Mock bin/tests/flux-d2/test.sh
  export MOCK_FLUX_TEST_DIR="${MOCK_DIR}/bin/tests/flux-d2"
  mkdir -p "${MOCK_FLUX_TEST_DIR}"
  export MOCK_FLUX_TEST_SCRIPT="${MOCK_FLUX_TEST_DIR}/test.sh"

  # Keep a real bin directory structure but inside MOCK_DIR for testing?
  # No, the script uses ROOT_DIR to call bin/tests/flux-d2/test.sh
  # Since ROOT_DIR is calculated relative to the script's location, we need to create
  # a fake ROOT_DIR structure and place our script there to test it properly,
  # or we can just mock the test script in the real tree temporarily? No, that's dangerous.

  # Let's copy the script to a mock directory structure so it resolves ROOT_DIR to MOCK_DIR
  export FAKE_ROOT="${MOCK_DIR}/repo"
  mkdir -p "${FAKE_ROOT}/bin/ci"
  mkdir -p "${FAKE_ROOT}/bin/tests/flux-d2"

  cp bin/ci/run-flux-test.sh "${FAKE_ROOT}/bin/ci/run-flux-test.sh"
  chmod +x "${FAKE_ROOT}/bin/ci/run-flux-test.sh"

  export SCRIPT_UNDER_TEST="${FAKE_ROOT}/bin/ci/run-flux-test.sh"
}

teardown() {
  rm -rf "${MOCK_DIR}"
  rm -f "${GITHUB_STEP_SUMMARY}"
}

@test "run-flux-test.sh succeeds and writes summary on test success" {
  cat << 'EOF' > "${FAKE_ROOT}/bin/tests/flux-d2/test.sh"
#!/bin/bash
echo "Fake tests passed"
exit 0
EOF
  chmod +x "${FAKE_ROOT}/bin/tests/flux-d2/test.sh"

  run "${SCRIPT_UNDER_TEST}"

  [ "$status" -eq 0 ]

  # Check output
  echo "$output" | grep "Fake tests passed"

  # Check summary
  grep "### :test_tube: Flux D2 Test Results" "$GITHUB_STEP_SUMMARY"
  grep "\*\*Status:\*\* :white_check_mark: Passed" "$GITHUB_STEP_SUMMARY"
  grep "Fake tests passed" "$GITHUB_STEP_SUMMARY"
}

@test "run-flux-test.sh fails and writes summary on test failure" {
  cat << 'EOF' > "${FAKE_ROOT}/bin/tests/flux-d2/test.sh"
#!/bin/bash
echo "Fake tests failed"
exit 1
EOF
  chmod +x "${FAKE_ROOT}/bin/tests/flux-d2/test.sh"

  run "${SCRIPT_UNDER_TEST}"

  [ "$status" -eq 1 ]

  # Check output
  echo "$output" | grep "Fake tests failed"

  # Check summary
  grep "### :test_tube: Flux D2 Test Results" "$GITHUB_STEP_SUMMARY"
  grep "\*\*Status:\*\* :x: Failed" "$GITHUB_STEP_SUMMARY"
  grep "Fake tests failed" "$GITHUB_STEP_SUMMARY"
}
