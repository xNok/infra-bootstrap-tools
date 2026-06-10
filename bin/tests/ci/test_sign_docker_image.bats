#!/usr/bin/env bats

setup() {
  export TEST_TEMP_DIR="$(mktemp -d)"
  export SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." >/dev/null 2>&1 && pwd)"
  export SCRIPT="$SCRIPT_DIR/ci/sign-docker-image.sh"

  # Mock 'cosign'
  mkdir -p "$TEST_TEMP_DIR/bin"
  cat << MOCK > "$TEST_TEMP_DIR/bin/cosign"
#!/bin/bash
echo "cosign \$*" >> "$TEST_TEMP_DIR/cosign_calls.log"
MOCK
  chmod +x "$TEST_TEMP_DIR/bin/cosign"

  export PATH="$TEST_TEMP_DIR/bin:/usr/bin:/bin:$PATH"
  export GITHUB_STEP_SUMMARY="$TEST_TEMP_DIR/step_summary.md"
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

@test "script fails with insufficient arguments" {
  run bash "$SCRIPT" "tags"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "script executes cosign commands and updates summary" {
  tags="tag1
tag2"
  run bash "$SCRIPT" "$tags" "sha256:1234567890abcdef"
  echo "$output" # Debug output
  [ "$status" -eq 0 ]

  # check log file line by line using simple string matching without regular expressions or external commands
  run cat "$TEST_TEMP_DIR/cosign_calls.log"
  [[ "${lines[0]}" == "cosign sign --yes tag1@sha256:1234567890abcdef" ]]
  [[ "${lines[1]}" == "cosign sign --yes tag2@sha256:1234567890abcdef" ]]

  # Check step summary
  [ -f "$GITHUB_STEP_SUMMARY" ]
  run cat "$GITHUB_STEP_SUMMARY"
  [[ "${lines[0]}" == "### :closed_lock_with_key: Docker Image Signed" ]]
  [[ "${lines[1]}" == "**Digest**: \`sha256:1234567890abcdef\`" ]]
  [[ "${lines[2]}" == "**Tags**:" ]]
  [[ "${lines[3]}" == "- \`tag1\`" ]]
  [[ "${lines[4]}" == "- \`tag2\`" ]]
}
