# Release Management for infra-bootstrap-tools Monorepo

This document describes the release process for the infra-bootstrap-tools monorepo, which contains multiple package types managed through [Changesets](https://github.com/changesets/changesets).

## Overview

The monorepo uses Changesets for version management and automated releases. Different package types have specialized publishing workflows that are triggered by Changeset releases.

## Package Types

### 1. Ansible Collection (`ansible/`)
- **Package Name**: `xnok.infra_bootstrap_tools`
- **Published To**: Ansible Galaxy
- **Workflow**: `.github/workflows/ansible-collection-publish.yml`
- **Trigger**: Git tags matching `v*` (e.g., `v1.0.0`)
- **Published By**: Ansible Galaxy publishing action

### 2. Python Package (`agentic/`)
- **Package Name**: `infra-bootstrap-tools-agentic`
- **Published To**: GitHub Releases (as wheel and source distribution)
- **Workflow**: `.github/workflows/python-package-publish.yml`
- **Trigger**: Releases with tags matching `infra-bootstrap-tools-agentic@*`
- **Published By**: Python build system, uploaded to GitHub Release

### 3. Docker Stacks (`stacks/`)
- **Package Name**: `infra-bootstrap-tools-stacks`
- **Published To**: GitHub Releases (as zip archives)
- **Workflow**: `.github/workflows/stacks-package-release.yml`
- **Trigger**: Releases with tags matching `infra-bootstrap-tools-stacks@*`
- **Published By**: Zip archives uploaded to GitHub Release

### 4. NPM Packages (Ansible roles and stacks)
- **Published To**: Not published (all marked as `"private": true`)
- **Purpose**: Version management and changelog generation only

## Release Process

### Step 1: Create a Changeset

When making changes to any package, create a changeset file to describe the changes:

```bash
npx changeset add
```

Follow the prompts to:
1. Select which packages are affected
2. Choose the version bump type (major, minor, or patch)
3. Write a summary of the changes

This creates a markdown file in `.changeset/` that will be committed with your changes.

**Example changeset file** (`.changeset/my-feature.md`):
```markdown
---
"infra-bootstrap-tools-agentic": minor
"infra-bootstrap-tools-stacks": patch
---

Add new workflow automation feature and update stack configurations
```

### Step 2: Open a Pull Request

Commit the changeset file along with your code changes and open a PR:

```bash
git add .changeset/my-feature.md
git commit -m "Add changeset for new feature"
git push origin your-branch
```

### Step 3: Merge to Main

When your PR is merged to `main`, the Changesets GitHub Action automatically:
1. Creates or updates a "Version Packages" PR
2. Bumps versions in `package.json` files
3. Updates `CHANGELOG.md` files
4. Removes consumed changeset files

### Step 4: Merge Version Packages PR

When the "Version Packages" PR is merged:
1. **Changeset publishes packages** (skips npm for private packages)
2. **Creates Git tags** for each released package:
   - Ansible: `v1.0.0` (root version)
   - Agentic: `infra-bootstrap-tools-agentic@0.1.1`
   - Stacks: `infra-bootstrap-tools-stacks@1.0.3`
3. **Creates GitHub Releases** with changelog content

### Step 5: Automated Package Publishing

After releases are created, specialized workflows automatically publish packages:

#### Ansible Collection
- **Workflow**: `.github/workflows/ansible-collection-publish.yml`
- **Triggers on**: Tag `v*` (e.g., `v1.0.0`)
- **Actions**:
  1. Builds Ansible collection tarball
  2. Publishes to Ansible Galaxy
  3. Uploads tarball to GitHub Release

#### Python Package
- **Workflow**: `.github/workflows/python-package-publish.yml`
- **Triggers on**: Release with tag `infra-bootstrap-tools-agentic@*`
- **Actions**:
  1. Builds Python wheel and source distribution
  2. Uploads packages to the GitHub Release

#### Docker Stacks
- **Workflow**: `.github/workflows/stacks-package-release.yml`
- **Triggers on**: Release with tag `infra-bootstrap-tools-stacks@*`
- **Actions**:
  1. Creates individual stack zip archives
  2. Creates complete stacks bundle zip
  3. Uploads all archives to the GitHub Release

## Manual Package Publishing

If automatic publishing fails or you need to manually publish a package, you can trigger the workflows manually:

### Ansible Collection
```bash
gh workflow run ansible-collection-publish.yml -f release_tag=v1.0.0
```

### Python Package
```bash
gh workflow run python-package-publish.yml -f release_tag=infra-bootstrap-tools-agentic@0.1.1
```

### Docker Stacks
```bash
gh workflow run stacks-package-release.yml -f release_tag=infra-bootstrap-tools-stacks@1.0.3
```

## Installation

### Ansible Collection
```bash
ansible-galaxy collection install xnok.infra_bootstrap_tools
```

### Python Package
```bash
pip install https://github.com/xNok/infra-bootstrap-tools/releases/download/infra-bootstrap-tools-agentic@0.1.1/infra_bootstrap_tools_agentic-0.1.1-py3-none-any.whl
```

### Docker Stacks
```bash
wget https://github.com/xNok/infra-bootstrap-tools/releases/download/infra-bootstrap-tools-stacks@1.0.3/infra-bootstrap-tools-stacks-1.0.3.zip
unzip infra-bootstrap-tools-stacks-1.0.3.zip
```

## Troubleshooting

### Changeset Not Creating Version PR
- Ensure changeset files are properly formatted
- Check that package names in changesets match `package.json` names
- Verify the Changesets action is running on push to main

### Workflow Not Triggering
- Check that the release tag format matches the workflow trigger pattern
- Verify the workflow file syntax is valid (use `yamllint`)
- Check workflow permissions in repository settings

### Package Build Failure
- Review workflow logs in GitHub Actions
- Test package building locally before pushing
- Ensure all dependencies are correctly specified

## Best Practices

1. **One changeset per feature**: Create separate changesets for different features
2. **Descriptive summaries**: Write clear changeset summaries that will appear in changelogs
3. **Semantic versioning**: Choose appropriate version bumps (major, minor, patch)
4. **Test before merging**: Ensure all tests pass before merging Version Packages PR
5. **Monitor workflows**: Check that automated publishing completes successfully

## References

- [Changesets Documentation](https://github.com/changesets/changesets)
- [Changesets GitHub Action](https://github.com/changesets/action)
- [Semantic Versioning](https://semver.org/)
