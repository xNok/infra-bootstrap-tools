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
   - Git tags are created for each version (e.g., `infra-bootstrap-tools-agentic@0.1.1`) via the `privatePackages.tag: true` config
   - **GitHub Releases are created automatically** with the changelog content via the `createGithubReleases: true` option

## Configuration for Private Packages

This repository uses the `privatePackages` configuration option in `.changeset/config.json` to enable tagging of private packages:

```json
{
  "privatePackages": {
    "version": true,
    "tag": true
  }
}
```

- `version: true` - Allows private packages to be versioned (default behavior)
- `tag: true` - Creates git tags for private packages when `changeset publish` runs

With `tag: true`, `changeset publish` outputs "New tag:" lines for private packages, which the GitHub Action detects and uses to create GitHub releases. This is the built-in mechanism for handling private packages in monorepos.

## Why This Approach?

The standard `changeset publish` command is designed primarily for npm publishing. By default, it only creates git tags when actually publishing to npm. For private packages that shouldn't be published to npm, the `privatePackages.tag: true` option enables tag creation without publishing.

The changesets/action then:
- Detects the "New tag:" output from `changeset publish`
- Pushes the git tags to the repository
- Creates GitHub releases with changelog content

This is the recommended approach from the Changesets team for using Changesets with non-npm packages like Ansible collections, Docker stacks, and Python packages.

## Custom Publishing

For packages like the Ansible collection that need custom publishing (e.g., to Ansible Galaxy), there is a separate workflow (`.github/workflows/ansible-collection-publish.yml`) that:
- Triggers on git tags (e.g., `v*`)
- Publishes the Ansible collection to Galaxy
- Uploads the collection tarball to the GitHub release

This gives us the best of both worlds:
- Automated version management and GitHub releases via Changesets
- Custom publishing workflows for specific packages
