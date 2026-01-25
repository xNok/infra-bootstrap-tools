---
type: project
status: active
description: Core CLI and environment setup tool currently undergoing a refactor to use Nix for better reproducibility
related_projects:
  - docker-swarm-env
  - agentic-framework
  - n8n-workflows
related_resources:
  - nix
  - bash
  - docker
  - ansible
  - pre-commit
related_areas:
  - developer-experience
  - environment-management
---

# IBT (Infra Bootstrap Tools) & Nix Refactor

## Overview

IBT is the core command-line interface and environment setup tool for the infra-bootstrap-tools monorepo. It provides a unified interface to project scripts with subcommands and auto-completion. The project is currently undergoing a significant refactor to use Nix for better reproducibility and consistency.

## Current State

**Status**: Active Development / Refactoring  
**Last Updated**: January 2025

The project has two parallel implementations:
1. ✅ **Current (Bash-based)**: Functional and in use
2. 🔄 **Future (Nix-based)**: Active refactor in progress

### Bash Implementation Status
- ✅ Core `ibt` dispatcher with subcommands
- ✅ Tab completion system
- ✅ Setup script for tool installation
- ✅ Stacks management
- ✅ Docker-based tool aliases
- ✅ Comprehensive test suite

### Nix Implementation Status
- ✅ Nix Flakes configuration
- ✅ Traditional nix-shell support
- ✅ Automated dependency installation
- ✅ Python virtual environment management
- 🔄 Full feature parity with bash implementation
- 🔄 Documentation updates
- 🔄 Migration guide

## Key Files and Directories

### Bash Implementation
```
bin/bash/
├── ibt.sh                    # Main dispatcher and entry point
├── setup.sh                  # Tool installation script
├── stacks.sh                 # Stack management
├── tools.sh                  # Docker-based tool aliases
├── docker_tools_alias.sh     # Legacy tool aliases
├── completion-utils.sh       # Shared completion functions
├── ibt-completion.sh         # Main ibt completion
├── setup-completion.sh       # Setup subcommand completion
├── stacks-completion.sh      # Stacks subcommand completion
├── tools-completion.sh       # Tools subcommand completion
├── test_completion.sh        # Comprehensive test suite
├── IBT_SPEC.md              # Design specification
└── README.md                # Documentation
```

### Nix Implementation
```
bin/nix/
├── common.nix               # Shared Nix configuration
└── shell.nix                # Traditional nix-shell entry

flake.nix                    # Nix Flakes configuration (root)
```

### Configuration
```
requirements.txt             # Python dependencies
requirements.yml             # Ansible Galaxy dependencies
.pre-commit-config.yaml      # Pre-commit hooks
```

## Architecture

### Command Structure

```
ibt <subcommand> [options...]
```

**Subcommands:**
- `setup [tool ...]` - Install required tools and dependencies
- `stacks [args ...]` - Manage and run infrastructure stacks
- `tools [args ...]` - Use Docker-based aliases for infrastructure tools

### Completion System

```
┌─────────────────────────────────────────────────────────────┐
│                    ibt-completion.sh                         │
│         (Main completion handler for `ibt` command)          │
└──────────────────┬──────────────────────────────────────────┘
                   │
       ┌───────────┼───────────┐
       │           │           │
       ▼           ▼           ▼
┌──────────┐ ┌──────────┐ ┌──────────┐
│  setup-  │ │ stacks-  │ │ tools-   │
│completion│ │completion│ │completion│
└────┬─────┘ └────┬─────┘ └────┬─────┘
     │            │            │
     └────────────┴────────────┘
                  │
                  ▼
       ┌─────────────────────┐
       │  completion-utils.sh│
       │  (Shared utilities) │
       └─────────────────────┘
                  │
                  ▼
       ┌─────────────────────┐
       │  <subcommand>.sh    │
       │  --list-options     │
       └─────────────────────┘
```

### Design Principles

1. **Tool Wrapping**: Focus on wrapping existing tools with consistent interface
2. **Dynamic Completion**: Fetch completion data from actual scripts, not hardcoded
3. **Extensibility**: Easy to add new subcommands without modifying multiple files
4. **DRY**: Shared functionality extracted into reusable utilities

## Bash Implementation

### Core Features

#### 1. Unified Dispatcher (`ibt.sh`)
Main entry point providing consistent interface:
```bash
source ./bin/bash/ibt.sh
ibt setup pre-commit ansible
ibt stacks list
ibt tools dasb --version
```

