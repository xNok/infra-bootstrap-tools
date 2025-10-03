

# Bash Scripts for infra-bootstrap-tools

This folder contains helper scripts for managing and bootstrapping infrastructure stacks and tools. Each script is designed to be portable and easy to use from any environment.

## Unified Dispatcher: `ibt`

The `ibt` command (Infra Bootstrap Tools) is a shell function that provides a unified interface to the main project scripts with subcommands and auto-completion support.

**To enable `ibt` in your shell:**

```bash
source ./bin/bash/ibt.sh
```

**Subcommands:**

- `ibt setup [tool ...]` &mdash; Install required tools and dependencies (with tab-completion for tool names)
- `ibt stacks [args ...]` &mdash; Manage and run infrastructure stacks
- `ibt tools [args ...]` &mdash; Use Docker-based aliases for Ansible, AWS CLI, etc.

**Example usage:**

```bash
ibt setup pre-commit ansible
ibt stacks list
ibt tools dasb --version
```

You can add the `source` line to your `~/.bashrc` or `~/.bash_profile` for persistence.

---

## Script Overview

| Script      | Purpose                                                      |
|-------------|--------------------------------------------------------------|
| ibt.sh      | Unified dispatcher for all main scripts (ibt command)        |
| stacks.sh   | Quickly start and manage stacks defined in this repository   |
| tools.sh    | Provides Docker-based aliases for Ansible, AWS CLI, etc.     |
| setup.sh    | Installs all required tools and dependencies for this repo   |

---

## stacks.sh

Quickly start and manage stacks defined in this repository. Supports both direct invocation and shell aliases for convenience.

**Prerequisites:** Docker Compose must be installed.

### Usage

**Source for aliases:**
```bash
source /path/to/stacks.sh
```
or add to your `~/.bashrc.d/` for persistent aliases.

**Direct invocation:**
```bash
./stacks.sh list
./stacks.sh run <name> [component ...] [local]
./stacks.sh help
```

### Commands/Aliases
- `list_stacks` or `list`   — List all available stacks
- `run_stack` or `run`      — Run a stack (with optional components/local)
- `help_stacks` or `help`   — Show usage/help

### Examples
- `run_stack n8n`
- `run_stack n8n local`
- `run_stack n8n component1 component2`
- `./stacks.sh list`
- `./stacks.sh run n8n local`

### How it works
- Stacks are expected as YAML files in `$INFRA_BOOTSTRAP_TOOLS_STACK_PATH` (default: `~/.local/share/infra-bootstrap-tools/stacks`)
- Local stacks use the `.local.yaml` suffix
- Modular stacks can be composed by specifying multiple components

---

## tools.sh

Provides aliases to run Ansible, AWS CLI, Packer, and other tools in Docker containers for a consistent, reproducible environment.

**Prerequisites:** Docker must be installed and running.

### Usage
Source this script in your shell:
```bash
source /path/to/tools.sh
```
or add to your `~/.bashrc.d/` for persistent aliases.

### Aliases Provided
- `dasb`   — Run ansible in Docker
- `dap`    — Run ansible-playbook in Docker
- `daws`   — Run awscli in Docker
- `dpk`    — Run packer in Docker
- `dtf`    — Run terraform in Docker
- `dbash`  — Run bash in Docker

### Examples
- `dasb --version`
- `dap playbooks/main.yml`
- `daws s3 ls`
- `dpk build template.json`
- `dtf plan`

---


## setup.sh

Installs all required tools and dependencies for this repository. Designed for quick setup in local environments, GitHub Codespaces, and Gitpod.

**Prerequisites:**
- Ubuntu/Debian-based system (tested on Codespaces and Gitpod)
- Python and pip
- sudo privileges for some installations

### Usage
```bash
# Recommended: use the ibt dispatcher
ibt setup pre-commit ansible

# Or use the script directly
bash setup.sh pre-commit ansible
```

### Tools Installed
- Python dependencies (from requirements.txt, test-requirements.txt)
- Ansible and Ansible Galaxy roles (from requirements.yml)
- pre-commit hooks
- 1Password CLI (if needed)

### Idempotency
This script can be run multiple times safely.

---

## See also

- [Project root README](../../README.md)
- [Ansible playbooks](../../ansible/playbooks/)

---

Please update this README as new scripts are added or existing ones are updated.
