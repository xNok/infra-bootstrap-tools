#!/usr/bin/env bats

setup() {
  export MOCK_DIR="$(mktemp -d)"
  export PATH="${MOCK_DIR}:$PATH"
  export GITHUB_STEP_SUMMARY="$(mktemp)"

  # Ensure inventory dir exists in the current working directory is mocked, so we just run the script inside MOCK_DIR
  cd "$MOCK_DIR"
}

teardown() {
  cd - > /dev/null
  rm -rf "$MOCK_DIR"
  rm -f "$GITHUB_STEP_SUMMARY"
}

@test "write-inventory-extra writes inventory" {
  export INVENTORY="[web]
web1 ansible_host=10.0.0.1"

  run "$OLDPWD/bin/ci/write-inventory-extra.sh"

  [ "$status" -eq 0 ]

  # Check if file was created
  [ -f "inventory/extra" ]

  # Check contents
  grep "web1 ansible_host=10.0.0.1" "inventory/extra"

  # Check github summary
  grep "Setup Ansible Extra Inventory" "$GITHUB_STEP_SUMMARY"
}

@test "write-inventory-extra fails when INVENTORY is not set" {
  unset INVENTORY

  run "$OLDPWD/bin/ci/write-inventory-extra.sh"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "INVENTORY environment variable is required" ]]
}
