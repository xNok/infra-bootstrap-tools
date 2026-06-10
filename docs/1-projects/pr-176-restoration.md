# PR 176 File Restoration

## Goal
Restore files accidentally deleted during rebase/merge and align workflow files with current `main` branch CI patterns.

## Status
- Recreated the three CI scripts in `bin/ci/`:
  - `build-website.sh`
  - `release-kubernetes.sh`
  - `sign-docker-image.sh`
- Recreated the three corresponding BATS tests in `bin/tests/ci/`:
  - `build-website.bats`
  - `test_release_kubernetes.bats`
  - `test_sign_docker_image.bats`
- Recreated conftest policies in `policies/ci/`:
  - `inline_scripts.rego`
  - `no_inline_scripts.rego`
- Updated GitHub Actions workflows to invoke scripts instead of inline multiline shell code:
  - `.github/workflows/website.yml`
  - `.github/workflows/release-kubernetes.yml`
  - `.github/workflows/docker-caddy-publish.yml`
  - `.github/workflows/docker-openziti-bootstrap-publish.yml`
