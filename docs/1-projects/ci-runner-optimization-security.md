---
type: project
status: active
description: CI runner minute optimization strategy and security best practice policy enforcement for GitHub Actions
related_projects:
  - ibt-nix-refactor
  - changeset-release-mgmt
related_resources:
  - nix
  - bash
  - rego
related_areas:
  - developer-experience
  - security-identity
---

# CI Runner Optimization & Security Architecture

## Overview

This project analyzes the current GitHub Actions CI/CD infrastructure across the `infra-bootstrap-tools` monorepo to:
1. **Optimize runner minutes**: Define what to run, when to run it, and where to run it, eliminating redundant executions, uncancelled stale runs, expensive Nix shell hook overhead, and inappropriate triggers.
2. **Harden CI security**: Implement least-privilege token permissions, eliminate secret exposure risks on pull requests, guard against script injection vulnerabilities, enforce immutable action pinning, and prevent unauthorized artifact publishing.
3. **Automate policy enforcement**: Wire up automated policy checks (using OPA / Conftest with Rego) to continuously validate that workflow files meet strict performance and security standards.

---

## 1. CI Audit Findings

### A. Runner Minute Waste & Inefficiencies

1. **Nix `shellHook` execution on every step**:
   - In `bin/nix/common.nix`, `mkShellHook` runs heavy setup tasks indiscriminately:
     - `tenv tf install` (downloads Terraform binary from the internet)
     - `pip install -r requirements.txt` & `pip install -r agentic/requirements.txt`
     - `ansible-galaxy install -r requirements.yml`
     - `pre-commit install --install-hooks`
   - In CI jobs that set `defaults.run.shell: nix develop .#<shell> --command bash -eo pipefail {0}`, **every single step** triggers the shell hook!
   - Pre-commit hook installation in ephemeral CI runners is entirely redundant.
   - Network installations (pip, galaxy, tenv) in each step waste 45–90 seconds per step per job.
   - **Fix**: Guard interactive setup tasks in `mkShellHook` behind `if [ -z "${CI:-}" ]; then ... fi`.

2. **Unnecessary Nix installation in container workflows**:
   - `release-docker.yml` installs Nix via `nix-installer-action` and `magic-nix-cache-action`, yet only runs `docker/build-push-action`, `cosign`, and two simple bash scripts (`sign-docker-image.sh` and `docker-summary.sh`).
   - Installing Nix adds 60–120 seconds of runner time for a job that does not use any Nix dependencies.

3. **Concurrency and Stale Run Cancellation**:
   - Several workflows (`bats.yml`, `flux-test.yml`, `flux-oci-publish.yml`) have **no concurrency group** configured. Multiple pushes to a PR trigger concurrent runs that execute to completion without cancelling obsolete runs.
   - Other workflows (`ansible-play-docker-swarm.yml`, `docker-caddy-publish.yml`, `docker-openziti-bootstrap-publish.yml`, `website.yml`) have `cancel-in-progress: false`. If a contributor pushes 3 commits, all 3 runs queue up and run serially.
   - In `website.yml`, `concurrency.group: "pages"` forces all pull requests into the same global queue as production deployments, blocking deployments and creating massive queuing delays.

4. **Faulty and Overly Broad Triggers**:
   - `ansible-play-docker-swarm.yml` and `website.yml` listen on `pull_request` types including `edited`. Editing a PR title or description triggers the entire pipeline!
   - `ansible-play-docker-swarm.yml` includes `.github/workflows/ansible.yml` in its `paths:`, which is a dead reference (the workflow is named `ansible-play-docker-swarm.yml`).
   - Workflows lack negative path filters (e.g. documentation-only changes triggering bats tests or container builds).

5. **Redundant Jobs and Artifacts**:
   - `ansible-play-docker-swarm.yml` spins up a separate runner job (`lock`) just to checkout code and push a `.deploy-lock` file to a `lock-branch`. This can be handled natively via GitHub Environment concurrency.
   - `website.yml` executes `actions/upload-pages-artifact` on every pull request, even though the `deploy` job only runs on `main`.
   - Artifact uploads (`actions/upload-artifact@v4`) omit `retention-days`, defaulting to GitHub's maximum 90 days.

---

### B. Security Vulnerabilities & Best Practice Deficits

1. **Permissive Token Permissions (`permissions:`)**:
   - Multiple workflows (`ansible-play-docker-swarm.yml`, `ansible-utils-unlock.yml`, `flux-test.yml`, `release-changeset.yml`) lack explicit `permissions:` declarations, falling back to the default repository permission (which may grant write access).
   - `website.yml` grants top-level `contents: write`, `pages: write`, and `id-token: write` across all jobs, including PR builds.

