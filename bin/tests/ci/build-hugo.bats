#!/usr/bin/env bats

setup() {
  export MOCK_DIR="$(mktemp -d)"
  export PATH="${MOCK_DIR}:$PATH"

  export BASE_URL="https://example.com"

  # create a dummy website dir to avoid cd errors
  mkdir -p website

  # Mock hugo
  cat << MOCK > "${MOCK_DIR}/hugo"
#!/usr/bin/env bash
echo "hugo called with: \$@"
MOCK
  chmod +x "${MOCK_DIR}/hugo"
}

teardown() {
  rm -rf "${MOCK_DIR}"
  rm -rf website
}

@test "build-hugo.sh fails if BASE_URL is not set" {
  unset BASE_URL
  run ./bin/ci/build-hugo.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"BASE_URL is not set"* ]]
}

@test "build-hugo.sh succeeds with correct env vars" {
  export GITHUB_STEP_SUMMARY="${MOCK_DIR}/summary.md"
  touch "$GITHUB_STEP_SUMMARY"

  run ./bin/ci/build-hugo.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"hugo called with: --gc --minify --baseURL https://example.com/"* ]]

  run cat "$GITHUB_STEP_SUMMARY"
  [[ "$output" == *"### :rocket: Website Built"* ]]
}
