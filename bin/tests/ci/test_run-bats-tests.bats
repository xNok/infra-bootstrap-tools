#!/usr/bin/env bats

setup() {
  export GITHUB_STEP_SUMMARY="$(mktemp)"
  export MOCK_BIN_DIR="$(mktemp -d)"
  export PATH="${MOCK_BIN_DIR}:${PATH}"

  cat << 'MOCK' > "${MOCK_BIN_DIR}/bats"
#!/usr/bin/env bash
if [ "$1" = "--formatter" ] && [ "$2" = "tap" ]; then
  echo "1..1"
  echo "ok 1 test pass"
fi
MOCK
  chmod +x "${MOCK_BIN_DIR}/bats"
}

teardown() {
  rm -f "$GITHUB_STEP_SUMMARY"
  rm -rf "$MOCK_BIN_DIR"
  rm -f test_results.tap
}

@test "run-bats-tests.sh runs bats, creates tap output and writes to summary" {
  run ./bin/ci/lib/run-bats-tests.sh

  [ "$status" -eq 0 ]

  run grep "### :test_tube: BATS Test Results" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]

  run grep "ok 1 test pass" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]

  run grep "ok 1 test pass" test_results.tap
  [ "$status" -eq 0 ]
}
