#!/usr/bin/env bats

setup() {
  export TEST_TEMP_DIR="$(mktemp -d)"
  export SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." >/dev/null 2>&1 && pwd)"
  export SCRIPT="$SCRIPT_DIR/ci/run-ansible-lint.sh"

  mkdir -p "$TEST_TEMP_DIR/bin"

  cat << 'EOF' > "$TEST_TEMP_DIR/bin/make"
#!/bin/bash
echo "make $@" >> "$TEST_TEMP_DIR/make_calls.log"
EOF
  chmod +x "$TEST_TEMP_DIR/bin/make"

  cat << 'EOF' > "$TEST_TEMP_DIR/bin/ansible-lint"
#!/bin/bash
echo "ansible-lint $@" >> "$TEST_TEMP_DIR/ansible_lint_calls.log"
EOF
  chmod +x "$TEST_TEMP_DIR/bin/ansible-lint"

  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  export GITHUB_STEP_SUMMARY="$TEST_TEMP_DIR/step_summary.md"
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

@test "run-ansible-lint.sh executes make and ansible-lint and updates summary" {
  run "$SCRIPT"
  [ "$status" -eq 0 ]

  run grep "make install-collection" "$TEST_TEMP_DIR/make_calls.log"
  [ "$status" -eq 0 ]

  run grep "ansible-lint ansible" "$TEST_TEMP_DIR/ansible_lint_calls.log"
  [ "$status" -eq 0 ]

  [ -f "$GITHUB_STEP_SUMMARY" ]
  run grep "### :white_check_mark: Ansible Lint Passed" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
}
