---
type: project
status: active
description: Automated release management and versioning for all projects using Changesets, extending beyond just Node.js
related_projects:
  - agentic-framework
  - docker-swarm-env
  - n8n-workflows
  - openziti-mesh
related_resources:
  - changesets
related_areas:
  - developer-experience
---

# Changeset - Release Management

## Overview

The Changeset Release Management project implements automated version management and release workflows for the entire infra-bootstrap-tools monorepo. It extends the Changesets tool beyond its typical Node.js use case to manage releases for diverse package types including Ansible collections, Python packages, and Docker stacks.

## Current State

**Status**: Active / Production  
**Version**: Mature (using @changesets/cli ^2.27.3)  
**Last Updated**: January 2025

System Status:
- ✅ **Core Workflow**: Fully functional
- ✅ **Version Packages PR**: Automated
- ✅ **GitHub Releases**: Automated creation
- ✅ **Multiple Package Types**: Ansible, Python, Stacks
- ✅ **Custom Publishing**: Specialized workflows per package type
- ✅ **Documentation**: Complete (RELEASE.md)

## Key Files and Directories

### Configuration
```
.changeset/
├── README.md              # Process documentation
├── config.json            # Changeset configuration
├── terraform-gcp-role.md  # Example changeset
└── *.md                   # Pending changesets

package.json               # Root package with workspaces
```

### Workflow Files
```
.github/workflows/
├── changesets.yml                    # Main Changeset workflow
├── ansible-collection-publish.yml    # Ansible Galaxy publishing
├── python-package-publish.yml        # Python package publishing
└── stacks-package-release.yml        # Docker stacks packaging
```

### Package Metadata
```
Managed Packages:
├── ansible/package.json              # Ansible collection (xnok.infra_bootstrap_tools)
├── agentic/package.json              # Python package (infra-bootstrap-tools-agentic)
├── stacks/package.json               # Stacks bundle (infra-bootstrap-tools-stacks)
├── stacks/n8n/package.json          # Individual stack versions
├── stacks/prefect/package.json
├── stacks/openziti/package.json
└── ansible/roles/*/package.json     # Individual role versions
```

### Documentation
```
RELEASE.md                 # Complete release process documentation
.changeset/README.md       # Quick reference
```

## Architecture

### Workflow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Developer Workflow                            │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
                   ┌────────────────────┐
                   │  Create Changeset  │
                   │  (npx changeset)   │
                   └─────────┬──────────┘
                             │
                             ▼
                   ┌────────────────────┐
                   │  Open Pull Request │
                   └─────────┬──────────┘
                             │
                             ▼
                   ┌────────────────────┐
                   │  Merge to Main     │
                   └─────────┬──────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Automated Changeset Action                          │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Create/Update "Version Packages" PR                      │  │
│  │  - Bump versions in package.json files                    │  │
│  │  - Update CHANGELOG.md files                              │  │
│  │  - Remove consumed changeset files                        │  │
│  └────────────────────────┬─────────────────────────────────┘  │
└────────────────────────────┼────────────────────────────────────┘
                             │
                   ┌─────────▼──────────┐
                   │  Review & Merge    │
                   │  Version Packages  │
                   └─────────┬──────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Changeset Publish Action                            │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Run: changeset publish                                   │  │
│  │  - Skip npm publish (private packages)                    │  │
│  │  - Create git tags (privatePackages.tag: true)            │  │
│  │  - Push tags to GitHub                                    │  │
│  │  - Create GitHub Releases with changelog                  │  │
│  └────────────────────────┬─────────────────────────────────┘  │
└────────────────────────────┼────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│           Package-Specific Publishing Workflows                  │
│                                                                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────┐  │
│  │  Ansible Galaxy  │  │  Python Package  │  │   Stacks    │  │
│  │   Publishing     │  │   Publishing     │  │  Packaging  │  │
│  │                  │  │                  │  │             │  │
│  │ Trigger: v*      │  │ Trigger: *@*     │  │ Trigger:*@* │  │
│  │ Action: Build    │  │ Action: Build    │  │ Action: Zip │  │
│  │   + Publish      │  │   + Upload       │  │   + Upload  │  │
│  └──────────────────┘  └──────────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Tag Strategy

Different packages use different tagging conventions:

| Package Type | Tag Format | Example | Trigger |
|--------------|------------|---------|---------|
| **Root (Ansible)** | `v{version}` | `v1.0.0` | Root version bump |
| **Python (Agentic)** | `{name}@{version}` | `infra-bootstrap-tools-agentic@0.1.1` | Agentic version bump |
| **Stacks Bundle** | `{name}@{version}` | `infra-bootstrap-tools-stacks@1.0.3` | Stacks version bump |

## Resources and Dependencies

### Core Tools
- **@changesets/cli**: Version management tool
- **GitHub Actions**: Workflow automation
- **Node.js/npm**: Package management and workspaces
- **Git**: Version control and tagging

