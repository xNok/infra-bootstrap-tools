#!/usr/bin/env bats

setup() {
    export MOCK_BIN_DIR="$(mktemp -d)"
    export PATH="$MOCK_BIN_DIR:$PATH"

    cat << 'MOCK' > "$MOCK_BIN_DIR/pip"
#!/bin/bash
echo "pip $*"
MOCK
    chmod +x "$MOCK_BIN_DIR/pip"

    cat << 'MOCK' > "$MOCK_BIN_DIR/ansible"
#!/bin/bash
echo "ansible [core 2.14.3]"
MOCK
    chmod +x "$MOCK_BIN_DIR/ansible"

    export GITHUB_STEP_SUMMARY="$(mktemp)"
}

teardown() {
    rm -rf "$MOCK_BIN_DIR"
    rm -f "$GITHUB_STEP_SUMMARY"
}

@test "install-ansible-core.sh installs ansible-core and writes to step summary" {
    run ./bin/ci/lib/install-ansible-core.sh
    [ "$status" -eq 0 ]

    # Check if pip install was called correctly
    [[ "${lines[0]}" == "pip install ansible-core" ]]

    # Check if the step summary was updated
    grep -q "Installed Ansible Core" "$GITHUB_STEP_SUMMARY"
    grep -q "Ansible version: ansible \[core 2.14.3\]" "$GITHUB_STEP_SUMMARY"
}
