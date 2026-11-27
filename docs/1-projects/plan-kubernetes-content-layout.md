---
type: project
status: active
description: Plan the content layout, documentation structure, and discoverability improvements for Kubernetes/K3s alongside Docker Swarm
related_projects:
  - dark-k3s-stack
  - kubernetes-flux-d2
  - docker-swarm-env
  - ibt-nix-refactor
related_resources:
  - nix
related_areas:
  - infra-orchestration
  - developer-experience
---

# Plan: Kubernetes Content Layout & Discoverability

## 1. Problem Statement & Context

The repository has completed extensive engineering and operational work on **K3s**, **Zero-Trust networking (OpenZiti)**, and **Enterprise GitOps (Flux D2)**:
- Hardened K3s Ansible automation: `k3s_server`, `k3s_agent`, `k3s_os_hardening`, and `k3s_flux_bootstrap`.
- "Dark K3s" zero-trust architecture: K3s API bound to `127.0.0.1` with public ports closed and exposed exclusively through OpenZiti overlay network.
- Flux D2 Enterprise GitOps pattern adapted for monorepo: dual OCI artifacts (`fleet/<cluster>` and `infra-addons`), values layering via ConfigMaps, immediate reconciliation with `reconcile.fluxcd.io/watch: Enabled`.
- Fully automated local integration test harness using Kind + local OCI registry (`make test-flux-d2`, `bin/k8s/setup-kind-local-registry.sh`, `bin/tests/flux-d2/test.sh`).
- Add-on components: cert-manager, trust-manager, OpenZiti controller/router, Keycloak/Auth0 OIDC integration.

**The Disconnect**:
The documentation website (`website/content/en/docs/`) and sidebar (`website/data/en/docs/sidebar.yml`) do not reflect any of this learning:
1. `_overview.md` states that the author prefers Docker Swarm and dismisses Kubernetes as fashion over function.
2. The sidebar navigation contains no Kubernetes section whatsoever.
3. Getting started assumes single-node Docker Swarm with Caddy and Portainer.
4. Discoverability is zero: an outside user or homelab enthusiast landing on the site cannot see that a hardened K3s + OpenZiti + Flux D2 stack exists in the repository.

---

## 2. Goals & Objectives

1. **Parity & Truth**: Align documentation with codebase reality—both Docker Swarm and Kubernetes (K3s) are first-class, supported orchestrators.
2. **Clear Pathways (Progressive Disclosure)**:
   - Provide an intentional fork in the road:
     - **Path A (Minimalist Homelab)**: Docker Swarm + Caddy + Portainer (simple, low resource, compose-native).
     - **Path B (Zero-Trust GitOps)**: K3s + OpenZiti + Flux D2 (declarative GitOps, private control plane, enterprise patterns).
3. **Information Architecture (IA)**:
   - Restructure `website/content/en/docs/` and `sidebar.yml` into logical, discoverable groups.
   - Keep shared foundations (Terraform, Ansible, Nix, 1Password) separate from orchestrator-specific tracks.
4. **Actionable Content Inventory**:
   - Define the exact files, sections, and topics to write.
   - Outline key blog articles to broadcast these learnings.

---

## 3. Information Architecture (IA) Comparison

### Current Structure:
- Documentation
  - Overview (`_overview.md`)
  - Getting Started (`gs1.getting_started.md`)
- Infrastructure Management
  - Understanding Ansible Concepts (`b1.ansible_concepts.md`)
  - Spinning up infrastructure (`b2.terraform_ansible.md`)
  - Docker Swarm Setup (`b3.docker_swarm.md`)
- Tools Introduction
  - Caddy (`a1.caddy.md`)
  - Portainer (`a2.portainer.md`)
- Tools Showcase
  - Pre-commit (`tools/pre-commit.md`)
  - 1Password CLI (`tools/1password-cli.md`)
  - Boilerplate (`tools/boilerplate.md`)
  - Hugo (`tools/hugo.md`)
  - *(Nix exists in filesystem but missing from sidebar)*

### Proposed Structure:

#### Section 1: Getting Started & Journey
- **Overview**: Position the project as a progressive journey from Docker Swarm simplicity to Zero-Trust Kubernetes GitOps.
- **Architectural Parity & Mirroring**: Detailed mapping of Docker Swarm layers to Kubernetes layers:
  - Cluster Management & Delivery: **Portainer** (Swarm) mirrors **FluxCD Operator** (K3s).
  - Ingress & Perimeter: **Caddy** (traditional reverse proxy) evolves into **OpenZiti** (zero-trust dark overlay).
