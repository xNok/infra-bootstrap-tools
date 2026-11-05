# Fix Deployment Lock Permissions & Security Hardening

## Overview & Problem
When deploying or unlocking deployment locks on `lock-branch`, the GitHub Actions bot encountered:
```
remote: Permission to xNok/infra-bootstrap-tools.git denied to github-actions[bot].
fatal: unable to access 'https://github.com/xNok/infra-bootstrap-tools/': The requested URL returned error: 403
Error: Process completed with exit code 128.
```

## Changes Implemented

### 1. Least-Privilege Permissions
- Added top-level `permissions: contents: read` to `.github/workflows/ansible-play-docker-swarm.yml` and `.github/workflows/ansible-utils-unlock.yml` to establish a default-deny posture.
- Granted `permissions: contents: write` exclusively to the `lock` jobs in both workflows, allowing `github-actions[bot]` to push commit locks to `lock-branch`.
- Explicitly restricted `validate` and `run-playbook` to `contents: read`.

### 2. Execution from Default Branch (`main`)
- Updated `actions/checkout` in `lock` job to check out `ref: ${{ github.event.repository.default_branch || 'main' }}` so `.github/actions/pr-lock` and `.github/actions/pr-unlock` execute trusted definitions from `main`, protecting against malicious PR modification of composite actions with write tokens.
- Created `bin/ci/restore-scripts-from-main.sh` and integrated it before `ansible-lint.sh` and `run-playbook.sh` in `ansible-play-docker-swarm.yml` to ensure execution scripts are restored from `main` before running sensitive tasks or accessing environment secrets (`OP_SERVICE_ACCOUNT_TOKEN`, `ANSIBLE_INVENTORY`).
- Created BATS test suite in `bin/tests/ci/test_restore-scripts-from-main.bats`.

### 3. Workflow Triggers & Fork Protection
- Fixed path trigger in `ansible-play-docker-swarm.yml` from outdated `.github/workflows/ansible.yml` to `.github/workflows/ansible-play-docker-swarm.yml`.
- Added guard (`if: github.event_name != 'pull_request' || github.event.pull_request.head.repo.full_name == github.repository`) to `lock` and `run-playbook` jobs to prevent untrusted fork pull requests from attempting deployment locks or accessing deployment environments.
- Updated `.github/actions/pr-unlock/action.yml` to safely check if `lock-branch` exists on origin before attempting to fetch/checkout, avoiding step failures when no lock branch exists.
- Cleaned up whitespace formatting on git push commands in `.github/actions/pr-lock/action.yml`.
