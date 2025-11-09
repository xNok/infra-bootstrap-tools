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
   - A custom script then detects all versioned packages and creates git tags for them (e.g., `infra-bootstrap-tools-agentic@0.1.1`)
   - **GitHub Releases are created automatically** for each tag with the corresponding changelog content

## Why This Custom Approach?

Since all packages in this repository are marked as `"private": true`, they should not be published to npm. The standard `changeset publish` command is designed for npm publishing and only creates git tags as a side effect of publishing packages. When all packages are private, `changeset publish` skips them entirely and doesn't create any tags or releases.

To solve this, we use a custom workflow step that:
1. Detects when a "Version Packages" PR has been merged (no changesets remain, no hasChangesets output)
2. Scans all package.json files to find packages with CHANGELOG.md files
3. Creates git tags for each package version that doesn't already have a tag
4. Creates GitHub releases from those tags using the changelog content

This approach gives us the benefits of Changesets for version management while properly handling private packages.

## Custom Publishing

For packages like the Ansible collection that need custom publishing (e.g., to Ansible Galaxy), there is a separate workflow (`.github/workflows/ansible-collection-publish.yml`) that:
- Triggers on git tags (e.g., `v*`)
- Publishes the Ansible collection to Galaxy
- Uploads the collection tarball to the GitHub release

This gives us the best of both worlds:
- Automated version management and GitHub releases via Changesets
- Custom publishing workflows for specific packages
