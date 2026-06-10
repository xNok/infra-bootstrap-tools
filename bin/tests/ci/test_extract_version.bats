#!/usr/bin/env bats

setup() {
  export GITHUB_OUTPUT="$(mktemp)"
}

teardown() {
  rm -f "$GITHUB_OUTPUT"
}

@test "extract version handles package@1.0.0" {
  run ./bin/ci/extract-version-from-tag.sh "workflow_dispatch" "package@1.0.0"
  [ "$status" -eq 0 ]
  grep -q "version=1.0.0" "$GITHUB_OUTPUT"
}

@test "extract version handles v1.0.0" {
  run ./bin/ci/extract-version-from-tag.sh "workflow_dispatch" "v1.0.0"
  [ "$status" -eq 0 ]
  grep -q "version=1.0.0" "$GITHUB_OUTPUT"
}

@test "extract version handler chooses correct tag based on event" {
  run ./bin/ci/extract-version.sh "workflow_dispatch" "input@1.0.0" "release@2.0.0"
  [ "$status" -eq 0 ]
  grep -q "version=1.0.0" "$GITHUB_OUTPUT"

  run ./bin/ci/extract-version.sh "release" "input@1.0.0" "release@2.0.0"
  [ "$status" -eq 0 ]
  grep -q "version=2.0.0" "$GITHUB_OUTPUT"
}
