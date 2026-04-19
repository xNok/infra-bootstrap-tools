# Nix in CI/CD: Patterns & Future Roadmap

This document outlines the strategy, observed patterns, and future architectural direction for migrating the `infra-bootstrap-tools` GitHub Actions CI/CD pipelines to run entirely within Nix environments.

## Current State & Problem

Historically, local development and continuous integration environments were managed via different primitives:
- **Local:** Managed by custom bash setup scripts (`setup.sh`, fetching specific pip/go/node binaries), later migrated to Nix Flakes (`nix develop`).
- **CI/CD:** Managed by GitHub-native Actions (e.g., `actions/setup-python`, `actions/setup-node`, `ansible/ansible-lint`), which download runtime dependencies directly into the Ubuntu runner.

**The Issue:** This split configuration breaks the "it works on my machine" guarantee. If a user tests against Python 3.11 locally encoded in `.nix`, but `.github/workflows/release-python.yml` hardcodes `node-version: 20` or python setup steps, the pipeline can unexpectedly fail.

## Architectural Goal

**Nix as the Single Source of Truth for Tooling**. 

No CI pipeline should ever invoke `actions/setup-python`, `actions/setup-node`, or `setup-go`. Every job should instantiate the repository's Nix developer environment, ensuring the runner utilizes the exact same binaries and library paths that the developers use on their local machines.

## Observed Patterns and Best Practices

Through the migration of the `ansible-play-docker-swarm.yml` pipeline, we established several declarative patterns that should be applied to all future workflow migrations.

### 1. Fast, Deterministic Nix Setup
Instead of installing Nix manually, always use the Determinate Systems actions. They provide the most reliable flakes-first installation and caching mechanisms:

```yaml
      - name: Install Nix
        uses: DeterminateSystems/nix-installer-action@v14

      - name: Cache Nix store
        uses: DeterminateSystems/magic-nix-cache-action@v8
```

### 2. Global Shell Assignment
Rather than prefixing every command with `nix develop ... --command`, you can leverage GitHub Actions `defaults.run` to override the default shell behavior at the job level.

```yaml
  validate:
    runs-on: ubuntu-latest
    defaults:
      run:
        # {0} is the temporary file where the runner dumps the `run` block
        shell: nix develop .#ansible --command bash -eo pipefail {0}
    steps:
      ...
```

**Benefits of Global Shell Assignment:**
- Keeps the `run:` blocks clean and readable.
- `nix develop` evaluates once per block natively.
- Ensures zero environment leakage; you can't accidentally invoke a system-level binary.

### 3. Replacing Tool-Specific Actions
Do not use isolated wrapper actions like `ansible/ansible-lint`. Because these wrap the CLI in a separate Python container/environment, they often fail to resolve relative paths or FQCNs (Fully Qualified Collection Names) created by our local `make install-collection` steps. 

Run the native CLI directly inside the Nix shell:
**Bad:**
```yaml
      - name: Run ansible-lint
        uses: ansible/ansible-lint@v25.9.0
```
**Good (Using Nix Global Shell defaults):**
```yaml
      - name: Run ansible-lint
        run: ansible-lint ansible
```

## Migration Roadmap & Future Ideas

The following pipelines currently use legacy GitHub Actions environment setup and must be migrated to Nix implementations:

### Workflow Migration Matrix

- [ ] **`release-changeset.yml`**: Uses `actions/setup-node@v4`. Migrate to use `nix develop .#default` with Node/Yarn exposed locally.
- [ ] **`release-python.yml`**: Needs to adopt the Nix Python Virtual Environment to build and push Python packages.
- [ ] **`release-ansible.yml`**: Needs the Ansible environment shell to execute `ansible-galaxy collection build` and `publish`.
- [ ] **`website.yml`**: Uses `actions/setup-go@v5` to support Hugo module downloads. The Hugo extended package provided in `.nix` can handle this natively.

### Future Ideas

1. **Pre-commit caching**: Right now pre-commit installs all hooks from scratch upon invocation inside Nix. We should explore caching `~/.cache/pre-commit` explicitly in pipelines to dramatically speed up lint checks.
2. **Specialized Task Shells**: For complex CI runners (like Python tests versus Go builds), continue extracting them into specialized devShells in `flake.nix` (e.g., `.#python`, `.#go`) to keep the CI environments ultra-lightweight.
3. **Nix matrix testing**: GitHub Actions provides easy matrix strategies. We can use Nix to test our software against multiple versions of Python/Node simultaneously by creating matrix outputs dynamically from the Nix inputs, without ever leveraging `setup-*` actions.
