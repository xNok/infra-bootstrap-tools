# Research: Flox as an alternative to Nix Flakes

Flox (https://flox.dev/) is a software environment platform built on top of Nix that aims to provide "All the power of Nix, none of the learning curve."
It uses a declarative manifest file (like `manifest.toml`) to describe tools, environment variables, and services, offering a more approachable developer experience compared to writing raw Nix flakes.

## Key Features

1. **Declarative and Reproducible:** Similar to Nix flakes, it locks to cryptographically pinned, content-hashed inputs.
2. **Simplified Interface:** Instead of writing complex `flake.nix` code, users define environments in a simpler format, making it easier for non-Nix experts to use.
3. **Composability:** Environments can be layered per project, per team, and per pipeline.
4. **Large Package Ecosystem:** Leverages Nixpkgs (120,000+ packages).
5. **CLI Tooling:** A dedicated CLI (`flox`) to activate, build, and publish environments natively on macOS, Linux, and Windows (WSL2).

## Comparison to current flake.nix

Our current `flake.nix` uses `flake-utils` and dynamically creates `devShells` based on configurations defined in `bin/nix/common.nix`.
It provides environments like `default`, `ansible`, `flux`, `docs`, and `full`.
Each environment has a specific set of `buildInputs` and a `shellHook` to run setup scripts (like setting up `.venv`, running `pip install`, or `ansible-galaxy install`).

With Flox, we could define these environments either as separate manifests or layered environments. Flox allows declarative environment variables and hooks natively through `[vars]`, `[hook]`, and `[profile]` sections in a `manifest.toml`.

## Understanding `[hook]` vs `[profile]`

According to Flox's best practices ([Mastering Hooks and Profiles](https://flox.dev/blog/mastering-hooks-and-profiles-for-reproducible-flox-environments/)):

- **`[hook]`**:
  - The `[hook]` section provides a portable, reproducible way to script **setup operations** (e.g., bootstrapping `venv`, `rbenv`, configuring temporary directories).
  - It runs **once** whenever the environment is activated.
  - Crucially, it executes using **Flox’s built-in bash interpreter**, meaning it behaves identically across all supported systems (macOS, Linux, x86-64, ARM).
  - **Limitations:** It cannot be used for teardown tasks, as it only runs on activation. It should also avoid interactive prompts because they can block automated pipelines (CI/CD).

- **`[profile]`**:
  - The `[profile]` section is used to decorate the environment with **aliases, shell functions, and teardown automations**.
  - Logic inside `[profile]` is executed in the user's **native subshell** (e.g., `bash`, `zsh`, `fish`), inheriting the user's local shell versions and configurations (like `.bashrc` or `.zshrc`).
  - Because local shells vary greatly (e.g., macOS ships with a 20-year-old bash 3.2), logic placed here must be written defensively to support different shells and older versions. Flox allows providing specific blocks for different shells like `[profile.bash]`, `[profile.zsh]`, or a fallback `[profile.common]`.

**Best Practice:** Use `[hook]` for environment bootstrapping and package setup to guarantee cross-platform consistency. Use `[profile]` strictly for providing user convenience functions and aliases.

## POC Implementation

To replicate our current default environment using Flox best practices, we define the following `manifest.toml` in `.flox/env/manifest.toml`:

```toml
# .flox/env/manifest.toml
version = 1

[install]
python3.pkg-path = "python3"
git.pkg-path = "git"
docker.pkg-path = "docker"
pre-commit.pkg-path = "pre-commit"
tenv.pkg-path = "tenv"
terraform-docs.pkg-path = "terraform-docs"
pip.pkg-path = "python3Packages.pip"
yamllint.pkg-path = "python3Packages.yamllint"
ansible.pkg-path = "ansible"
ansible-lint.pkg-path = "ansible-lint"

[vars]
TENV_VALIDATION = "sha"
TENV_AUTO_INSTALL = "true"

[hook]
on-activate = '''
  echo "Bootstrapping development shell..."
  tenv tf install

  if [ ! -d ".venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv .venv
  fi

  # Note: The venv is activated here strictly to run pip installs during the hook execution.
  # The actual user subshell activation is handled via aliases in [profile] or standard sourcing.
  source .venv/bin/activate

  echo "Installing Python dependencies from requirements.txt..."
  pip install -r requirements.txt
  pip install -r agentic/requirements.txt

  echo "Installing Ansible Galaxy roles and collections..."
  ansible-galaxy install -r requirements.yml

  echo "Installing pre-commit hooks..."
  pre-commit install --install-hooks
'''

[profile]
common = '''
  # Automatically activate the virtual environment for the user's interactive shell session
  if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
  fi
'''
```

### Usage

Instead of running `nix develop .#default`, developers would run:
```bash
flox activate
```

## Conclusion
Flox provides a much cleaner, TOML-based declarative API over standard `flake.nix`, hiding the functional complexity of Nix while retaining its reproducible guarantees. The separation of concerns between `[hook]` (guaranteed bash execution for setup) and `[profile]` (user shell decoration) provides a powerful and resilient environment management tool.

Next Steps: Review the POC manifest and if it matches our needs, we can fully migrate from `flake.nix` to `.flox/env/manifest.toml`.
