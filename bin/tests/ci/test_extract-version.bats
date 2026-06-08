#!/usr/bin/env bats

setup() {
  export GITHUB_STEP_SUMMARY="$(mktemp)"
  export GITHUB_OUTPUT="$(mktemp)"
}

teardown() {
  rm -f "$GITHUB_STEP_SUMMARY"
  rm -f "$GITHUB_OUTPUT"
}

@test "extract-version.sh extracts version correctly from workflow_dispatch (workspace format)" {
  export EVENT_NAME="workflow_dispatch"
  export INPUTS_RELEASE_TAG="workspace@1.2.3"

  run ./bin/ci/lib/extract-version.sh

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "Version: 1.2.3" ]

  run grep "VERSION=1.2.3" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]

  run grep "Tag: \`workspace@1.2.3\`" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
}

@test "extract-version.sh extracts version correctly from ref_name (v format)" {
  export EVENT_NAME="push"
  export GITHUB_REF_NAME="v2.0.0"

  run ./bin/ci/lib/extract-version.sh

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "Version: 2.0.0" ]

  run grep "VERSION=2.0.0" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]
}
