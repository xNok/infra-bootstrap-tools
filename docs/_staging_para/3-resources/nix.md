---
type: resource
description: Reproducible development environments and declarative package management
related_projects:
  - ibt-nix-refactor
related_areas:
  - developer-experience
---

# Nix

## Overview

Nix is a powerful package manager and system configuration tool that enables purely functional package management. In infra-bootstrap-tools, Nix provides reproducible development environments, ensuring all developers have consistent toolchains regardless of their host operating system.

## Key Features

- **Reproducibility**: Exact package versions, bit-for-bit reproducible builds
- **Declarative**: Environments defined as code
- **Isolated**: Multiple versions of packages can coexist
- **Rollback**: Easy to revert to previous configurations
- **Cross-Platform**: Works on Linux and macOS

## Use in This Project

### Nix Flakes (Recommended)

Modern approach using `flake.nix`:

```bash
# Enter development environment
nix develop

# Everything installed and configured automatically
```

### Traditional Nix Shell

```bash
# Use shell.nix file
nix-shell bin/nix/shell.nix
```

## Configuration Files

### flake.nix (Root)

```nix
{
  description = "Infrastructure Bootstrap Tools - Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = (import ./bin/nix/common.nix { inherit pkgs; }).nixpkgsConfig;
        };
        common = import ./bin/nix/common.nix { inherit pkgs; };
      in
      {
        devShells.default = pkgs.mkShell {
          inherit (common) buildInputs shellHook;
        };
      }
    );
}
```

### bin/nix/common.nix

```nix
{ pkgs }:

{
  nixpkgsConfig = {
    allowUnfreePredicate = pkg: pkg.pname == "1password-cli";
  };

  buildInputs = with pkgs; [
    python3
    python3Packages.pip
    ansible
    _1password-cli
    go
    hugo
    pre-commit
    git
    docker
  ];

  shellHook = ''
    # Setup virtual environment and install dependencies
    if [ ! -d ".venv" ]; then
      python -m venv .venv
    fi
    source .venv/bin/activate
    pip install -r requirements.txt
    pip install -r agentic/requirements.txt
    ansible-galaxy install -r requirements.yml
    pre-commit install --install-hooks
  '';
}
```

## Common Commands

### Environment Management
```bash
# Enter development environment
nix develop

# Build environment (without entering)
nix build

# Update flake inputs
nix flake update

# Check flake
nix flake check
```

### Package Management
```bash
# Search for packages
nix search nixpkgs python

# Show package information
nix show-derivation nixpkgs#python3

# Try a package temporarily
nix shell nixpkgs#httpie
```

### Garbage Collection
```bash
# Remove unused packages
nix-collect-garbage

# Aggressive cleanup
nix-collect-garbage -d

# Keep last 7 days of generations
nix-collect-garbage --delete-older-than 7d
```

## Best Practices

1. **Pin Inputs**: Use specific nixpkgs commits for reproducibility
2. **Flakes**: Prefer Flakes over traditional nix-shell
3. **Caching**: Use Cachix for binary caches
4. **Documentation**: Comment complex Nix expressions
5. **Testing**: Test environment on clean system

## Common Patterns

### Development Shell with Tools
```nix
pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs
    python3
    go
  ];
  
  shellHook = ''
    echo "Welcome to the dev environment"
    export PATH="$PWD/bin:$PATH"
  '';
}
```

### Overriding Packages
```nix
pkgs.python3.override {
  packageOverrides = self: super: {
    mypackage = super.mypackage.overridePythonAttrs (old: {
      version = "1.2.3";
    });
  };
}
```

### Environment Variables
```nix
shellHook = ''
  export DATABASE_URL="postgresql://localhost/mydb"
  export DEBUG=true
'';
```

## Resources

### Internal Documentation
- [Main README - Nix Section](../../README.md#nix-shell)
- [IBT Project Documentation](../1-projects/ibt-nix-refactor.md)

### External Links
- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [NixOS Wiki](https://nixos.wiki/)
- [Zero to Nix](https://zero-to-nix.com/)

## Troubleshooting

### Flakes Not Working
```bash
# Enable flakes in nix.conf
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Build Failures
```bash
# Clear build cache
rm -rf ~/.cache/nix

# Verbose output
nix develop --show-trace
```

### Disk Space Issues
```bash
# Check Nix store size
du -sh /nix/store

# Garbage collection
nix-collect-garbage -d
```

## Integration with Project

### With IBT CLI
```bash
# Nix provides the environment
nix develop

# IBT provides the commands
ibt setup ansible
ibt stacks list
```

### With Pre-commit
Nix ensures pre-commit hooks work consistently:
```bash
# In Nix environment
pre-commit run --all-files
```

### With Python Projects
Nix provides Python, pip creates venv:
```bash
# Nix provides: python3, pip
# Shell hook creates: .venv
# Project manages: requirements.txt
```

## Related Resources

- [Bash](./bash.md) - Alternative setup method
- [Docker](./docker.md) - Containerized tools
- [Pre-commit](./pre-commit.md) - Code quality hooks