#### 2. Setup Script (`setup.sh`)
Installs development dependencies:
- Python packages (from requirements.txt)
- Ansible Galaxy roles/collections (from requirements.yml)
- Pre-commit hooks
- 1Password CLI
- Additional tools as needed

**Supported Tools:**
- `pre-commit`
- `ansible`
- `1password-cli`
- `hugo`
- `go`
- `python`

#### 3. Stacks Management (`stacks.sh`)
Manages Docker Compose stacks:
```bash
# List available stacks
ibt stacks list

# Run a stack locally
ibt stacks run n8n local

# Run with multiple components
ibt stacks run prefect mcp-hub

# Direct invocation
./bin/bash/stacks.sh run openziti spire-stack
```

Features:
- Auto-detection of `.local.yaml` files
- Modular component composition
- Stack path configuration via env var

#### 4. Docker Tools (`tools.sh`)
Provides Docker-based tool aliases:
- `dasb` - Ansible in Docker
- `dap` - Ansible Playbook in Docker
- `daws` - AWS CLI in Docker
- `dpk` - Packer in Docker
- `dtf` - Terraform in Docker
- `dbash` - Bash in Docker

#### 5. Completion System
Intelligent tab completion:
- Dynamically fetches options via `--list-options`
- Subcommand-specific completion
- No hardcoded options (DRY principle)
- Comprehensive test coverage

### Testing
```bash
# Run completion tests
bash bin/bash/test_completion.sh
```

Tests verify:
- `--list-options` flag works
- Completion functions are defined
- Tab completion produces correct results
- No hardcoded options remain
- Multi-argument completion works

## Nix Implementation

### Nix Flakes (Recommended)

Modern, reproducible approach:

```bash
# Enable flakes (if not already enabled)
# Add to ~/.config/nix/nix.conf:
# experimental-features = nix-command flakes

# Enter development environment
nix develop
```

### Traditional Nix Shell

```bash
nix-shell bin/nix/shell.nix
```

### Automated Setup

Both Nix approaches automatically:
1. Install essential tools (Python, Ansible, Docker, Hugo, etc.)
2. Create Python virtual environment (`.venv`)
3. Install Python dependencies from `requirements.txt` and `agentic/requirements.txt`
4. Install Ansible Galaxy roles/collections from `requirements.yml`
5. Install pre-commit hooks

### Provided Tools

From `bin/nix/common.nix`:
- **python3** with pip
- **ansible**
- **1password-cli** (unfree package)
- **go**
- **hugo**
- **pre-commit**
- **git**
- **docker**

### Shell Hook

Automatic setup on environment entry:
```nix
shellHook = ''
  echo "Setting up development environment..."
  
  # Create and activate virtual environment
  if [ ! -d ".venv" ]; then
    python -m venv .venv
  fi
  source .venv/bin/activate
  
  # Install dependencies
  pip install -r requirements.txt
  pip install -r agentic/requirements.txt
  ansible-galaxy install -r requirements.yml
  
  # Setup pre-commit
  pre-commit install --install-hooks
  
  echo "Environment setup complete!"
'';
```

## Migration Strategy

### Current Approach
Users can choose their preferred method:
1. **Bash-only**: Source `ibt.sh`, run `ibt setup`
2. **Nix Flakes**: Run `nix develop` (modern, recommended)
3. **Traditional Nix**: Run `nix-shell bin/nix/shell.nix`
4. **Gitpod**: Cloud-based environment (uses bash setup)

### Migration Goals

1. **Preserve Functionality**: All bash features work in Nix
2. **Maintain Compatibility**: Bash scripts still work standalone
3. **Improve Reproducibility**: Nix ensures consistent environments
4. **Simplify Setup**: Single command (`nix develop`)
5. **Document Path**: Clear migration guide for users

### Challenges

- **Nix Learning Curve**: Not all users familiar with Nix
- **Platform Support**: Nix not available on all platforms
- **Existing Workflows**: Users have established bash workflows
- **Tool Availability**: Some tools not in nixpkgs
- **Virtual Environment**: Python venv outside Nix paradigm

### Benefits of Nix

- **Reproducibility**: Exact package versions
- **Declarative**: Configuration as code
- **Isolated**: No system pollution
- **Multi-Platform**: Linux and macOS support
- **Rollback**: Easy to revert changes
- **Caching**: Binary cache for fast setup