- **Makefile Disambiguation**:
  - `make up`: Historically provisions DigitalOcean VMs and deploys the Docker Swarm stack (`main.yml`).
  - `make k3s`: Builds collection and executes `ansible/playbooks/k3s.yml` across target servers.
  - `make test-flux-d2`: Spins up local Kind cluster + local OCI registry to validate GitOps and OpenZiti without cloud costs.

#### Section 2: Shared Infrastructure Foundations
- **Terraform Cloud Provisioning**: Managing DigitalOcean and AWS instances.
- **Ansible Automation Framework**: Inventory models, playbooks, roles, and vault/1Password lookups.
- **Secrets Management**: 1Password CLI (`op`) integration and automated placeholders.

#### Section 3: Docker Swarm Track (Homelab Core - 4 High-Value Pages)
1. **Architecture & Philosophy** (`s1.swarm_architecture.md` / `swarm-architecture`): Minimalist single-binary clustering, internal Raft consensus, and routing mesh.
2. **Bootstrapping Swarm with Ansible** (`b3.docker_swarm.md` / `docker-swarm-setup`): Declarative multi-node inventory, manager initialization, and worker joins.
3. **Reverse Proxy with Caddy** (`a1.caddy.md` / `caddy`): Ingress perimeter, automated Let's Encrypt TLS, and OAuth authentication.
4. **Cluster Operations with Portainer** (`a2.portainer.md` / `portainer`): Visual cluster management, container stacks, and monitoring.

#### Section 4: Kubernetes Track (Dark K3s - 4 High-Value Pages)
1. **Architecture & Philosophy** (`k1.overview.md` / `kubernetes/dark-k3s-architecture`): Dark control plane bound to `127.0.0.1`, perimeter isolation, and zero-trust design.
2. **Bootstrapping K3s with Ansible** (`k3.k3s_ansible.md` / `kubernetes/k3s-ansible-bootstrap`): Host OS hardening (UFW default-deny port matrix), declarative `config.yaml`, token management, and agent joins.
3. **Zero-Trust Mesh with OpenZiti** (`k5.openziti_mesh.md` / `kubernetes/openziti-mesh`): Programmable overlay network, router enrollment, and secure kubectl tunneling.
4. **GitOps with Flux D2 & OCI** (`k4.flux_d2_gitops.md` / `kubernetes/flux-d2-gitops`): Monorepo OCI artifacts, values layering, ConfigMap watch, and platform add-on services (cert-manager, trust-manager, OIDC).

*(Note: Implementation details like Node Hardening and Platform Add-ons were folded directly into the primary 4 pages to eliminate main nav clutter, while Kind local testing is maintained as a focused test guide cross-linked from Quickstart).*

#### Section 5: Developer Tooling & Workflow
- **Nix & Flakes**: Task-specific developer shells (`.#ansible`, `.#flux`, `.#docs`, `.#full`).
- **Code Quality**: Pre-commit hooks, linters, and BATS tests.
- **Release Automation**: Changesets monorepo versioning.
- **Documentation Platform**: Hugo and documentation guidelines.

---

## 4. Exact Content Pieces & Layout

### A. Existing Documentation Updates
1. `website/content/en/docs/_overview.md`:
   - Rewrite introduction to celebrate both Docker Swarm (rock-solid, minimal) and K3s (hardened, zero-trust, GitOps).
   - Update navigation references.
2. `website/content/en/docs/gs1.getting_started.md`:
   - Add orchestrator selection guide.
   - Add K3s bootstrap prerequisites alongside Swarm.
3. `website/data/en/docs/sidebar.yml`:
   - Restructure menu categories to reflect the new IA.
   - Include `tools/nix.md` and all new K3s pages.

### B. Infrastructure Management & Core Concerns
1. `website/content/en/docs/im1.core_concerns.md`:
   - Title: "Infrastructure Management: Core Concerns & Parity"
   - Contents: The six universal infrastructure concerns (Compute, OS Hardening, Orchestration, Delivery/GitOps, Ingress, Secrets/Config), architectural parity diagram, Swarm vs K3s comparison.

### C. New Kubernetes Documentation Pages (`website/content/en/docs/kubernetes/`)
1. `kubernetes/k1.overview.md`:
   - Title: "Dark K3s Architecture & Philosophy"
   - Contents: Zero-trust control plane, why 127.0.0.1, OpenZiti integration, Flux D2 GitOps.
2. `kubernetes/k2.os_hardening.md`:
   - Title: "Node Hardening & Security (UFW)"
   - Contents: `k3s_os_hardening` role, firewall rules, port isolation.
3. `kubernetes/k3.k3s_ansible.md`:
   - Title: "Bootstrapping K3s with Ansible"
   - Contents: 4-stage pipeline (`k3s_os_hardening`, `k3s_server`, `k3s_flux_bootstrap`, `k3s_agent`), declarative `config.yaml`, token management.
