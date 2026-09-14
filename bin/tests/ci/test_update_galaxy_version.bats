#!/usr/bin/env bats

setup() {
  export GITHUB_STEP_SUMMARY="$(mktemp)"
  export MOCK_DIR="$(mktemp -d)"
  export PATH="$MOCK_DIR:$PATH"

  export VERSION="1.2.3"
  export COLLECTION_DIR="$MOCK_DIR/ansible"
  mkdir -p "$COLLECTION_DIR"
  touch "$COLLECTION_DIR/galaxy.yml"

  cat << 'MOCK_EOF' > "$MOCK_DIR/yq"
#!/usr/bin/env bash
echo "$@" >> "$MOCK_DIR/yq.log"
MOCK_EOF
  chmod +x "$MOCK_DIR/yq"
}

teardown() {
  rm -rf "$MOCK_DIR"
  rm -f "$GITHUB_STEP_SUMMARY"
}

@test "update-galaxy-version.sh calls yq with correct arguments" {
  run ./bin/ci/update-galaxy-version.sh

  [ "$status" -eq 0 ]

  run cat "$MOCK_DIR/yq.log"
  [ "$output" = "-i .version = \"1.2.3\" $COLLECTION_DIR/galaxy.yml" ]
}
