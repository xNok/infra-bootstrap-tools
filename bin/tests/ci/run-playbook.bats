#!/usr/bin/env bats

setup() {
    export MOCK_BIN_DIR="$(mktemp -d)"
    export PATH="$MOCK_BIN_DIR:$PATH"

    cat << 'MOCK' > "$MOCK_BIN_DIR/ansible-playbook"
#!/bin/bash
echo "ansible-playbook $*"
MOCK
    chmod +x "$MOCK_BIN_DIR/ansible-playbook"

    export GITHUB_STEP_SUMMARY="$(mktemp)"
}

teardown() {
    rm -rf "$MOCK_BIN_DIR"
    rm -f "$GITHUB_STEP_SUMMARY"
}

@test "run-playbook.sh calls ansible-playbook with correct arguments" {
    run ./bin/ci/run-playbook.sh
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" == "ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/main.yml" ]]
    grep -q "Ansible Playbook Run" "$GITHUB_STEP_SUMMARY"
}
