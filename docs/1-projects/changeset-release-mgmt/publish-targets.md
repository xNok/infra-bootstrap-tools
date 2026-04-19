---
title: "Publish Targets"
parent: "changeset-release-mgmt.md"
---

# Publish Targets with Changesets

The standard `changeset publish` command is inherently tied to the npm registry. For projects spanning multiple ecosystems (Ansible, Python, Docker, Helm, etc.), we circumvent this by using `changeset tag` (to generate tags without publishing) and relying on GitHub Actions to orchestrate the actual build and upload process to the appropriate registries based on those tags.

## 1. Ansible Collections (Ansible Galaxy)
- **Tag Format**: `vX.Y.Z` or `<package-name>@X.Y.Z`
- **Workflow Hook**: Triggered by `push: tags: - 'v*'` or equivalent regex.
- **Process**:
  1. Extract the version string from the Git tag.
  2. Dynamically update `ansible/galaxy.yml` using tools like `yq` (`yq -i ".version = \"$VERSION\""`).
  3. Build the tarball via `ansible-galaxy collection build`.
  4. Use the `artis3n/ansible_galaxy_collection` action to push to Ansible Galaxy, utilizing an API token (`GALAXY_API_KEY`).
- **Improvement Areas**: Currently hardcoded to `v*`. If multiple collections exist in the repo, consider a workspace-specific tag like `ansible-collection-name@X.Y.Z` to trigger individual releases.

## 2. Python Packages (PyPI / GitHub Releases)
- **Tag Format**: `<package-name>@X.Y.Z` (e.g., `infra-bootstrap-tools-agentic@0.1.1`)
- **Workflow Hook**: `release: types: [published]` or `push: tags: - '<package-name>@*'`
- **Process**:
  1. Extract version from the tag.
  2. Modify `pyproject.toml` using `sed` or Python scripts to set `version = "X.Y.Z"`.
  3. Build the wheel (`python -m build`).
  4. Upload `.whl` artifacts to the GitHub Release.
- **Improvement Areas**: Investigate PyPI Publishing via Trusted Publishing (OIDC). Instead of purely attaching wheels to GitHub Releases, we can use `pypa/gh-action-pypi-publish` to natively push to PyPI.

## 3. Docker Containers (GHCR / Docker Hub)
- **Tag Format**: `vX.Y.Z` or `<stack-name>@X.Y.Z`
- **Workflow Hook**: Often tied directly to pushing tags that match Semantic Versioning.
- **Process**:
  1. Use `docker/metadata-action` to generate Docker tags from the GitHub tag (e.g., stripping the `v` or the workspace prefix).
  2. Authenticate to the container registry (`docker/login-action`).
  3. Build and push multi-architecture images using `docker/build-push-action`.
- **Improvement Areas**: Consistency in tag matching. The OpenZiti bootstrap uses `tags: ['v*.*.*']`, which conflicts slightly if changesets generate `openziti-bootstrap@1.2.3`. We should align Docker triggers with Changesets' workspace tagging format.

## 4. Stack Archives (Zip Bundles)
- **Tag Format**: `infra-bootstrap-tools-stacks@X.Y.Z`
- **Workflow Hook**: `release: types: [published]`
- **Process**:
  1. Extract version from the tag.
  2. Zip relevant directories (excluding `node_modules`, `.git`).
  3. Attach zip files directly to the GitHub Release created by changesets.
- **Improvement Areas**: Abstracting the zipping process so other users can cleanly bundle arbitrary folder structures upon a tag.

## Key Takeaways
To improve the reusability of our GitHub Actions:
- We should decouple the "build" steps from the "publish" steps.
- We should standardize on the `<workspace-name>@<version>` tag format generated natively by changesets for all package types, avoiding global `v*` tags unless the entire monorepo is versioned together.
- We should leverage `workflow_call` reusable workflows that accept the target registry, artifact paths, and version strings as inputs.
