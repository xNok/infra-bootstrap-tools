#!/usr/bin/env bats

setup() {
  export GITHUB_STEP_SUMMARY="$(mktemp)"
  export MOCK_BIN_DIR="$(mktemp -d)"
  export PATH="${MOCK_BIN_DIR}:${PATH}"

  cat << 'MOCK' > "${MOCK_BIN_DIR}/sudo"
#!/usr/bin/env bash
if [ "$1" = "apt-get" ]; then
  if [ "$2" = "update" ]; then
    echo "Mock apt-get update"
  elif [ "$2" = "install" ] && [ "$3" = "-y" ] && [ "$4" = "bats" ]; then
    echo "Mock apt-get install bats"
  fi
fi
MOCK
  chmod +x "${MOCK_BIN_DIR}/sudo"

  cat << 'MOCK' > "${MOCK_BIN_DIR}/bats"
#!/usr/bin/env bash
if [ "$1" = "-v" ]; then
  echo "Bats 1.9.0"
fi
MOCK
  chmod +x "${MOCK_BIN_DIR}/bats"
}

teardown() {
  rm -f "$GITHUB_STEP_SUMMARY"
  rm -rf "$MOCK_BIN_DIR"
}

@test "install-bats.sh installs bats and writes summary" {
  run ./bin/ci/lib/install-bats.sh

  [ "$status" -eq 0 ]
  run grep "### :hammer_and_wrench: Installed BATS" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
  run grep "BATS version: Bats 1.9.0" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
}
