#!/usr/bin/env bats

setup() {
    export MOCK_BIN_DIR="$(mktemp -d)"
    export PATH="$MOCK_BIN_DIR:$PATH"
    export MOCK_LOG="$(mktemp)"

    cat << 'MOCK' > "$MOCK_BIN_DIR/git"
#!/usr/bin/env bash
echo "git $*" >> "$MOCK_LOG"
if [[ "$*" == *"rev-parse --verify origin/main"* ]]; then
  exit 0
fi
if [[ "$*" == *"rev-parse --verify origin/custom-branch"* ]]; then
  exit 1
fi
exit 0
MOCK
    chmod +x "$MOCK_BIN_DIR/git"
}

teardown() {
    rm -rf "$MOCK_BIN_DIR"
    rm -f "$MOCK_LOG"
}

@test "restore-scripts-from-main.sh checks out from origin/main by default" {
    run ./bin/ci/restore-scripts-from-main.sh
    [ "$status" -eq 0 ]
    grep -q "git checkout origin/main -- bin/ci/" "$MOCK_LOG"
}

@test "restore-scripts-from-main.sh fetches branch if not verified locally" {
    run ./bin/ci/restore-scripts-from-main.sh "custom-branch"
    [ "$status" -eq 0 ]
    grep -q "git fetch origin custom-branch:refs/remotes/origin/custom-branch --depth=1" "$MOCK_LOG"
    grep -q "git checkout origin/custom-branch -- bin/ci/" "$MOCK_LOG"
}
