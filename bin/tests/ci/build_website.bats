#!/usr/bin/env bats

setup() {
    export MOCK_DIR="$(mktemp -d)"
    export RUNNER_TEMP="$MOCK_DIR/tmp"
    mkdir -p "$RUNNER_TEMP"
    export BASE_URL="https://example.com/"

    # Mock wget
    wget() {
        echo "Mocked wget: $@"
        touch "${RUNNER_TEMP}/hugo.deb"
    }
    export -f wget

    # Mock sudo dpkg
    sudo() {
        echo "Mocked sudo: $@"
    }
    export -f sudo

    # Mock hugo
    hugo() {
        echo "Mocked hugo: $@"
    }
    export -f hugo

    export GITHUB_STEP_SUMMARY="$MOCK_DIR/step_summary.md"
}

teardown() {
    rm -rf "$MOCK_DIR"
}

@test "build_website.sh executes successfully" {
    run ./bin/ci/build_website.sh
    [ "$status" -eq 0 ]

    # Verify summary is created
    [ -f "$GITHUB_STEP_SUMMARY" ]
    run cat "$GITHUB_STEP_SUMMARY"
    [[ "${lines[0]}" == "### Website Build Successful :rocket:" ]]
}