### Publishing Tools (Per Package Type)
- **Ansible Galaxy**: For Ansible collection
- **Python Build**: For Python packages (wheel, sdist)
- **Zip**: For stack archives
- **GitHub CLI**: For release management

### GitHub Permissions Required
- Contents: Write (for tags and releases)
- Pull Requests: Write (for Version Packages PR)
- Actions: Read (for workflow status)

## Package Types and Publishing

### 1. Ansible Collection

**Package**: `xnok.infra_bootstrap_tools`  
**Published To**: Ansible Galaxy  
**Workflow**: `.github/workflows/ansible-collection-publish.yml`

**Process:**
1. Triggered by tag `v*` (e.g., `v1.0.0`)
2. Builds collection tarball from `ansible/` directory
3. Publishes to Ansible Galaxy using API key
4. Uploads tarball to GitHub Release

**Installation:**
```bash
ansible-galaxy collection install xnok.infra_bootstrap_tools
```

### 2. Python Package (Agentic)

**Package**: `infra-bootstrap-tools-agentic`  
**Published To**: GitHub Releases  
**Workflow**: `.github/workflows/python-package-publish.yml`

**Process:**
1. Triggered by release tag `infra-bootstrap-tools-agentic@*`
2. Builds wheel and source distribution
3. Uploads to GitHub Release assets

**Installation:**
```bash
pip install https://github.com/xNok/infra-bootstrap-tools/releases/download/infra-bootstrap-tools-agentic@0.1.1/infra_bootstrap_tools_agentic-0.1.1-py3-none-any.whl
```

### 3. Docker Stacks

**Package**: `infra-bootstrap-tools-stacks`  
**Published To**: GitHub Releases  
**Workflow**: `.github/workflows/stacks-package-release.yml`

**Process:**
1. Triggered by release tag `infra-bootstrap-tools-stacks@*`
2. Creates individual stack zip archives
3. Creates complete stacks bundle
4. Uploads all archives to GitHub Release

**Installation:**
```bash
wget https://github.com/xNok/infra-bootstrap-tools/releases/download/infra-bootstrap-tools-stacks@1.0.3/infra-bootstrap-tools-stacks-1.0.3.zip
unzip infra-bootstrap-tools-stacks-1.0.3.zip
```

### 4. NPM Packages (Roles and Individual Stacks)

**Status**: Private (not published)  
**Purpose**: Version tracking and changelog generation only

All individual roles and stacks are marked `"private": true` in their `package.json` files. They are:
- Versioned by Changesets
- Get changelog entries
- Not published to npm
- Not tagged individually

## Developer Workflow

### Step 1: Create a Changeset

When making changes to any package:

```bash
npx changeset add
```

Follow the prompts:
1. **Select packages**: Choose which packages are affected
2. **Bump type**: Select major, minor, or patch
3. **Summary**: Write a clear description of changes

This creates a file in `.changeset/` like:

```markdown
---
"infra-bootstrap-tools-agentic": minor
"infra-bootstrap-tools-stacks": patch
---

Add new workflow automation feature and update stack configurations
```

### Step 2: Commit and Open PR

```bash
git add .changeset/
git commit -m "Add changeset for new feature"
git push origin feature-branch
# Open PR on GitHub
```

### Step 3: Review and Merge

- Code review happens normally
- Changeset file is included in the PR
- Merge when approved

### Step 4: Automatic Version PR

After merge to `main`:
- Changesets bot creates/updates "Version Packages" PR
- PR contains:
  - Version bumps in `package.json` files
  - Updated `CHANGELOG.md` files
  - Removed changeset files

### Step 5: Release

When ready to release:
1. Review and merge "Version Packages" PR
2. Changesets automatically:
   - Creates git tags
   - Creates GitHub Releases
   - Triggers publishing workflows

## Configuration

### Changesets Config (`.changeset/config.json`)

```json
{
  "$schema": "https://unpkg.com/@changesets/config@3.0.0/schema.json",
  "changelog": "@changesets/cli/changelog",
  "commit": false,
  "fixed": [],
  "linked": [],
  "access": "restricted",
  "baseBranch": "main",
  "updateInternalDependencies": "patch",
  "ignore": [],
  "privatePackages": {
    "version": true,
    "tag": true
  },
  "___experimentalUnsafeOptions_WILL_CHANGE_IN_PATCH": {
    "onlyUpdatePeerDependentsWhenOutOfRange": true
  }
}
```

**Key Settings:**
- `privatePackages.tag: true` - Create tags for private packages
- `baseBranch: "main"` - PR target branch
- `access: "restricted"` - Don't publish to npm
- `commit: false` - Don't auto-commit changesets

### Workspaces Configuration (`package.json`)

```json
{
  "private": true,
  "name": "infra-bootstrap-tools",
  "workspaces": [
    "agentic",
    "ansible",
    "ansible/roles/*",
    "stacks",
    "stacks/*"
  ]
}
```

## Use Cases

### Single Package Release
```bash
# Add changeset for one package
npx changeset add
# Select only "infra-bootstrap-tools-agentic"
# Choose "patch" for bug fix
# Write: "Fix authentication issue in Jules workflow"
```

