#!/usr/bin/env bats

setup() {
  export MOCK_DIR="$(mktemp -d)"
  export PATH="${MOCK_DIR}:${PATH}"

  export GITHUB_STEP_SUMMARY="${MOCK_DIR}/step_summary.md"
  touch "$GITHUB_STEP_SUMMARY"

  # Mock wget
  cat << 'MOCK_EOF' > "${MOCK_DIR}/wget"
#!/usr/bin/env bash
echo "mock wget $@"
MOCK_EOF
  chmod +x "${MOCK_DIR}/wget"

  # Mock sudo
  cat << 'MOCK_EOF' > "${MOCK_DIR}/sudo"
#!/usr/bin/env bash
echo "mock sudo $@"
MOCK_EOF
  chmod +x "${MOCK_DIR}/sudo"

  # Mock cd
  # We can't mock cd easily as an executable since it's a shell builtin.
  # But we can override it in a function if needed. However, since the script runs in a separate bash session,
  # the script's `cd website` will look for a `website` directory in the current working directory.
  # We should just create a dummy website directory.
  export MOCK_WEBSITE_DIR="$(mktemp -d)"

  # Instead of relying on a physical directory, we can wrap the execution

  # Mock hugo
  cat << 'MOCK_EOF' > "${MOCK_DIR}/hugo"
#!/usr/bin/env bash
echo "mock hugo $@"
MOCK_EOF
  chmod +x "${MOCK_DIR}/hugo"
}

teardown() {
  rm -rf "$MOCK_DIR"
  rm -rf "$MOCK_WEBSITE_DIR"
}

@test "build-website.sh fails when missing arguments" {
  run ./bin/ci/build-website.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "build-website.sh executes successfully and outputs summary" {
  # Create a wrapper to intercept cd website
  cat << 'WRAPPER_EOF' > "${MOCK_DIR}/test_wrapper.sh"
#!/usr/bin/env bash
cd() {
  echo "mock cd $@"
}
export -f cd
./bin/ci/build-website.sh "0.147.3" "/tmp/runner" "https://example.com"
WRAPPER_EOF
  chmod +x "${MOCK_DIR}/test_wrapper.sh"

  run "${MOCK_DIR}/test_wrapper.sh"

  echo "$output"
  [ "$status" -eq 0 ]

  # Check if mock commands were called
  [[ "$output" == *"mock wget -O /tmp/runner/hugo.deb https://github.com/gohugoio/hugo/releases/download/v0.147.3/hugo_extended_0.147.3_linux-amd64.deb"* ]]
  [[ "$output" == *"mock sudo dpkg -i /tmp/runner/hugo.deb"* ]]
  [[ "$output" == *"mock cd website"* ]]
  [[ "$output" == *"mock hugo --gc --minify --baseURL https://example.com/"* ]]

  # Check if summary was populated
  run cat "$GITHUB_STEP_SUMMARY"
  [[ "$output" == *"### :rocket: Website Built Successfully"* ]]
  [[ "$output" == *"**Hugo Version**: \`0.147.3\`"* ]]
  [[ "$output" == *"**Base URL**: \`https://example.com\`"* ]]
}
