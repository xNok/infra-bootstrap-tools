#!/usr/bin/env bats

setup() {
  export MOCK_DIR="$(mktemp -d)"
  export PATH="${MOCK_DIR}:$PATH"
  export GITHUB_STEP_SUMMARY="$(mktemp)"

  cat << 'MOCK' > "$MOCK_DIR/yarn"
#!/usr/bin/env bash
echo "mock yarn ran"
MOCK
  chmod +x "$MOCK_DIR/yarn"
}

teardown() {
  rm -rf "$MOCK_DIR"
  rm -f "$GITHUB_STEP_SUMMARY"
}

@test "run-yarn runs yarn" {
  run ./bin/ci/run-yarn.sh

  [ "$status" -eq 0 ]
  [[ "$output" =~ "mock yarn ran" ]]

  # Check github summary
  grep "Yarn Install" "$GITHUB_STEP_SUMMARY"
}
