#!/usr/bin/env bats

setup() {
    export MOCK_BIN_DIR="$(mktemp -d)"
    export PATH="$MOCK_BIN_DIR:$PATH"

    cat << 'MOCK' > "$MOCK_BIN_DIR/yq"
#!/bin/bash
echo "yq $*"
MOCK
    chmod +x "$MOCK_BIN_DIR/yq"

    export GITHUB_STEP_SUMMARY="$(mktemp)"
}

teardown() {
    rm -rf "$MOCK_BIN_DIR"
    rm -f "$GITHUB_STEP_SUMMARY"
}

@test "update-collection-version.sh executes yq with correct arguments and updates step summary" {
    run ./bin/ci/lib/update-collection-version.sh "1.2.3" "ansible"
    [ "$status" -eq 0 ]

    # Check if yq was called correctly
    [[ "${lines[0]}" == "yq -i .version = \"1.2.3\" ansible/galaxy.yml" ]]

    # Check if step summary was updated
    grep -q "Updated Collection Version" "$GITHUB_STEP_SUMMARY"
    grep -q "Set version to \`1.2.3\` in \`ansible/galaxy.yml\`" "$GITHUB_STEP_SUMMARY"
}
