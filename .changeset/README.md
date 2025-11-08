# Changeset Release Process

This repository uses [Changesets](https://github.com/changesets/changesets) for version management and GitHub releases.

## How It Works

### For Developers

1. **Create a changeset** when you make changes:
   ```bash
   npx changeset add
   ```
   Follow the prompts to describe your changes and select which packages are affected.

2. **Commit the changeset file** along with your code changes.

3. **Open a Pull Request** with your changes.

### Automated Release Process

When a PR with changesets is merged to the `main` branch:

1. The **Changesets GitHub Action** will automatically:
   - Create or update a "Version Packages" PR that:
     - Bumps versions in `package.json` files
     - Updates `CHANGELOG.md` files
     - Removes consumed changeset files

2. When the "Version Packages" PR is merged:
   - The action runs `changeset publish`
   - Since all packages are marked as `"private": true`, they are **not** published to npm
   - Git tags are created for each version (e.g., `v1.0.5`)
   - **GitHub Releases are created automatically** with the changelog content

## Why Not `changeset tag`?

Previously, the repository used `changeset tag`, which only creates git tags but **does not** create GitHub releases. 

The current setup uses `changeset publish` with the `createGithubReleases: true` option, which:
- Skips npm publishing (because packages are private)
- Creates git tags
- **Creates GitHub releases** with changelog content

This is the recommended approach for using Changesets with non-npm packages like Ansible collections.

## Custom Publishing

For packages like the Ansible collection that need custom publishing (e.g., to Ansible Galaxy), there is a separate workflow (`.github/workflows/ansible-collection-publish.yml`) that:
- Triggers on git tags (e.g., `v*`)
- Publishes the Ansible collection to Galaxy
- Uploads the collection tarball to the GitHub release

This gives us the best of both worlds:
- Automated version management and GitHub releases via Changesets
- Custom publishing workflows for specific packages
