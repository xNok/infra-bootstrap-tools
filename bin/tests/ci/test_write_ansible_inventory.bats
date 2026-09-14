#!/usr/bin/env bats

setup() {
  export GITHUB_STEP_SUMMARY="$(mktemp)"
  export MOCK_DIR="$(mktemp -d)"
  export INVENTORY="test inventory content"
  export WORK_DIR="$(mktemp -d)"
  mkdir -p "$WORK_DIR/inventory"

  # Copy the script to WORK_DIR and run it from there to write to its inventory/extra
  cp bin/ci/write-ansible-inventory.sh "$WORK_DIR/"

  # Go into WORK_DIR so the relative write goes there
  cd "$WORK_DIR"
}

teardown() {
  rm -rf "$MOCK_DIR"
  rm -f "$GITHUB_STEP_SUMMARY"
  rm -rf "$WORK_DIR"
}

@test "write-ansible-inventory writes to inventory/extra and updates summary" {
  run ./write-ansible-inventory.sh

  [ "$status" -eq 0 ]

  [ -f "inventory/extra" ]
  run cat "inventory/extra"
  [ "$output" = "test inventory content" ]
}
