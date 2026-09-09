#!/usr/bin/env bats

setup() {
  export MOCK_BIN_DIR="$(mktemp -d)"
  export PATH="${MOCK_BIN_DIR}:${PATH}"

  export TEMP_TEST_DIR="$(mktemp -d)"
  export ROOT_DIR="${TEMP_TEST_DIR}"
  export WORKFLOWS_DIR="${ROOT_DIR}/.github/workflows"
  export POLICIES_DIR="${ROOT_DIR}/policies/ci"

  mkdir -p "${WORKFLOWS_DIR}"
  mkdir -p "${POLICIES_DIR}"

  touch "${WORKFLOWS_DIR}/test.yml"

  export GITHUB_STEP_SUMMARY="$(mktemp)"

  # Mock wget
  cat << 'SCRIPT' > "${MOCK_BIN_DIR}/wget"
#!/bin/bash
echo "Mock wget called with: $@"
SCRIPT
  chmod +x "${MOCK_BIN_DIR}/wget"

  # Mock tar
  cat << 'SCRIPT' > "${MOCK_BIN_DIR}/tar"
#!/bin/bash
echo "Mock tar called with: $@"
# create mock conftest binary
for arg in "$@"; do
    if [[ "$arg" == "-C" ]]; then
        # The next arg is the directory
        shift
        dir="$1"
        touch "${dir}/conftest"
        chmod +x "${dir}/conftest"

        # mock conftest to be a bash script that just returns success
        cat << 'CONFTEST' > "${dir}/conftest"
#!/bin/bash
echo "1..1"
echo "ok 1 - test.yml"
exit 0
CONFTEST
        break
    fi
    shift
done
SCRIPT
  chmod +x "${MOCK_BIN_DIR}/tar"
}

teardown() {
  rm -rf "${MOCK_BIN_DIR}"
  rm -rf "${TEMP_TEST_DIR}"
  rm -f "${GITHUB_STEP_SUMMARY}"
}

@test "run-conftest.sh executes successfully and outputs to step summary" {
  run bin/ci/run-conftest.sh

  [ "$status" -eq 0 ]

  # Check if step summary was updated
  run grep "### Conftest Results" "${GITHUB_STEP_SUMMARY}"
  [ "$status" -eq 0 ]

  run grep "ok 1 - test.yml" "${GITHUB_STEP_SUMMARY}"
  [ "$status" -eq 0 ]
}