### Multi-Package Release
```bash
# Add changeset affecting multiple packages
npx changeset add
# Select "infra-bootstrap-tools-agentic" and "infra-bootstrap-tools-stacks"
# Choose appropriate bump types
# Write: "Add MCP Hub integration to both packages"
```

### Breaking Change
```bash
# Add changeset with major bump
npx changeset add
# Select affected package
# Choose "major" for breaking change
# Write: "BREAKING: Remove deprecated configuration options"
```

### Documentation Update (No Release)
No changeset needed for:
- Documentation-only changes
- README updates
- Comment additions
- Test-only changes

## Known Issues and Limitations

### Current Limitations
1. **npm Publishing Workaround**: Using private packages with tagging instead of direct npm support
2. **Manual GitHub Release Editing**: Release notes may need manual cleanup
3. **No PyPI Publishing**: Python packages only on GitHub Releases
4. **Individual Roles Not Tagged**: Only parent packages get tags

### Workarounds
1. **Custom Publishing Workflows**: Separate workflows for each package type
2. **GitHub Releases**: Use as distribution mechanism
3. **Manual Installation**: Users install from GitHub URLs

## Comparison with Alternatives

| Tool | Changesets | Semantic Release | Lerna | Release-It |
|------|------------|------------------|-------|------------|
| **Monorepo** | ✅ Excellent | ⚠️ Good | ✅ Excellent | ❌ Limited |
| **Manual Control** | ✅ Yes | ❌ No | ✅ Yes | ✅ Yes |
| **CI Integration** | ✅ Simple | ✅ Simple | ⚠️ Complex | ✅ Simple |
| **Version PRs** | ✅ Yes | ❌ No | ❌ No | ❌ No |
| **Private Packages** | ✅ Yes | ⚠️ Workaround | ✅ Yes | ⚠️ Limited |
| **Learning Curve** | Low | Medium | High | Low |

**Why Changesets?**
- Explicit changelog intent (changeset files)
- Version Packages PR for review
- Works well with private packages
- Simple GitHub Actions integration
- Growing community adoption

## Best Practices

### Writing Good Changesets

**Do:**
- ✅ Use clear, user-facing language
- ✅ Explain the impact of changes
- ✅ Reference issues/PRs if relevant
- ✅ Choose appropriate bump types

**Don't:**
- ❌ Use technical jargon
- ❌ Write vague descriptions
- ❌ Skip changesets for user-facing changes
- ❌ Batch unrelated changes

### Example Good Changeset

```markdown
---
"infra-bootstrap-tools-agentic": minor
---

Add support for OpenAI GPT-4o model in Jules workflow. You can now set
`LLM_MODEL=openai:gpt-4o` in your environment to use GPT-4o instead of
the default Gemini model. Requires `OPENAI_API_KEY` to be set.
```

### Example Bad Changeset

```markdown
---
"infra-bootstrap-tools-agentic": patch
---

Updated code
```

## Troubleshooting

### Version PR Not Created
- Check that changeset files are properly formatted
- Verify package names match `package.json`
- Ensure Changesets action ran on main branch
- Check workflow logs in GitHub Actions

### Workflow Not Triggering
- Verify release tag format matches trigger pattern
- Check workflow YAML syntax (use yamllint)
- Verify repository permissions
- Check workflow is enabled

### Package Build Failure
- Review workflow logs for errors
- Test build locally before pushing
- Check all dependencies are specified
- Verify build scripts are correct

## Planned Improvements

### Short Term
1. **Better Release Notes**: Template for GitHub Releases
2. **Validation**: Pre-commit hook for changeset format
3. **Documentation**: Video walkthrough of process
4. **Testing**: Automated testing of publishing workflows

### Long Term
1. **PyPI Publishing**: Publish Python packages to PyPI
2. **Helm Charts**: Add Helm chart versioning
3. **Container Images**: Version and publish Docker images
4. **Dependency Updates**: Automate dependency changesets
5. **Analytics**: Track release metrics and adoption

## Documentation Links

- [Main Release Documentation](../../RELEASE.md) - Complete guide
- [Changeset README](.changeset/README.md) - Quick reference
- [Changesets Documentation](https://github.com/changesets/changesets) - Official docs
- [GitHub Actions](https://docs.github.com/en/actions) - Workflow documentation

## Related Projects

All projects in the monorepo use this release system:
- **agentic-framework**: Python package releases
- **docker-swarm-env**: Ansible collection releases
- **n8n-workflows**: Stack bundle releases
- **openziti-mesh**: Stack bundle releases

## Next Steps

1. **Document Edge Cases**: Handle complex versioning scenarios
2. **Automate Testing**: Test publishing workflows in PRs
3. **Improve Release Notes**: Better formatting and categorization
4. **PyPI Integration**: Investigate PyPI publishing options
5. **Metrics Dashboard**: Track releases and adoption
6. **Video Tutorial**: Screen recording of full release process
7. **Template Expansion**: More changeset templates for common scenarios
