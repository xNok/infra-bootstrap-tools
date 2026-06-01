#!/usr/bin/env bats

setup() {
  export MOCK_DIR="$(mktemp -d)"
  export PATH="${MOCK_DIR}:$PATH"

  export HUGO_VERSION="0.147.3"
  export RUNNER_TEMP="/tmp"

  # Mock wget
  cat << MOCK > "${MOCK_DIR}/wget"
#!/usr/bin/env bash
echo "wget called with: \$@"
MOCK
  chmod +x "${MOCK_DIR}/wget"

  # Mock sudo
  cat << MOCK > "${MOCK_DIR}/sudo"
#!/usr/bin/env bash
echo "sudo called with: \$@"
MOCK
  chmod +x "${MOCK_DIR}/sudo"
}

teardown() {
  rm -rf "${MOCK_DIR}"
}

@test "install-hugo.sh fails if HUGO_VERSION is not set" {
  unset HUGO_VERSION
  run ./bin/ci/install-hugo.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"HUGO_VERSION is not set"* ]]
}

@test "install-hugo.sh fails if RUNNER_TEMP is not set" {
  unset RUNNER_TEMP
  run ./bin/ci/install-hugo.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"RUNNER_TEMP is not set"* ]]
}

@test "install-hugo.sh succeeds with correct env vars" {
  export GITHUB_STEP_SUMMARY="${MOCK_DIR}/summary.md"
  touch "$GITHUB_STEP_SUMMARY"

  run ./bin/ci/install-hugo.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"wget called with: -O /tmp/hugo.deb https://github.com/gohugoio/hugo/releases/download/v0.147.3/hugo_extended_0.147.3_linux-amd64.deb"* ]]
  [[ "$output" == *"sudo called with: dpkg -i /tmp/hugo.deb"* ]]

  run cat "$GITHUB_STEP_SUMMARY"
  [[ "$output" == *"### :hammer: Hugo Installed"* ]]
}
