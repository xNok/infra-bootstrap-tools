#!/usr/bin/env bats

setup() {
    export MOCK_BIN_DIR="$(mktemp -d)"
    export PATH="$MOCK_BIN_DIR:$PATH"

    cat << 'MOCK' > "$MOCK_BIN_DIR/make"
#!/bin/bash
echo "make $*"
MOCK
    chmod +x "$MOCK_BIN_DIR/make"

    cat << 'MOCK' > "$MOCK_BIN_DIR/ansible-lint"
#!/bin/bash
echo "ansible-lint $*"
MOCK
    chmod +x "$MOCK_BIN_DIR/ansible-lint"

    export GITHUB_STEP_SUMMARY="$(mktemp)"
}

teardown() {
    rm -rf "$MOCK_BIN_DIR"
    rm -f "$GITHUB_STEP_SUMMARY"
}

@test "ansible-lint.sh calls make install-collection and ansible-lint ansible" {
    run ./bin/ci/ansible-lint.sh
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" == "make install-collection" ]]
    [[ "${lines[1]}" == "ansible-lint ansible" ]]
    grep -q "Ansible Lint Run" "$GITHUB_STEP_SUMMARY"
}
