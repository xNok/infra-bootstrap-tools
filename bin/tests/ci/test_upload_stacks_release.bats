#!/usr/bin/env bats

setup() {
  export PATH="$BATS_TEST_DIRNAME/mocks:$PATH"
  mkdir -p "$BATS_TEST_DIRNAME/mocks"

  export GITHUB_STEP_SUMMARY="$(mktemp)"
  export DIST_DIR="$(mktemp -d)"
  touch "$DIST_DIR/test.zip"

  cat << 'MOCK' > "$BATS_TEST_DIRNAME/mocks/gh"
#!/usr/bin/env bash
if [[ "$1" == "release" && "$2" == "view" ]]; then
  if [[ "$3" == "valid@1.0.0" ]]; then
    exit 0
  else
    exit 1
  fi
elif [[ "$1" == "release" && "$2" == "upload" ]]; then
  echo "mock upload"
  exit 0
fi
MOCK
  chmod +x "$BATS_TEST_DIRNAME/mocks/gh"
}

teardown() {
  rm -rf "$BATS_TEST_DIRNAME/mocks"
  rm -rf "$DIST_DIR"
  rm -f "$GITHUB_STEP_SUMMARY"
}

@test "upload stacks uploads if release exists" {
  run ./bin/ci/upload-stacks-release.sh "valid@1.0.0" "$DIST_DIR"
  [ "$status" -eq 0 ]
  grep -q "mock upload" <<< "$output"
  grep -q "Stacks Uploaded" "$GITHUB_STEP_SUMMARY"
}

@test "upload stacks skips if release does not exist" {
  run ./bin/ci/upload-stacks-release.sh "invalid@1.0.0" "$DIST_DIR"
  [ "$status" -eq 0 ]
  grep -q "skipping upload" <<< "$output"
}
