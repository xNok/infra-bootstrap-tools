#!/usr/bin/env bats

setup() {
  # Mock GITHUB_STEP_SUMMARY
  export GITHUB_STEP_SUMMARY="$(mktemp)"
}

teardown() {
  rm -f "$GITHUB_STEP_SUMMARY"
}

@test "docker-summary writes to GITHUB_STEP_SUMMARY" {
  run ./bin/ci/docker-summary.sh "ghcr.io/my-image" "true" "v1.0.0" "sha256:12345"

  [ "$status" -eq 0 ]

  run cat "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
  [[ "$output" == *"### :rocket: Docker Image Build"* ]]
  [[ "$output" == *"**Image:** \`ghcr.io/my-image\`"* ]]
  [[ "$output" == *"**Pushed:** \`true\`"* ]]
  [[ "$output" == *"**Tags:** \`v1.0.0\`"* ]]
  [[ "$output" == *"**Digest:** \`sha256:12345\`"* ]]
}
