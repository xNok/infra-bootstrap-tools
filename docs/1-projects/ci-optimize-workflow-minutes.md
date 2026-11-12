# CI Workflow Minutes Optimization

Investigation and plan to reduce GitHub Actions minute consumption across the repository.

## Problem Statement
The repository accumulated over 1,300 runner minutes in 11 days (over 300 runs), causing GitHub Actions to stall in the `queued` state due to spending limits.

## Key Findings & Bottlenecks
1. **Lack of `concurrency` cancellation**:
   - Workflows (`flux-test.yml`, `flux-oci-publish.yml`, `conftest.yml`, `bats.yml`) do not define concurrency groups.
   - Every push to an open PR executes the entire test suite sequentially instead of canceling superseded runs.
2. **Missing path filters on `conftest.yml`**:
   - Triggers on every push and PR without `paths` or `paths-ignore`, spinning up Nix even for markdown/documentation edits.
3. **Matrix fan-out in `flux-oci-publish.yml`**:
   - Runs 4 separate VM jobs (`publish-fleet [kind]`, `publish-fleet [k3s]`, `publish-infra-addons`, `publish-apps`), multiplying runner minutes by 4 per run.
   - Runs on PRs as well as pushes.
4. **`ansible-play-docker-swarm.yml` triggers on PR `edited`**:
   - `types: [opened, edited, ready_for_review, synchronize]` with `cancel-in-progress: false` triggers a full Ansible run whenever a PR title or description is updated.

## Action Plan
1. Add `concurrency` with `cancel-in-progress: true` across all PR-facing workflows:
   - `flux-test.yml`
   - `flux-oci-publish.yml`
   - `conftest.yml`
   - `bats.yml`
   - Update `ansible-play-docker-swarm.yml` to `cancel-in-progress: true`.
2. Add `paths-ignore` for documentation and non-code files in `conftest.yml`:
   - Ignore `docs/**`, `website/**`, `*.md`, `.github/workflows/**` (unless conftest policies are affected).
3. Remove `edited` trigger from `ansible-play-docker-swarm.yml`.
4. Consolidate `flux-oci-publish.yml`:
   - Combine the 4 separate jobs into a single runner job that publishes all artifacts sequentially. This saves 3 separate Nix setups and VM allocations per run.
5. Create changeset and verify.
