#!/usr/bin/env bats

setup() {
  export TEST_DIR="$(mktemp -d)"
  export DIST_DIR="$(mktemp -d)"
  export GITHUB_STEP_SUMMARY="$(mktemp)"

  mkdir -p "$TEST_DIR/stack-a"
  echo "test" > "$TEST_DIR/stack-a/file.txt"

  mkdir -p "$TEST_DIR/stack-b"
  echo "test" > "$TEST_DIR/stack-b/file.txt"

  # create a node_modules which should be ignored
  mkdir -p "$TEST_DIR/stack-b/node_modules"
  echo "test" > "$TEST_DIR/stack-b/node_modules/file.txt"
}

teardown() {
  rm -rf "$TEST_DIR"
  rm -rf "$DIST_DIR"
  rm -f "$GITHUB_STEP_SUMMARY"
}

@test "package stacks creates correct zips" {
  run ./bin/ci/package-stacks.sh "$TEST_DIR" "1.0.0" "$DIST_DIR"
  [ "$status" -eq 0 ]

  # Check individual stack zip
  [ -f "$DIST_DIR/stack-a-1.0.0.zip" ]
  [ -f "$DIST_DIR/stack-b-1.0.0.zip" ]

  # Check combined stack zip
  [ -f "$DIST_DIR/infra-bootstrap-tools-stacks-1.0.0.zip" ]

  # Check output summary
  grep -q "Stacks Packaged" "$GITHUB_STEP_SUMMARY"
}
