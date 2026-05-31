#!/usr/bin/env bats

setup() {
  export TEST_TEMP_DIR="$(mktemp -d)"
  export SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." >/dev/null 2>&1 && pwd)"
  export SCRIPT="$SCRIPT_DIR/ci/publish-kubernetes-release.sh"

  # Mock 'git'
  mkdir -p "$TEST_TEMP_DIR/bin"
  cat << 'EOF' > "$TEST_TEMP_DIR/bin/git"
#!/bin/bash
if [[ "$*" == *"rev-parse --short HEAD"* ]]; then
  echo "abcdef1"
elif [[ "$*" == *"rev-parse HEAD"* ]]; then
  echo "abcdef1234567890"
fi
EOF
  chmod +x "$TEST_TEMP_DIR/bin/git"

  # Mock 'flux'
  cat << 'EOF' > "$TEST_TEMP_DIR/bin/flux"
#!/bin/bash
echo "flux $@" >> "$TEST_TEMP_DIR/flux_calls.log"
EOF
  chmod +x "$TEST_TEMP_DIR/bin/flux"

  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  export GITHUB_STEP_SUMMARY="$TEST_TEMP_DIR/step_summary.md"
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

@test "script fails with insufficient arguments" {
  run "$SCRIPT" "owner" "tag" "path"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "script executes flux commands and updates summary" {
  run "$SCRIPT" "TestOwner" "kubernetes-infra-addons@1.2.3" "kubernetes" "https://github.com/repo"

  [ "$status" -eq 0 ]

  # Check if flux push was called correctly
  run grep "flux push artifact oci://ghcr.io/testowner/manifests/kubernetes/infra-addons:abcdef1 --path=./kubernetes/infra-addons --source=https://github.com/repo --revision=abcdef1234567890" "$TEST_TEMP_DIR/flux_calls.log"
  [ "$status" -eq 0 ]

  # Check if flux tag was called correctly
  run grep "flux tag artifact oci://ghcr.io/testowner/manifests/kubernetes/infra-addons:abcdef1 --tag latest --tag 1.2.3" "$TEST_TEMP_DIR/flux_calls.log"
  [ "$status" -eq 0 ]

  # Check step summary
  [ -f "$GITHUB_STEP_SUMMARY" ]
  run grep "### :rocket: Kubernetes Component Published" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
  run grep "\`infra-addons\`" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
  run grep "\`1.2.3\`" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
}
