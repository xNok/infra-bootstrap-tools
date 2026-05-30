#!/usr/bin/env bats

setup() {
  # Add mock flux to PATH
  export MOCK_DIR=$(mktemp -d)
  export PATH="${MOCK_DIR}:${PATH}"

  # Create a mock flux command
  cat << 'EOF' > "${MOCK_DIR}/flux"
#!/usr/bin/env bash
echo "flux $@"
EOF
  chmod +x "${MOCK_DIR}/flux"

  # Mock git to return fake SHA
  cat << 'EOF' > "${MOCK_DIR}/git"
#!/usr/bin/env bash
if [[ "$1" == "rev-parse" ]]; then
  if [[ "$2" == "--short" ]]; then
    echo "deadbeef"
  else
    echo "deadbeef1234567890abcdef"
  fi
else
  echo "git $@"
fi
EOF
  chmod +x "${MOCK_DIR}/git"

  export GITHUB_STEP_SUMMARY="${MOCK_DIR}/summary.md"
}

teardown() {
  rm -rf "${MOCK_DIR}"
}

@test "publish-kubernetes-release.sh requires 4 arguments" {
  run ./bin/ci/publish-kubernetes-release.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "publish-kubernetes-release.sh publishes and tags artifact" {
  run ./bin/ci/publish-kubernetes-release.sh "MyOrg" "kubernetes-infra-addons@1.0.0" "kubernetes" "https://github.com/myorg/repo"

  [ "$status" -eq 0 ]

  # Check flux push
  [[ "$output" == *"flux push artifact oci://ghcr.io/myorg/manifests/kubernetes/infra-addons:deadbeef"* ]]
  [[ "$output" == *"--path=./kubernetes/infra-addons"* ]]
  [[ "$output" == *"--source=https://github.com/myorg/repo"* ]]
  [[ "$output" == *"--revision=deadbeef1234567890abcdef"* ]]

  # Check flux tag
  [[ "$output" == *"flux tag artifact oci://ghcr.io/myorg/manifests/kubernetes/infra-addons:deadbeef --tag latest --tag 1.0.0"* ]]

  # Check summary output
  run cat "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
  [[ "$output" == *"### :rocket: Kubernetes Release Published"* ]]
  [[ "$output" == *"**Bundle Name**: \`infra-addons\`"* ]]
  [[ "$output" == *"**Version**: \`1.0.0\`"* ]]
  [[ "$output" == *"**OCI Repository**: \`oci://ghcr.io/myorg/manifests/kubernetes/infra-addons\`"* ]]
}
