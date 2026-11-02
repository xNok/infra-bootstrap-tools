---
title: "7 Infrastructure as Code Quality Patterns for Production-Grade Repositories"
date: 2026-04-15
author: xNok
draft: false
summary: "From an OVH server for my Master's 10 years ago to a production-grade homelab: 7 Infrastructure as Code (IaC) quality patterns I rely on in infra-bootstrap-tools, from Policy-as-Code and BATS testing to Nix environments and BOM release management."
tags:
  - Infrastructure as Code
  - DevOps
  - Best Practices
  - CI/CD
  - Policy as Code
---

# 7 Infrastructure as Code Quality Patterns for Production-Grade Repositories

When I first started [`infra-bootstrap-tools`](https://github.com/xNok/infra-bootstrap-tools), it was simply my personal playground. I needed a way to manage an OVH webserver on which I was running experiments for my Master's degree 10 years ago. Ever since then, I've always had a server to manage some automations—mostly n8n for a very long time, along with some custom applications I have built. Having a place where you can deploy that only costs you a few bucks a month is a nerd's dream.

This repository has also been the launchpad into my DevOps career. I have learned so much on the journey, wrote countless articles, and landed side gigs as a tech writer. But that's maybe too much rambling! Today, I wanted to look back and see what I consider I did well on this repo and the key decisions I abide by as cornerstones in my work.

In modern application engineering, we take comprehensive unit tests, type checkers, hermetic build environments, and granular release management for granted. Why should our **Infrastructure as Code (IaC)** be treated with any less rigor?

Over the years, I've treated `infra-bootstrap-tools` as an engineering lab to tackle these friction points head-on. In this article, I want to walk you through **7 key quality patterns** I've implemented across the repository that elevate IaC from fragile glue scripts into a robust, production-grade system.

Let's dig in!

---

## 1. Policy-as-Code Hardening for CI/CD Pipelines

CI/CD pipelines are the engine of modern DevOps, but unconstrained pipelines introduce severe supply chain risks and stability issues. In a busy repository, relying on manual code review to verify that someone pinned an action or added a timeout is a recipe for disaster.

Instead of hoping reviewers catch mistakes, we enforce our engineering standards automatically before code merges using [Conftest](https://www.conftest.dev/) and Open Policy Agent (OPA) Rego policies.

In `infra-bootstrap-tools`, every workflow under `.github/workflows/` is statically tested against our policy rules defined in `policies/ci/`:

- **Pinning Third-Party Actions to Immutable SHAs ([`pinned_actions.rego`](https://github.com/xNok/infra-bootstrap-tools/blob/main/policies/ci/pinned_actions.rego))**: Floating tags like `@v4` can be moved or compromised. We require all third-party GitHub Actions and reusable workflows to be pinned to full 40-character commit SHAs (with a human-readable tag comment, e.g. `uses: actions/checkout@11d5960a326... # v4`).
- **Least-Privilege Job Permissions ([`job_permissions.rego`](https://github.com/xNok/infra-bootstrap-tools/blob/main/policies/ci/job_permissions.rego))**: Every job must declare an explicit `permissions:` block rather than inheriting broad default repository token permissions.
- **Mandatory Job Timeouts ([`job_timeout.rego`](https://github.com/xNok/infra-bootstrap-tools/blob/main/policies/ci/job_timeout.rego))**: Runaway build minutes cost real money. Every job must define an explicit `timeout-minutes` threshold (defaulting to 15 minutes).
- **No Multiline Inline Scripts ([`inline_scripts.rego`](https://github.com/xNok/infra-bootstrap-tools/blob/main/policies/ci/inline_scripts.rego))**: We strictly prohibit writing multiline shell snippets directly inside YAML `run:` blocks.

Here is an excerpt from [`policies/ci/inline_scripts.rego`](https://github.com/xNok/infra-bootstrap-tools/blob/main/policies/ci/inline_scripts.rego) written in Rego v1:

```rego
package main

import rego.v1

# Deny any run step that contains a newline, suggesting it is a multiline inline script
deny contains msg if {
  some job_id
  job := input.jobs[job_id]

  some step_index
  step := job.steps[step_index]

  step.run
  contains(step.run, "\n")

  step_name := object.get(step, "name", sprintf("step %v", [step_index]))
  msg := sprintf("Job '%v' step '%v' contains a multiline inline script. Please extract this into a dedicated script in the `bin/ci` directory.", [job_id, step_name])
}
```

By running `conftest test .github/workflows/ -p policies/ci/` during CI validation, compliance deviations are caught immediately.

> If an architectural standard isn't enforced by a policy engine, it's not a standard—it's just a wish.

---

## 2. Decoupled CI Execution & Automated Shell Script Testing (BATS)

That last policy brings us directly to my biggest pet peeve in modern DevOps: **embedding dozens of lines of bash inside GitHub Actions YAML files**.

When you write multiline shell scripts inside workflow YAML, you create untestable, opaque glue code. You can't run it locally, you can't lint it easily with `shellcheck`, and debugging it turns into an agonizing loop: make a change, commit, push, wait for GitHub Actions to trigger, watch it fail, and repeat.

To escape this trap:

1. **Extract Logic to Executable Scripts**: All CI workflows delegate to dedicated scripts in `bin/ci/` (e.g., `bin/ci/build-website.sh`, `bin/ci/ansible-lint.sh`, or `bin/ci/publish-flux-artifact.sh`).
2. **Strict Bash Headers & Modular Helpers**: Every script enforces strict mode (`set -euo pipefail`), traps cleanup routines with `mktemp`, and leverages shared helpers in `bin/ci/lib/`.
3. **Automated Unit Testing with BATS**: We treat our shell scripts just like Python or Go application code by writing unit tests with the [Bash Automated Testing System (BATS)](https://github.com/bats-core/bats-core) in `bin/tests/ci/`.

Here is an example from [`bin/tests/ci/build-website.bats`](https://github.com/xNok/infra-bootstrap-tools/blob/main/bin/tests/ci/build-website.bats):

```bash
#!/usr/bin/env bats

setup() {
  export MOCK_DIR="$(mktemp -d)"
  export PATH="${MOCK_DIR}:${PATH}"
  export GITHUB_STEP_SUMMARY="${MOCK_DIR}/step_summary.md"
  touch "$GITHUB_STEP_SUMMARY"

  # Mock hugo executable
  cat << 'MOCK_EOF' > "${MOCK_DIR}/hugo"
#!/usr/bin/env bash
echo "mock hugo $@"
MOCK_EOF
  chmod +x "${MOCK_DIR}/hugo"
}

teardown() {
  rm -rf "$MOCK_DIR"
}

@test "build-website.sh fails when missing arguments" {
  run ./bin/ci/build-website.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}
```

We execute our entire test suite using [`bin/ci/lib/run-bats-tests.sh`](https://github.com/xNok/infra-bootstrap-tools/blob/main/bin/ci/lib/run-bats-tests.sh). It formats TAP output and automatically generates collapsible test result summaries directly inside GitHub's Step Summary.

> Testing shell scripts with BATS turns fragile "glue code" into reliable software you can refactor without fear.

---

## 3. Hermetic & Reproducible Development Environments (Nix Flakes & Flox)

In [The Holy Grail of Development Environments: My Journey to Nix](/blog/journey-to-nix/), I shared how I bounced between bloated Docker toolchains (`tools.sh`) and custom bash installer scripts (`ibt`). Both kept falling short because of container startup lag, maintenance overhead, or platform incompatibilities between macOS, Ubuntu, and cloud workspaces.

The solution that completely eliminated "works on my machine" in this repository is **Nix Flakes** (with **Flox** support as a lightweight alternative).

Instead of forcing a single monolithic 10GB environment on every contributor, our [`flake.nix`](https://github.com/xNok/infra-bootstrap-tools/blob/main/flake.nix) dynamically maps targeted shell profiles defined in [`bin/nix/common.nix`](https://github.com/xNok/infra-bootstrap-tools/blob/main/bin/nix/common.nix):

- `nix develop .#docs`: Loads Go, Hugo, and site linters.
- `nix develop .#ansible`: Loads Ansible, `ansible-lint`, and 1Password CLI.
- `nix develop .#flux`: Loads `kubectl`, `helm`, `kind`, and `fluxcd`.
- `nix develop .#default`: Loads common utilities (Git, pre-commit, `tenv` for Terraform version management, BATS, Conftest).

```bash
# Jump straight into the docs environment with the exact pinned Hugo version
nix develop .#docs

# Or run commands directly inside the hermetic shell
nix develop .#docs --command hugo server
```

For contributors who prefer an environment manifest, we also provide a declarative [Flox](https://flox.dev/) environment in `.flox/env/manifest.toml`. And for maximum backward compatibility, our lightweight `ibt` wrapper (`bin/bash/ibt.sh`) can still dispatch commands with auto-completion and container fallbacks.

No installation guides, no conflicting system libraries—just bit-for-bit reproducibility everywhere.

---

## 4. GitOps & Immutable Infrastructure Artifact Packaging (Flux CLI & GHCR)

A classic operational anti-pattern is deploying changes to servers by SSHing in and running `git pull` followed by `docker compose up`, or having a cron job pull raw branches on cluster nodes. 

What happens when git is unreachable? What happens if someone pushes an untested commit to `main`? And how do you roll back reliably when your deployment relies on a live git checkout?

In `infra-bootstrap-tools`, infrastructure manifests are packaged and published as **immutable Open Container Initiative (OCI) artifacts**:

1. Pushes to Kubernetes manifests trigger [`.github/workflows/flux-oci-publish.yml`](https://github.com/xNok/infra-bootstrap-tools/blob/main/.github/workflows/flux-oci-publish.yml).
2. The workflow enters a hermetic `nix develop .#flux` shell and calls [`bin/ci/publish-flux-artifact.sh`](https://github.com/xNok/infra-bootstrap-tools/blob/main/bin/ci/publish-flux-artifact.sh).
3. The script packages the manifests using the Flux CLI and pushes them as versioned OCI artifacts to the GitHub Container Registry (GHCR):

```bash
# bin/ci/publish-flux-artifact.sh
flux push artifact "oci://ghcr.io/${OWNER}/manifests/kubernetes/${ARTIFACT_NAME}:${SHORT_SHA}" \
    --path="${ARTIFACT_PATH}" \
    --source="${SOURCE_URL}" \
    --revision="${HEAD_SHA}"
```

4. Downstream cluster operators (Flux) pull the versioned OCI artifact and reconcile it into the cluster.

Because artifacts are tagged with the immutable commit SHA and cryptographically traceable back to source commits, we gain complete auditability, zero direct git access from cluster nodes, and effortless rollback.

---

## 5. Multi-Granular Tree Release Strategy & Bill of Materials (BOM) Management

Release management in a polyglot infrastructure monorepo is notoriously tricky. This repository contains Ansible collections, individual Ansible roles, Docker Swarm stacks, and Python agent utilities.

In [Intentional Releases: Why I Chose Changesets over Semantic-Release](/blog/intentional-releases-changesets/), I explained why purely automated commit parsing (like `semantic-release`) fails for infrastructure. It produces noisy changelogs full of commit hashes rather than communicating actual architectural intent to users.

To solve this, we implemented a **Hierarchical Tree Release Architecture** using npm workspaces and [Changesets](https://github.com/changesets/changesets), even though this repository contains virtually no Node.js code:

### Multi-Level Package Architecture

1. **Leaf Level (Individual Components)**: Every standalone role (e.g., `ansible/roles/docker`, `ansible/roles/k3s_server`) and stack maintains its own `package.json` with independent semantic versioning.
2. **Aggregator Level (Bill of Materials - BOM)**: Parent directories like [`ansible/package.json`](https://github.com/xNok/infra-bootstrap-tools/blob/main/ansible/package.json) act as a **Bill of Materials (BOM)**. They pin the exact tested versions of all underlying roles:

```json
{
  "name": "ansible-collection-infra-bootstrap-tools",
  "private": true,
  "version": "1.1.0",
  "workspaces": [
    "roles/*"
  ],
  "dependencies": {
    "ansible-role-docker": "0.0.2",
    "ansible-role-k3s-server": "0.1.3",
    "ansible-role-utils-rotate-docker-secrets": "0.0.1",
    "ansible-role-utils-affected-roles": "0.0.3"
  }
}
```

3. **Automated Tree Cascading**: When you submit a PR, Changesets prompts you for an intentional change description (`yarn changeset`). If you bump `ansible-role-docker`, Changesets automatically bubbles that bump up to the parent `ansible-collection-infra-bootstrap-tools` BOM package!

Consumers can choose to pin an individual role, or simply reference the parent collection BOM knowing that all constituent roles have been tested together.

---

## 6. Defense-in-Depth Secret Hygiene & Dynamic Credential Injection

Hardcoding passwords or long-lived API tokens inside infrastructure playbooks is an obvious security hazard. But even keeping plaintext `.env` files or secret values on host filesystems creates an unnecessary attack surface.

In `infra-bootstrap-tools`, secret hygiene is handled with defense-in-depth:

1. **Pre-Commit Guardrails**: Local `.pre-commit-config.yaml` runs `detect-private-key` and secret detection hooks before any git commit can be finalized.
2. **Ephemeral Injection via 1Password CLI**: We avoid writing credentials to disk by leveraging `op run` or 1Password CLI integrations to dynamically inject secrets into environment variables at runtime.
3. **Zero-Downtime Secret Rotation in Ansible**: For containerized workloads on Docker Swarm, secrets shouldn't be left as static files. We built dedicated utility roles like [`ansible/roles/utils_rotate_docker_secrets`](https://github.com/xNok/infra-bootstrap-tools/blob/main/ansible/roles/utils_rotate_docker_secrets/README.md) and `utils_rotate_docker_configs`.

When a database password or API token changes, `utils_rotate_docker_secrets` provisions a new versioned secret (e.g. `db_password_20260415`), updates the Docker Compose service definition to point to the new secret, triggers a rolling service update, and prunes the old secret—all with zero downtime and without persisting plaintext on target hosts.

---

## 7. Layered Architecture & Declarative Idempotency

When you first begin orchestrating infrastructure, the temptation is to build a single "God Playbook": provision the cloud VM, configure firewall rules, install the container runtime, and deploy the application all in one giant run.

The moment something fails in step 47, your server is stuck in an inconsistent intermediate state.

To prevent this, we enforce a strict separation of concerns across three architectural layers:

```
+-----------------------------------------------------------+
| Layer 3: Application Workloads                            |
| (Docker Swarm Stacks & Kubernetes Fleet Manifests)        |
+-----------------------------------------------------------+
                             |
                             v
+-----------------------------------------------------------+
| Layer 2: Host Configuration & Orchestrator Bootstrap      |
| (Ansible Roles: Docker, K3s, OS Hardening, Firewall)     |
+-----------------------------------------------------------+
                             |
                             v
+-----------------------------------------------------------+
| Layer 1: Cloud Infrastructure Provisioning                |
| (Terraform: DigitalOcean Droplets, VPCs, DNS Records)    |
+-----------------------------------------------------------+
```

- **Layer 1: Provisioning (Terraform)**: Solely responsible for cloud infrastructure lifecycles (VMs, VPCs, DNS).
- **Layer 2: OS Configuration & Cluster Bootstrap (Ansible)**: Idempotently configures host settings, sysctl parameters, firewall rules, and cluster manager/agent nodes.
- **Layer 3: Workload Deployment (Docker Swarm / Kubernetes)**: Pure declarative stack and fleet manifests managed via GitOps.

Every playbook and stack is continuously validated by strict linters (`.ansible-lint`, `.yamllint.yaml`, `.terraform-version`). If you rerun our main playbooks against an already configured cluster, every single task reports `ok: 0 changed: 0`.

---

## Bringing It All Together

High quality in Infrastructure as Code isn't about finding a single silver-bullet tool. It’s about building a cohesive culture of craftsmanship across your entire automation pipeline:

| Quality Pattern | Tooling | Problem Solved |
| :--- | :--- | :--- |
| **1. Policy-as-Code** | Conftest & Rego v1 | Supply chain security, SHA pinning, timeout enforcement |
| **2. Decoupled CI & Shell Testing** | BATS & Bash Strict Mode | Elimination of commit-and-pray loops and unverified glue scripts |
| **3. Hermetic Environments** | Nix Flakes & Flox | "Works on my machine" syndrome and cross-platform drift |
| **4. Immutable OCI Packaging** | Flux CLI & GHCR | Volatile git pulls, unverified deployments, and rollback friction |
| **5. Tree & BOM Releases** | Changesets & Workspaces | Granular role versioning with coordinated collection releases |
| **6. Secret Hygiene** | 1Password CLI & Rotation Roles | Plaintext credential leaks and zero-downtime rotation |
| **7. Layered Modularity** | Terraform + Ansible + Stacks | Fragile monolithic playbooks and non-idempotent configurations |

If you treat your infrastructure automation with the same engineering rigor you give to production software, your systems will be more reliable, testable, and maintainable.

You can explore all of these patterns in action in the [`infra-bootstrap-tools`](https://github.com/xNok/infra-bootstrap-tools) repository. Let me know your favorite IaC patterns or how you tackle CI/CD hygiene in your own setups!

