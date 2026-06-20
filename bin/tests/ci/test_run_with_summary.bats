#!/usr/bin/env bats

setup() {
  export GITHUB_STEP_SUMMARY="$(mktemp)"

  MOCK_DIR="$(mktemp -d)"
  export MOCK_BIN_DIR="$MOCK_DIR/bin"
  mkdir -p "$MOCK_BIN_DIR"
  export PATH="$MOCK_BIN_DIR:$PATH"
}

teardown() {
  rm -f "$GITHUB_STEP_SUMMARY"
  rm -rf "$MOCK_DIR"
}

@test "run-with-summary.sh fails if no command provided" {
  run ./bin/ci/lib/run-with-summary.sh

  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage: "* ]]
}

@test "run-with-summary.sh executes command and generates success summary" {
  cat << 'EOF' > "$MOCK_BIN_DIR/mock-script"
#!/usr/bin/env bash
echo "Mocked output success"
exit 0
EOF
  chmod +x "$MOCK_BIN_DIR/mock-script"

  run ./bin/ci/lib/run-with-summary.sh "$MOCK_BIN_DIR/mock-script"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Mocked output success"* ]]

  [ -f "$GITHUB_STEP_SUMMARY" ]
  summary_content=$(cat "$GITHUB_STEP_SUMMARY")
  [[ "$summary_content" == *"### Command Execution Results:"* ]]
  [[ "$summary_content" == *"✅ Execution passed successfully"* ]]
  [[ "$summary_content" == *"Mocked output success"* ]]
}

@test "run-with-summary.sh executes command and generates failure summary" {
  cat << 'EOF' > "$MOCK_BIN_DIR/mock-script-fail"
#!/usr/bin/env bash
echo "Mocked output failure"
exit 1
EOF
  chmod +x "$MOCK_BIN_DIR/mock-script-fail"

  run ./bin/ci/lib/run-with-summary.sh "$MOCK_BIN_DIR/mock-script-fail"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Mocked output failure"* ]]

  [ -f "$GITHUB_STEP_SUMMARY" ]
  summary_content=$(cat "$GITHUB_STEP_SUMMARY")
  [[ "$summary_content" == *"### Command Execution Results:"* ]]
  [[ "$summary_content" == *"❌ Execution failed"* ]]
  [[ "$summary_content" == *"Mocked output failure"* ]]
}

@test "run-with-summary.sh passes arguments correctly" {
  cat << 'EOF' > "$MOCK_BIN_DIR/mock-script-args"
#!/usr/bin/env bash
echo "Args: $1 $2"
exit 0
EOF
  chmod +x "$MOCK_BIN_DIR/mock-script-args"

  run ./bin/ci/lib/run-with-summary.sh "$MOCK_BIN_DIR/mock-script-args" "arg1" "arg2"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Args: arg1 arg2"* ]]

  [ -f "$GITHUB_STEP_SUMMARY" ]
  summary_content=$(cat "$GITHUB_STEP_SUMMARY")
  [[ "$summary_content" == *"Args: arg1 arg2"* ]]
}
