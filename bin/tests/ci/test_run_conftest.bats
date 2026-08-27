#!/usr/bin/env bats

setup() {
    export MOCK_BIN_DIR="$(mktemp -d)"
    export PATH="$MOCK_BIN_DIR:$PATH"
    export GITHUB_STEP_SUMMARY="$(mktemp)"

    # Mock conftest to always succeed
    cat << 'INNER_EOF' > "$MOCK_BIN_DIR/conftest"
#!/usr/bin/env bash
echo "Mock conftest executed"
INNER_EOF
    chmod +x "$MOCK_BIN_DIR/conftest"

    # Mock wget to prevent downloads
    cat << 'INNER_EOF' > "$MOCK_BIN_DIR/wget"
#!/usr/bin/env bash
echo "Mock wget executed"
INNER_EOF
    chmod +x "$MOCK_BIN_DIR/wget"
}

teardown() {
    rm -rf "$MOCK_BIN_DIR"
    rm -f "$GITHUB_STEP_SUMMARY"
}

@test "run-conftest.sh executes conftest successfully" {
    run ./bin/ci/run-conftest.sh

    # Assert successful execution
    [ "$status" -eq 0 ]

    # Assert conftest output is captured
    [[ "$output" == *"Mock conftest executed"* ]]

    # Assert GITHUB_STEP_SUMMARY is populated correctly
    run cat "$GITHUB_STEP_SUMMARY"
    [[ "$output" == *"### Conftest Policy Validation Results"* ]]
    [[ "$output" == *"✅ All policies passed successfully!"* ]]
}

@test "run-conftest.sh reports failure when conftest fails" {
    # Override the mock to fail
    cat << 'INNER_EOF' > "$MOCK_BIN_DIR/conftest"
#!/usr/bin/env bash
echo "Mock conftest failed"
INNER_EOF
    # Remove exit to avoid parsing errors in the heredoc, use return or false
    echo "(return 1 2>/dev/null) || command exit 1" >> "$MOCK_BIN_DIR/conftest"

    run ./bin/ci/run-conftest.sh

    # Assert failure execution
    [ "$status" -eq 1 ]

    # Assert GITHUB_STEP_SUMMARY is populated correctly for failure
    run cat "$GITHUB_STEP_SUMMARY"
    [[ "$output" == *"### Conftest Policy Validation Results"* ]]
    [[ "$output" == *"❌ Policy violations detected:"* ]]
}
