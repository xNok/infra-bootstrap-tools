#!/usr/bin/env bats

setup() {
    export MOCK_BIN_DIR="$(mktemp -d)"
    export PATH="$MOCK_BIN_DIR:$PATH"
    export GITHUB_STEP_SUMMARY="$(mktemp)"

    # Mock conftest to always succeed
    cat << 'INNER_EOF' > "$MOCK_BIN_DIR/conftest"
#!/usr/bin/env bash
if [[ "$1" == "test" ]]; then
    echo "Mock conftest executed"
elif [[ "$1" == "doc" ]]; then
    echo "Mock conftest doc executed"
fi
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
    rm -f policies/POLICIES_REFERENCE.md
}

@test "run-conftest.sh executes conftest successfully and generates docs" {
    run ./bin/ci/run-conftest.sh

    # Assert successful execution
    [ "$status" -eq 0 ]

    # Assert conftest test output is captured
    [[ "$output" == *"Mock conftest executed"* ]]

    # Assert conftest doc was executed and file created
    run cat policies/POLICIES_REFERENCE.md
    [[ "$output" == *"Mock conftest doc executed"* ]]

    # Assert GITHUB_STEP_SUMMARY is populated correctly
    run cat "$GITHUB_STEP_SUMMARY"
    [[ "$output" == *"### Conftest Policy Validation Results"* ]]
    [[ "$output" == *"✅ All policies passed successfully!"* ]]
}

@test "run-conftest.sh reports failure when conftest fails" {
    # Override the mock to fail on test
    cat << 'INNER_EOF' > "$MOCK_BIN_DIR/conftest"
#!/usr/bin/env bash
if [[ "$1" == "test" ]]; then
    echo "Mock conftest failed"
    (return 1 2>/dev/null) || command exit 1
elif [[ "$1" == "doc" ]]; then
    echo "Mock conftest doc executed"
fi
INNER_EOF
    chmod +x "$MOCK_BIN_DIR/conftest"

    run ./bin/ci/run-conftest.sh

    # Assert failure execution
    [ "$status" -eq 1 ]

    # Assert GITHUB_STEP_SUMMARY is populated correctly for failure
    run cat "$GITHUB_STEP_SUMMARY"
    [[ "$output" == *"### Conftest Policy Validation Results"* ]]
    [[ "$output" == *"❌ Policy violations detected:"* ]]
}
