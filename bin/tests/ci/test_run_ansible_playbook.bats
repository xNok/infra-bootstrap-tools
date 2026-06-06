#!/usr/bin/env bats

setup() {
  export TEST_TEMP_DIR="$(mktemp -d)"
  export SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." >/dev/null 2>&1 && pwd)"
  export SCRIPT="$SCRIPT_DIR/ci/run-ansible-playbook.sh"

  mkdir -p "$TEST_TEMP_DIR/bin"

  cat << 'EOF' > "$TEST_TEMP_DIR/bin/ansible-playbook"
#!/bin/bash
echo "ansible-playbook $@" >> "$TEST_TEMP_DIR/ansible_playbook_calls.log"
EOF
  chmod +x "$TEST_TEMP_DIR/bin/ansible-playbook"

  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  export GITHUB_STEP_SUMMARY="$TEST_TEMP_DIR/step_summary.md"
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

@test "run-ansible-playbook.sh executes ansible-playbook and updates summary" {
  run "$SCRIPT"
  [ "$status" -eq 0 ]

  run grep "ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/main.yml" "$TEST_TEMP_DIR/ansible_playbook_calls.log"
  [ "$status" -eq 0 ]

  [ -f "$GITHUB_STEP_SUMMARY" ]
  run grep "### :rocket: Ansible Playbook Executed Successfully" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
}
