# Infrastructure as Code (IaC) Quality Patterns Scratchpad

## Goal

Discover high-standard quality patterns in infrastructure as code across this repository (`infra-bootstrap-tools`) and write an engaging listicle introducing them to be published on the website under `website/content/en/blog/2026-04-15-7-iac-quality-patterns/index.md`.

## Discovered Patterns

1. **Policy-as-Code Hardening for CI/CD (Conftest & Rego v1)**
   - Enforcing 40-character commit SHA pinning for actions (`pinned_actions.rego`), explicit job permissions (`job_permissions.rego`), mandatory job timeouts (`job_timeout.rego`), and prohibiting multiline inline scripts (`inline_scripts.rego`).
2. **Decoupled CI/CD Execution & Automated Shell Script Testing (BATS)**
   - Moving shell logic out of GHA YAML into standalone, linted scripts (`bin/ci/`), tested with Bash Automated Testing System (`bin/tests/ci/`).
3. **Hermetic, Hermetically-Locked Development Environments (Nix Flakes & Flox)**
   - Eliminating "works on my machine" issues using Nix (`flake.nix`) and Flox (`.flox/env/manifest.toml`), wrapped with a unified dispatcher (`ibt`).
4. **GitOps & Immutable OCI Infrastructure Artifact Packaging (Flux CLI & GHCR)**
   - Packaging Docker Swarm stacks and Kubernetes manifests as immutable, versioned OCI artifacts pushed to GHCR instead of running ad-hoc raw git deployments.
5. **Multi-Granular Tree / Bill of Materials (BOM) Release Strategy (Changesets)**
   - Hierarchical versioning architecture managing granular leaf packages (individual Ansible roles like `ansible-role-docker`, individual stacks like `docker-stack-n8n`), aggregator collection BOMs (`ansible/package.json`, `stacks/package.json`), and the root monorepo.
   - Using Changesets to automatically propagate semver version bumps up the dependency tree while maintaining exact BOM bill-of-materials traceability and human-written changelogs.
6. **Defense-in-Depth Secret Hygiene & Dynamic Credential Injection**
   - Utilizing pre-commit secret scanners, SOPS, 1Password CLI injection, and automated Docker Secret rotation roles in Ansible to avoid persistent plain-text credentials.
7. **Modular, Idempotent IaC Architecture (Terraform + Ansible + Docker Swarm / K3s)**
   - Clean separation of provisioning (Terraform), configuration management (Ansible), and orchestration (Docker Swarm/K3s) backed by strict linting (`.ansible-lint`, `.yamllint.yaml`).

## Article Details

- Title: 7 Infrastructure as Code Quality Patterns for Production-Grade Repositories
- Date: 2026-04-15
- Author: xNok
- Draft Status: `draft: true`
- Location: `website/content/en/blog/2026-04-15-7-iac-quality-patterns/index.md`
- Content Guidelines alignment: Follows `website/CONTENT_GUIDELINES.md`, includes clear frontmatter, code examples, structured headings, and SEO-friendly summaries/tags.