4. `kubernetes/k4.flux_d2_gitops.md`:
   - Title: "GitOps with Flux D2 & OCI"
   - Contents: Monorepo mapping, dual OCI artifacts, values layering rules, watch annotations.
5. `kubernetes/k5.openziti_mesh.md`:
   - Title: "Zero-Trust Overlay with OpenZiti"
   - Contents: Router enrollment, controller configuration, JWT signer, dark API access.
6. `kubernetes/k6.infra_addons.md`:
   - Title: "Platform Add-ons (Cert-Manager & Identity)"
   - Contents: cert-manager, trust-manager (`--trust-namespace`), Keycloak & Auth0 OIDC.
7. `kubernetes/k7.local_testing_kind.md`:
   - Title: "Local Cluster Testing with Kind"
   - Contents: `make test-flux-d2`, local registry OCI pushing, end-to-end integration validation.

### D. New Tools Introduction & Showcase Pages (`website/content/en/docs/tools/`)
1. `tools/flux.md`: "FluxCD: Gitless GitOps via OCI Artifacts" (Tools Introduction)
2. `tools/openziti.md`: "OpenZiti: Programmable Zero-Trust Mesh" (Tools Introduction)
3. `tools/changesets.md`: "Changesets: Intentional Monorepo Release Management" (Tools Showcase)
### E. Excalidraw Diagram Suite (IBT Project Collection)
Authored and maintained in internal Excalidraw collection `IBT` (`2il9ZfGnHpD`), rendered to standalone static images in `website/static/images/diagrams/` (internal edit URLs strictly omitted from public web pages):
1. **Scene 1**: `Architectural Parity: Docker Swarm vs Dark K3s` (`8jP4Axz176r`)
   - Embedded in: `_overview.md`, `im1.core_concerns.md`, `gs1.getting_started.md`
2. **Scene 2**: `Dark K3s Zero-Trust Network Topology` (`7sEEjmQPNdq`)
   - Embedded in: `k1.overview.md`, `k5.openziti_mesh.md`, `tools/openziti.md`, blog post `dark-k3s-zero-trust`
3. **Scene 3**: `Flux D2 Enterprise GitOps Pipeline` (`19XwzD63VMb`)
   - Embedded in: `k4.flux_d2_gitops.md`, `tools/flux.md`
4. **Scene 4**: `4-Stage Ansible K3s Provisioning Pipeline` (`viad88FhoJ`)
   - Embedded in: `k3.k3s_ansible.md`

### F. Makefile Renaming & Disambiguation
- Added `make swarm-up`: Runs `ansible/playbooks/main.yml` to provision DigitalOcean infrastructure and deploy the full Swarm stack.
- Added `make swarm-down`: Decommissions Swarm cloud infrastructure.
- Added `make k3s-up`: Convenient alias for `make k3s`.
- Added `make k3s-test`: Convenient alias for `make test-flux-d2`.
- Preserved `make up` and `make down` as backwards-compatible shortcuts.

### F. Recommended Blog Articles (`website/content/en/blog/`)
1. `dark-k3s-zero-trust`:
   - Title: "Building a Dark K3s Cluster: Hiding the Kubernetes API Server Behind OpenZiti"
   - Audience: Homelabbers and DevOps engineers looking for zero-trust alternatives to exposing 6443 or running clumsy VPNs.
2. `flux-d2-monorepo`:
   - Title: "Gitless GitOps: Implementing Enterprise Flux D2 in a Monorepo with OCI Artifacts"
   - Audience: Platform engineers interested in scalable, branchless GitOps using OCI registries and Kustomize components.
3. `homelab-orchestration-swarm-vs-k3s`:
   - Title: "Docker Swarm vs K3s in 2026: An Honest Homelab Retrospective"
   - Audience: Community decision-makers deciding between simplicity and Kubernetes ecosystem benefits.

---

## 5. Phased Execution Plan

- **Phase 1: Project Setup & Information Architecture Alignment**
  - Finalize sidebar navigation schema in `sidebar.yml`.
  - Update `_overview.md` and `getting_started.md`.
- **Phase 2: Core Kubernetes Documentation Authoring**
  - Draft `k1.overview.md` to `k7.local_testing_kind.md` in `website/content/en/docs/kubernetes/`.
  - Validate inter-document links and Hugo build.
- **Phase 3: Blog Posts & Community Catch-up**
  - Draft blog posts summarizing the architectural journey.
- **Phase 4: Review, Polishing, and Verification**
  - Hugo rendering checks, mobile responsiveness, link validation.
