---
title: Nix Environment
description: Using Nix and Nix Flakes for reproducible development environments in the infra-bootstrap-tools project
weight: 10
---

# Nix Environments

This project uses [Nix](https://nixos.org/) to provide a fully reproducible, declarative development environment. This ensures that every developer—whether on Linux, macOS, or in a cloud IDE like Gitpod—has the exact same toolchain versions.

## Why Nix?
Previously, this project relied heavily on Docker and complex Bash scripts (`ibt`) to bootstrap environments. Nix simplifies this by replacing stateful scripts with a declarative `flake.nix` file that explicitly lists all dependencies.

## Getting Started

If you have Nix installed (with Flakes enabled):

```bash
# Enter the default development environment
nix develop
```

This will drop you into a shell with `python3`, `pre-commit`, `docker`, and other required tools pre-installed and configured. Note that `ansible` is **not** included in the default shell — use `nix develop .#ansible` or `nix develop .#full` for infrastructure automation tasks.

### Specialized Environments

You can also drop into task-specific shells:
```bash
nix develop .#ansible
nix develop .#flux
nix develop .#docs
nix develop .#full
```

## Seamless IDE Integration with Direnv

While running `nix develop` manually works great, you can automate this completely using `direnv`. This bridges the gap between your IDE and Nix, ensuring that whenever you open a terminal in this project, your environment is instantly and automatically loaded.

1. Ensure you have `direnv` and `nix-direnv` installed.
2. The repository already includes a root [`.envrc`](https://github.com/xNok/infra-bootstrap-tools/blob/main/.envrc) that loads the `full` dev shell:
   ```bash
   use flake .#full
   ```
   If you want a lighter environment, you can change this to `use flake` (default shell) or `use flake .#ansible`, etc.
3. Allow the directory by running `direnv allow`.

Now, every time you navigate into the project or open your IDE's integrated terminal, `direnv` will automatically evaluate `flake.nix` and drop you straight into the ready-to-use development environment!

## How It Works Under the Hood

When you run `nix develop`, Nix reads the `flake.nix` file in the root of the repository.
It leverages a `shellHook` to automatically set up virtual environments (like a Python `.venv`) and install project-specific dependencies (`pip install -r requirements.txt`). Some shell variants (such as `ansible` and `full`) also optionally run `ansible-galaxy install -r requirements.yml` to install Ansible roles and collections.

### CI/CD Integration
Our GitHub Actions pipelines also use Nix. By running tasks inside the same Nix profile used locally, we guarantee 100% parity between your laptop and the CI runner.

## Migration from `ibt` bash scripts
If you were previously using the `ibt setup` bash scripts, you can safely transition to running `nix develop`. The Nix flake incorporates all the same tool installations but in a cleaner, more robust package.

## Replicating This Setup

If you want to achieve a similar reproducible setup for your own projects or personal machine, you can replicate these patterns.

### Managing Personal Tools (Nix Profile & Home Manager)
To get the same declarative magic for your personal machine, avoid installing tools globally via traditional package managers or bash scripts. Instead, use Nix to manage your user profile:

**Using `nix profile` (Imperative):**
You can install packages into your personal profile permanently:
```bash
nix profile install nixpkgs#git
nix profile install nixpkgs#nodejs
```

**Using `home-manager` (Declarative):**
For a truly reproducible laptop, use [Home Manager](https://nix-community.github.io/home-manager/). You can define all your packages, dotfiles, and configurations in a single `home.nix` file, ensuring your terminal, Git config, and global tools are identical across every machine you own.

### Achieving Flake and `nix-shell` Compatibility
When setting up a new repository, it is highly recommended to support both legacy `nix-shell` users and modern Nix Flake users without duplicating code. Here is the generic architecture pattern used to achieve that (in this repo the files live at `bin/nix/common.nix`, `bin/nix/shell.nix`, and `flake.nix` at the root):

**1. Centralize Configurations (`common.nix`)**
Create a file that exports your packages and shell environments natively:
```nix
{ pkgs }:
let 
  basePackages = with pkgs; [ git python3 ];
in {
  shells = {
    default = {
      buildInputs = basePackages;
      shellHook = ''echo "Welcome to the default shell"'';
    };
  };
}
```

**2. Legacy Entrypoint (`shell.nix`)**
Consume the common configuration for users who don't have Flakes enabled:
```nix
{ shell ? "default" }:
let
  nixpkgs = import <nixpkgs> {};
  common = import ./common.nix { pkgs = nixpkgs; };
in
nixpkgs.mkShell common.shells.${shell}
```
*Usage:* `nix-shell` or `nix-shell --argstr shell custom-shell`

**3. Modern Entrypoint (`flake.nix`)**
Map the exact same definitions into your Flake:
```nix
{
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        common = import ./common.nix { inherit pkgs; };
      in
      {
        devShells = pkgs.lib.mapAttrs (_: shell: pkgs.mkShell shell) common.shells;
      }
    );
}
```
*Usage:* `nix develop` or `nix develop .#custom-shell`

By structuring your Nix files this way, you guarantee 100% environment parity regardless of how a developer enters the environment!
