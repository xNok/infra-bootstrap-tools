## Task

Clean the branch so it only carries the intended BATS workflow change.

## Findings

- The current local branch matches `origin/main`.
- PR #184 includes the intended new workflow at `.github/workflows/bats.yml`.
- The rest of PR #184 mixes in unrelated workflow, README, Dockerfile, Kubernetes, and shell-script changes.

## Validation

- `pre-commit run --all-files` fails in the current environment because `ansible-lint` cannot reach Galaxy and `terraform-docs` is not installed.
- `bats bin/tests/ci` passes.
