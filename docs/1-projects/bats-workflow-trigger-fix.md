## Task

Adjust the BATS GitHub Actions workflow so PR updates do not create duplicate runs.

## Findings

- `.github/workflows/bats.yml` currently triggers on both `push` and `pull_request`.
- For PR branches, that causes both events to run for the same change.
- Existing related validation is `yamllint` on the workflow file and `bats bin/tests/ci`.

## Notes

- Keep the branch focused on the BATS workflow fix.
