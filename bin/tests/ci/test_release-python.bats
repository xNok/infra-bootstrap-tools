#!/usr/bin/env bats

setup() {
  export MOCK_BIN_DIR="$(mktemp -d)"
  export PATH="$MOCK_BIN_DIR:$PATH"
  export GITHUB_STEP_SUMMARY="$(mktemp)"
}

teardown() {
  rm -rf "$MOCK_BIN_DIR"
  rm -f "$GITHUB_STEP_SUMMARY"
}

@test "install-python-build-deps.sh installs dependencies" {
  cat << 'EOF' > "$MOCK_BIN_DIR/python"
#!/bin/sh
echo "mock python $@"
EOF
  cat << 'EOF' > "$MOCK_BIN_DIR/pip"
#!/bin/sh
echo "mock pip $@"
EOF
  chmod +x "$MOCK_BIN_DIR/python" "$MOCK_BIN_DIR/pip"

  run ./bin/ci/install-python-build-deps.sh
  [ "$status" -eq 0 ]
  grep "Installed Python build dependencies: build, twine" "$GITHUB_STEP_SUMMARY"
}

@test "update-pyproject-version.sh updates version and name" {
  export TEST_DIR="$(mktemp -d)"
  touch "$TEST_DIR/pyproject.toml"
  echo 'version = "0.0.0"' > "$TEST_DIR/pyproject.toml"
  echo 'name = "old-name"' >> "$TEST_DIR/pyproject.toml"

  run ./bin/ci/update-pyproject-version.sh "$TEST_DIR" "new-name" "1.0.0"
  [ "$status" -eq 0 ]
  grep 'version = "1.0.0"' "$TEST_DIR/pyproject.toml"
  grep 'name = "new-name"' "$TEST_DIR/pyproject.toml"
  grep "Updated pyproject.toml in $TEST_DIR: name=new-name, version=1.0.0" "$GITHUB_STEP_SUMMARY"
  rm -rf "$TEST_DIR"
}

@test "build-python-package.sh builds the package" {
  export TEST_DIR="$(mktemp -d)"
  cat << 'EOF' > "$MOCK_BIN_DIR/python"
#!/bin/sh
echo "mock python $@"
EOF
  chmod +x "$MOCK_BIN_DIR/python"

  run ./bin/ci/build-python-package.sh "$TEST_DIR"
  [ "$status" -eq 0 ]
  grep "Successfully built python package in $TEST_DIR" "$GITHUB_STEP_SUMMARY"
  rm -rf "$TEST_DIR"
}

@test "upload-python-package.sh uploads to release" {
  cat << 'EOF' > "$MOCK_BIN_DIR/gh"
#!/bin/sh
echo "mock gh $@"
EOF
  chmod +x "$MOCK_BIN_DIR/gh"

  run ./bin/ci/upload-python-package.sh "my-dir" "my-tag"
  [ "$status" -eq 0 ]
  grep "Uploaded python package artifacts from my-dir to release tag my-tag" "$GITHUB_STEP_SUMMARY"
}