2. **Dangerous PR Artifact Publishing**:
   - `flux-oci-publish.yml` triggers on `pull_request` against `kubernetes/**` and immediately executes `flux push artifact ... $OCI_REPO:latest`.
   - Any untrusted or unreviewed PR could overwrite the `:latest` Flux OCI image in GHCR prior to code review and merge!

3. **Untrusted Pull Request Deployment**:
   - `ansible-play-docker-swarm.yml` requests `environment: docker_swarm` on `pull_request` triggers and passes `secrets.OP_SERVICE_ACCOUNT_TOKEN` and `secrets.ANSIBLE_INVENTORY` to `run-playbook.sh`.
   - Running live infrastructure playbooks on PR branches without an environment protection gate poses significant security and state corruption risks.

4. **Action Pinning**:
   - Most GitHub Actions (`actions/checkout@v4`, `actions/setup-node@v4`, `DeterminateSystems/nix-installer-action@v14`, `sigstore/cosign-installer@v3.8.1`, `docker/login-action@v3`, etc.) are pinned to mutable tags rather than immutable commit SHAs.

5. **Inline Scripts & Context Injection**:
   - Composite actions (`pr-lock`, `pr-unlock`, `tf-plan`, `tf-apply`) contain multiline inline bash scripts.
   - Script steps interpolate GitHub context variables directly into bash strings (e.g., `${{ github.event.pull_request.number }}`), which violates the repository's `policies/ci/inline_scripts.rego` policy and creates script injection risks.

---

## 2. Proposed CI Optimization Plan: "What, When, and Where"

### A. What to Run (Granularity & Filtering)

| Subsystem | What Runs on PR | What Runs on Main / Release | What is Skipped |
| :--- | :--- | :--- | :--- |
| **Linters & Policies** | Fast syntax check: yamllint, shellcheck, conftest (Rego policies) | Same (fail-fast gate) | Skip if only docs changed |
| **BATS Tests** | `./bin/ci/lib/run-bats-tests.sh` | Same | Skip if no changes in `bin/**` |
| **Ansible** | `ansible-lint` syntax validation | Deployment to target env (`docker-swarm`) via tag / approved workflow_dispatch | Never deploy unreviewed PRs |
| **Flux & Kubernetes** | Kind cluster validation (`flux-test.yml`) | OCI artifact build & push with semver tag + latest | Never push to GHCR on PR |
| **Docker Images** | Docker build without registry push (`push: false`) | Build & push to GHCR (`push: true`) + cosign sign | Skip push and signing on PR |
| **Website** | Hugo build validation (no pages artifact upload) | Hugo build + upload-pages-artifact + deploy-pages | Skip when non-website files change |
| **Python & Stacks** | Lint & unit tests (dry-run) | Changeset version bump + PyPI/Release artifact upload | Skip publish on PR |

### B. When to Run (Lifecycle, Concurrency & Gating)

1. **Concurrency Control**:
   - Standardize all PR workflows to cancel in-progress runs when new commits are pushed:
     ```yaml
     concurrency:
       group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
       cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}
     ```
   - For website builds, isolate PR concurrency groups (`group: website-${{ github.ref }}`) so PR builds do not block the production `"pages"` deployment queue.

2. **Trigger Cleanup**:
   - Restrict `pull_request` types to `[opened, synchronize, reopened]`, completely removing `edited`.
   - Add path filtering and ignore lists across all jobs:
     ```yaml
     paths-ignore:
       - 'docs/**'
       - '**.md'
       - '.articles/**'
     ```

3. **Stage Ordering & Fail Fast**:
   - Stage 1: Fast static analysis (<30s): Yaml lint, Shellcheck, Conftest policies.
   - Stage 2: Unit tests / package builds (~1-2m).
   - Stage 3: Heavy integration tests (e.g. Kind cluster bootstrap, only if Kubernetes manifests changed).
   - Stage 4: Post-merge publish & deployment (only on `main` or release tags).

### C. Where to Run (Runner Selection & Environment Isolation)

1. **Nix Runner Optimization**:
   - In `bin/nix/common.nix`, add `if [ -z "${CI:-}" ]; then` around interactive hooks (`tenv tf install`, `pre-commit install --install-hooks`, dynamic `pip install`, `ansible-galaxy install`).
   - Use specific Nix dev shells (`.#ansible`, `.#flux`, `.#docs`) rather than `.#full` or `.#default`.
