---
title: "Edge Cases"
parent: "changeset-release-mgmt.md"
---

# Edge Cases in Version Management

As our monorepo expands across multiple technologies and target registries, we face several versioning edge cases that must be handled gracefully by Changesets and our GitHub workflows.

## 1. Divergent Tag Formats
Changesets natively produces `workspace-name@version` tags (e.g. `ansible@1.0.0`). However, Ansible Galaxy conventionally relies on standard Semantic Versioning `vX.Y.Z` without prefixes if it's the only collection in a repo. Similarly, Docker containers are often tagged `latest` and `vX.Y.Z`.
**Resolution**: If we have multiple Ansible collections or multiple Docker images, we must strictly adhere to the Changesets `workspace@version` prefix to isolate releases. Workflows must strip the prefix (e.g., `VERSION=${TAG#*@}`) before passing the raw `X.Y.Z` string to PyPI/Galaxy.

## 2. Shared Dependencies
If `stacks-package` depends on a specific version of `ansible-collection` locally, changesets will update the internal dependencies in `package.json`. However, since these packages are not actually published to NPM, resolving those dependencies when users download them via GitHub Releases or ZIP files requires careful documentation or external scripting (like `requirements.yml` for Ansible).
**Resolution**: Ensure Changesets only bumps the *version strings* in `package.json` for Changelog generation, and use a separate manifest (`galaxy.yml`, `pyproject.toml`) that is updated dynamically during the release workflow.

## 3. Prereleases (Alpha/Beta/RC)
Using `npx changeset pre enter alpha` generates prerelease versions (`1.0.0-alpha.1`).
**Resolution**: Workflows must recognize prerelease suffixes and push to test repositories (like TestPyPI) or tag Docker images with `-alpha` instead of `latest`. This requires conditionals (`if: contains(github.ref, '-alpha')`) within our reusable workflows.

## 4. Failed Publish Steps
If the GitHub Action fails *after* Changesets tags the repository (e.g., due to a PyPI token expiry or a temporary Galaxy outage), the tag exists, but the artifact is not published.
**Resolution**: The workflows should support `workflow_dispatch` with an input for the `release_tag`. This allows a maintainer to manually re-trigger the publish process for an existing tag after fixing the credential or resolving the outage, without generating a new version bump.