## Resources and Dependencies

### Core Dependencies
- **Bash**: Shell scripting (v4+)
- **Nix**: Package manager (v2.13+ with flakes)
- **Docker**: Container runtime
- **Python**: 3.9+ for tools and scripts
- **Ansible**: 2.12+ for playbooks
- **Git**: Version control

### Optional Dependencies
- **1Password CLI**: Secret management
- **Hugo**: Documentation website
- **Go**: For additional tools
- **Pre-commit**: Git hooks

### External Services
- **GitHub**: Repository hosting and CI/CD
- **Gitpod**: Cloud development environment
- **Ansible Galaxy**: Role distribution

## Development Workflow

### Quick Start (Bash)
```bash
# 1. Source ibt
source ./bin/bash/ibt.sh

# 2. Install tools
ibt setup pre-commit ansible

# 3. Use ibt commands
ibt stacks list
ibt tools dasb --version
```

### Quick Start (Nix)
```bash
# 1. Enter Nix environment
nix develop

# 2. Everything is ready!
ibt stacks list
ansible --version
python --version
```

### Adding New Tools

#### In Bash
1. Add installation logic to `setup.sh`
2. Add tool name to `--list-options` output
3. Update README
4. Test completion

#### In Nix
1. Add package to `buildInputs` in `common.nix`
2. Update `shellHook` if needed
3. Test with `nix develop`

### Adding New Subcommands

1. Create `<subcommand>.sh` with `--list-options` support
2. Create `<subcommand>-completion.sh` using shared utilities
3. Update `ibt.sh` to include new subcommand
4. Update `IBT_SPEC.md`
5. Add tests to `test_completion.sh`
6. Update README

## Use Cases

### Local Development
- Consistent development environment
- Quick tool installation
- Shell completion for productivity
- Manage local stacks for testing

### CI/CD Environments
- Reproducible build environments
- Fast setup with Nix binary cache
- Automated testing
- Consistent across runners

### Onboarding
- New developers get started quickly
- Single command setup
- No manual tool installation
- Works on Gitpod/Codespaces

### Multiple Projects
- Isolated environments per project
- No version conflicts
- Easy context switching
- Declarative dependencies

## Known Issues and Limitations

### Bash Implementation
- Platform-specific differences (Linux vs macOS)
- Manual dependency updates
- No version pinning (uses latest)
- Requires sudo for some installations

### Nix Implementation
- Requires Nix installation first
- Learning curve for new users
- Python venv pattern non-standard in Nix
- Some tools require unfree packages
- Not all platforms supported

### General
- No Windows native support (WSL required)
- Docker required for tool aliases
- Some tools need manual API key setup

## Planned Improvements

### Short Term
1. **Complete Nix Migration**: Achieve feature parity
2. **Documentation**: Comprehensive migration guide
3. **Testing**: Nix-specific test suite
4. **CI Integration**: Use Nix in GitHub Actions

### Long Term
1. **Home Manager**: User-level Nix configuration
2. **Direnv Integration**: Automatic environment activation
3. **Cachix**: Custom binary cache
4. **Flake Inputs**: Pin all dependencies
5. **Cross-Platform**: Better Windows support (via WSL)
6. **IDE Integration**: VSCode Nix extensions

## Documentation Links

- [IBT Specification](../../bin/bash/IBT_SPEC.md) - Design document
- [Bash Scripts README](../../bin/bash/README.md) - Bash implementation
- [Main README](../../README.md) - Project overview
- [Nix Manual](https://nixos.org/manual/nix/stable/) - Nix documentation
- [Nix Flakes](https://nixos.wiki/wiki/Flakes) - Flakes guide

## Release Management

IBT is part of the root monorepo:
- Version in root `package.json`
- No separate releases
- Changes documented in commit messages
- Major changes get changelog entries

## Next Steps

1. **Complete Nix Parity**: Ensure all bash features work in Nix
2. **Migration Guide**: Document transition path for users
3. **Performance Testing**: Benchmark Nix vs Bash setup times
4. **CI Integration**: Use Nix in all GitHub Actions
5. **Documentation Website**: Add Nix setup to getting started guide
6. **Video Tutorial**: Screen recording of Nix workflow
7. **Community Feedback**: Gather user input on Nix migration
8. **Rollout Plan**: Phased migration with fallback to bash
