---
title: "Changesets: Intentional Monorepo Release Management"
slug: changesets
description: "How infra-bootstrap-tools coordinates versioning and changelogs across polyglot monorepo packages using Changesets."
tags:
  - release-management
  - monorepo
  - changesets
  - ci-cd
  - automation
---

## What is Changesets?

[Changesets](https://github.com/changesets/changesets) is a versioning and changelog tool designed specifically for monorepos.

Unlike tools that rely on parsing git commit messages (such as `semantic-release` or conventional commits), Changesets uses small, temporary Markdown files to capture a developer's **explicit intent** at the time code is written. This guarantees that changelogs are human-readable, context-rich, and that version bumps (major, minor, patch) are intentional.

---

## Why Changesets for a Polyglot Monorepo?

`infra-bootstrap-tools` contains packages across multiple ecosystems that are released independently:
1. **Ansible Collection**: `ansible/` (`xnok.infra_bootstrap_tools`, published to Ansible Galaxy).
2. **Python Agentic Framework**: `agentic/` (Python libraries and workflow runners).
3. **Docker Stacks**: `stacks/` (packaged Docker Compose bundles).

Even though Changesets is written in TypeScript/Node.js, it operates on standard `package.json` metadata files. By placing a lightweight `package.json` inside each subsystem, Changesets coordinates independent releases across our entire polyglot codebase with zero friction.

---

## The Developer Workflow

The Changesets workflow standardizes release management into 5 predictable steps:

1. **Developer completes a feature or fix** in a branch or worktree.
2. **Runs `npx changeset add`**:
   - Interactive prompt: Select package(s) affected (`ansible-collection`, `agentic`, `stacks`).
   - Interactive prompt: Select version bump type (`patch`, `minor`, `major`).
   - Interactive prompt: Enter a clear human summary for the changelog.
3. **Commit the changeset file** (`.changeset/<random-slug>.md`) alongside code changes and open a Pull Request.
4. **PR merged to `main`**:
   - GitHub Actions parses all pending changesets and creates/updates a standing **"Version Packages"** PR with auto-generated CHANGELOG entries.
5. **Release Trigger**:
   - When maintainers merge the "Version Packages" PR, git tags (e.g. `v1.2.0`) are published and CI triggers release distribution.

### 1. Adding a Change
When your changes are ready to commit, run:
```bash
npx changeset add
```
Changesets prompts you to select the packages you touched, choose the semver impact (`patch`, `minor`, `major`), and provide a clear, user-facing changelog summary. A markdown file is generated in `.changeset/` that lives with your PR.

### 2. The Versioning Phase
When PRs merge into `main`, the Changesets GitHub Action automatically opens (or updates) an aggregated **"Version Packages"** pull request. This PR:
- Bumps package versions in each affected `package.json`.
- Appends changelog entries to each package's `CHANGELOG.md`.
- Deletes the consumed changeset markdown files.

### 3. The Publish Phase
When the maintainer merges the "Version Packages" PR, the GitHub workflow runs:
```bash
npx changeset publish
```
This generates Git tags (e.g. `ansible-collection-infra-bootstrap-tools@1.2.0`), which in turn trigger specialized release workflows to build tarballs, run linters, and publish to registries.

---

## Configuration Highlights

Our configuration lives in `.changeset/config.json`:
- **`privatePackages.tag: true`**: Ensures packages marked private generate Git tags to trigger our internal CI pipelines.
- **`access: "restricted"`**: Prevents accidental publishing to public npm registries.
- **`baseBranch: "main"`**: Reconciles changesets relative to our primary trunk branch.

---

## Common Commands

```bash
# Record a new change interactively:
npx changeset add

# View pending unreleased changes:
npx changeset status

# Preview version bumps and changelogs without modifying Git:
npx changeset version --snapshot
```