2. **Native Runners for Docker & Node**:
   - Run Docker builds directly on GitHub runner using standard `docker/setup-buildx-action` and `cosign-installer` without Nix.
   - Run Changesets on Node 20 with Yarn caching without Nix.
3. **Artifact Retention**:
   - Limit all CI debug artifacts and test outputs to `retention-days: 7` (or `1` for temporary PR artifacts).

---

## 3. CI Security Best Practices & Rego Policy Suite

We propose a comprehensive Rego policy suite located in `policies/ci/` evaluated using **Conftest**:

```
policies/ci/
├── no_inline_scripts.rego     # Denies multiline inline scripts (forces bin/ci/)
├── enforce_permissions.rego   # Enforces explicit, least-privilege permissions
├── enforce_concurrency.rego   # Enforces concurrency with cancel-in-progress on PRs
├── no_pr_publish.rego         # Denies push/publish actions on pull_request events
├── no_script_injection.rego   # Flags expression interpolation (${{ ... }}) in bash scripts
├── limit_retention.rego       # Requires retention-days on upload-artifact
└── pin_actions.rego           # Checks for action pinning (SHA or approved versions)
```

### Automated Policy Enforcement in CI
Create a dedicated, fast workflow `.github/workflows/ci-policies.yml`:
- Runs on every PR and push.
- Runs Conftest against all `.github/workflows/*.yml` and `.github/actions/**/action.y*ml`.
- Fast execution (<15 seconds), zero cost, catches regressions immediately.

---

## 4. Implementation Status & Verification Results

### Completed Changes
- **Nix Optimization**: Added `if [ -z "${CI:-}" ]; then` to `bin/nix/common.nix`, preventing redundant `tenv`, `pip`, `ansible-galaxy`, and `pre-commit` setup runs across all CI steps. Added `conftest` to `basePackages`.
- **Docker Workflow Optimization**: Stripped Nix installation and defaults from `.github/workflows/release-docker.yml`, using native GitHub runner and actions.
- **Trigger Hardening**: Removed `edited` event type triggers from `.github/workflows/website.yml` and `.github/workflows/ansible-play-docker-swarm.yml`. Fixed dead path `.github/workflows/ansible.yml`.
- **Security Policy Suite (`policies/ci/`)**:
  - `inline_scripts.rego`: Modernized to Rego v1 to forbid multiline scripts in workflow YAML.
  - `enforce_permissions.rego`: Enforces explicit top-level or job-level least-privilege permissions, denies `write-all`.
  - `enforce_concurrency.rego`: Enforces concurrency groups with `cancel-in-progress: true` (or dynamic PR condition).
  - `no_pr_publish.rego`: Forbids pushing/publishing artifacts to registries on `pull_request` events.
  - `no_script_injection.rego`: Detects untrusted GitHub context expression interpolation in shell commands.
  - `limit_retention.rego`: Enforces explicit `retention-days` on `actions/upload-artifact`.
- **Automated Policy Enforcement**: Added `.github/workflows/ci-policies.yml` to automatically lint all workflows against the Rego policy suite.
- **Workflow Remediations**:
  - `.github/workflows/flux-oci-publish.yml`: Removed `pull_request` trigger to eliminate unreviewed GHCR `:latest` pushes. Added concurrency and GitHub `environment:` tracking (`cluster-k3s`, `cluster-kind`, `cluster-infra-addons`) for first-class deployment visibility and protection rules.
  - `.github/workflows/flux-test.yml`: Added concurrency with `cancel-in-progress: true`, explicit permissions.
  - `.github/workflows/bats.yml`: Added concurrency with `cancel-in-progress: true`.
  - `.github/workflows/docker-caddy-publish.yml` & `docker-openziti-bootstrap-publish.yml`: Added `cancel-in-progress` and permissions.
  - `.github/workflows/website.yml`: Isolated PR concurrency from pages deploy queue, restricted permissions, added conditional upload and artifact retention.
  - `.github/workflows/ansible-play-docker-swarm.yml`: Decoupled PR lint validation from live deployment to `docker_swarm`, eliminated redundant standalone `lock` job.
  - `.github/workflows/release-changeset.yml` & `release-kubernetes.yml`: Added explicit permissions.

### Verification Results
- **Conftest Policy Suite**: `160 tests, 160 passed, 0 warnings, 0 failures, 0 exceptions`.
- **YAML Linter (`yamllint`)**: Passed with 0 errors across all workflow files.
- **Nix Shell Execution (`CI=true`)**: Evaluates instantly with 0 interactive hooks triggered.

