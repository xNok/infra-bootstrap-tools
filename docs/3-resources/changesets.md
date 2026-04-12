---
type: resource
description: Automated versioning and changelog management for monorepos with an emphasis on human intent.
related_projects:
  - changeset-release-mgmt
  - agentic-framework
  - docker-swarm-env
related_areas:
  - developer-experience
---

# Changesets

## Overview

Changesets is a tool designed to manage versioning and changelogs in monorepos. Unlike tools that rely solely on parsing commit messages (like `semantic-release`), Changesets uses small, temporary markdown files to record a developer's intent regarding a future release. This ensures that changelogs are human-readable and that version bumps are deliberate.

## Key Features

- **Intent-Based**: Developers explicitly choose the version bump type (major, minor, patch) and write the changelog entry at the time of the change.
- **Monorepo First**: Excellent support for multiple packages within a single repository, handling internal dependency updates automatically.
- **Asynchronous Workflow**: Changesets are committed with the code but not "consumed" until the release phase.
- **Automated Version PRs**: The Changesets GitHub Action automatically creates and updates a "Version Packages" PR that aggregates all pending changes.
- **Polyglot Support**: While written in Node.js, it can manage any project that uses a `package.json` for metadata, including Ansible collections and Python packages.

## Core Workflow

### 1. Adding a Change
When a developer completes a task, they run:
```bash
npx changeset add
```
They select the affected packages, the bump type, and provide a summary. This creates a `.md` file in the `.changeset/` directory.

### 2. The Versioning Phase
When ready to release, the pending changesets are "consumed":
```bash
npx changeset version
```
This updates the `package.json` files and prepends entries to `CHANGELOG.md` files. In this project, this is handled automatically via a GitHub Action that opens a PR.

### 3. The Publish Phase
Once the version PR is merged, the packages are published:
```bash
npx changeset publish
```
In our polyglot setup, we use `changeset publish` to generate Git tags, which then trigger specialized GitHub workflows for Ansible Galaxy, Python/PyPI, or Docker Stack zipping.

## Use in This Project

We use Changesets to coordinate releases across three distinct ecosystems:

- **Ansible**: Managed via `ansible/package.json`. Triggers `v*` tags.
- **Python (Agentic)**: Managed via `agentic/package.json`. Triggers `infra-bootstrap-tools-agentic@*` tags.
- **Docker Stacks**: Managed via `stacks/package.json`. Triggers `infra-bootstrap-tools-stacks@*` tags.

## Configuration Highlights

Our configuration in `.changeset/config.json` includes:
- `privatePackages.tag: true`: Ensures that even packages marked as private (not for npm) get Git tags for our custom CI triggers.
- `access: "restricted"`: Prevents accidental publishing to the public npm registry.
- `baseBranch`: Set to `main`.

## Common Commands

```bash
# Record a new change
npx changeset add

# Check status of pending changes
npx changeset status

# Preview version bumps without consuming changesets
npx changeset version --snapshot
```

## Resources

### Internal Documentation
- [Changeset Release Management Project](../1-projects/changeset-release-mgmt.md)
- [Root RELEASE.md](../../RELEASE.md)
- [Blog: Intentional Releases](../../website/content/en/blog/intentional-releases-changesets.md)

### External Links
- [Official Changesets Repository](https://github.com/changesets/changesets)
- [Changesets Documentation](https://github.com/changesets/changesets/blob/main/docs/README.md)

## Related Resources

- [Nix](./nix.md) - Provides the Node.js environment needed to run Changesets.
- [Developer Experience Area](../2-areas/developer-experience.md) - The primary context for release automation.
