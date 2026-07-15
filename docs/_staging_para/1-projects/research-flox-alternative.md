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
It provides environments like:
- `default`
- `ansible`
- `flux`
- `docs`
- `full`

Each environment has a specific set of `buildInputs` and a `shellHook` to run setup scripts (like setting up `.venv`, running `pip install`, or `ansible-galaxy install`).

With Flox, we could define these environments either as separate manifests or layered environments. Flox allows declarative environment variables and hooks natively through `[vars]` and `[profile]` sections in a `manifest.toml`.

## POC Implementation

To replicate our current default environment using Flox, we define the following `manifest.toml` in `.flox/env/manifest.toml`:

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

[vars]
TENV_VALIDATION = "sha"
TENV_AUTO_INSTALL = "true"

[profile]
common = '''
echo "Entering default development shell..."
tenv tf install

if [ ! -d ".venv" ]; then
  echo "Creating Python virtual environment..."
  python3 -m venv .venv
fi
echo "Activating Python virtual environment..."
source .venv/bin/activate

echo "Installing Python dependencies from requirements.txt..."
pip install -r requirements.txt
pip install -r agentic/requirements.txt

echo "Installing pre-commit hooks..."
pre-commit install --install-hooks
'''
```

### Usage

Instead of running `nix develop .#default`, developers would run:
```bash
flox activate
```

Or for specific environments, multiple `.flox` environment dirs can be managed, or Flox composition (layering) can be used.

## Conclusion
Flox provides a much cleaner, TOML-based declarative API over standard `flake.nix`, hiding the functional complexity of Nix while retaining its reproducible guarantees.

Next Steps: Review the POC manifest and if it matches our needs, we can fully migrate from `flake.nix` to `.flox/env/manifest.toml`.
