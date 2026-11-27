---
title: Overview
url: "docs/overview"
aliases:
- "/docs"
---

I started **Infra-Bootstrap-Tools** (IBT) when I was first diving into DevOps as my personal lab for testing tools and running infrastructure experiments. Over the years, the project has evolved into a practical, battle-tested collection of Infrastructure-as-Code (IaC) and GitOps configurations designed for small self-hosted projects, edge nodes, and homelabs.

The core philosophy remains unchanged: **reproducible, wipe-and-rebuild reliability**. You should be able to completely tear down your infrastructure and have it running again in minutes with total confidence.

---

## The Dual-Orchestration Model

Infrastructure is not one-size-fits-all. A minimal homelab running a couple of utility containers doesn't need the overhead of an enterprise control plane. Conversely, complex multi-service architectures demand declarative GitOps, fine-grained RBAC, and zero-trust perimeter defense.

To address both needs without dogma, **Infra-Bootstrap-Tools supports two distinct orchestration tracks**:

![Architectural Parity: Docker Swarm vs Dark K3s](/images/diagrams/architectural-parity-swarm-k3s.png)

### Choosing Your Orchestration Track

| Capability | Docker Swarm Track | Kubernetes Track (Dark K3s) |
| :--- | :--- | :--- |
| **Philosophy** | Minimalist, simple, pragmatic | Enterprise GitOps & Zero-Trust |
| **Control Plane** | Docker Swarm Raft manager | K3s server bound strictly to `127.0.0.1` |
| **Public Exposure** | Ports 80/443 (Caddy) | Only OpenZiti data plane ports; API is dark |
| **Workload Definition** | Docker Compose / Stack files | Kustomize Components & HelmReleases via Flux |
| **Secret & Config Delivery** | Docker Secrets & Configs | 1Password CLI bootstrap + ConfigMap watch |
| **Management Interface** | Portainer Web UI | OpenZiti Tunnel + kubectl / k9s / Flux CLI |
| **Recommended For** | Low-spec hardware, rapid prototypes | Production homelabs, GitOps, zero-trust edge |

---

## Documentation Sections

The documentation is organized into focused, progressive sections:

### 1. [Getting Started & Quickstart]({{< ref "./gs1.getting_started.md" >}})
Understand prerequisites, setup your local development tools with Nix, configure secrets with 1Password, and deploy your chosen cluster.

### 2. [Infrastructure Management]({{< ref "./im1.core_concerns.md" >}})
- **[Core Concerns & Parity]({{< ref "./im1.core_concerns.md" >}})**: The six universal concerns of self-hosted infrastructure and architectural mirroring.
- **[Understanding Ansible Concepts]({{< ref "./b1.ansible_concepts.md" >}})**: Playbooks, roles, tasks, and dynamic inventory.
- **[Cloud Provisioning with Terraform & Ansible]({{< ref "./b2.terraform_ansible.md" >}})**: Spin up cloud compute instances on DigitalOcean or AWS.

### 3. Docker Swarm Track
- **[Architecture & Philosophy]({{< ref "./s1.swarm_architecture.md" >}})**: Minimalist single-binary clustering, internal Raft consensus, and routing mesh.
- **[Bootstrapping Swarm with Ansible]({{< ref "./b3.docker_swarm.md" >}})**: Declarative multi-node inventory, manager initialization, and worker joins.
- **[Reverse Proxy with Caddy]({{< ref "./a1.caddy.md" >}})**: Ingress perimeter, automated Let's Encrypt TLS, and OAuth authentication.
- **[Cluster Operations with Portainer]({{< ref "./a2.portainer.md" >}})**: Visual cluster management, container stacks, and monitoring.

### 4. Kubernetes Track (Dark K3s)
- **[Architecture & Philosophy]({{< ref "./kubernetes/k1.overview.md" >}})**: Dark control plane bound to `127.0.0.1`, perimeter isolation, and zero-trust design.
- **[Bootstrapping K3s with Ansible]({{< ref "./kubernetes/k3.k3s_ansible.md" >}})**: Host OS hardening (UFW default-deny), declarative `config.yaml`, and cluster joins.
- **[Zero-Trust Mesh with OpenZiti]({{< ref "./kubernetes/k5.openziti_mesh.md" >}})**: Programmable overlay network, router enrollment, and secure kubectl tunneling.
- **[Enterprise GitOps with Flux D2 & OCI]({{< ref "./kubernetes/k4.flux_d2_gitops.md" >}})**: Monorepo OCI artifacts, values layering, and platform add-on services.

### 5. Tools Introduction
- **[Caddy Web Server]({{< ref "./a1.caddy.md" >}})**: Reverse proxy with automated TLS.
- **[Portainer UI]({{< ref "./a2.portainer.md" >}})**: Visual container management dashboard.
- **[FluxCD Operator]({{< ref "./tools/flux.md" >}})**: Gitless GitOps via OCI artifacts.
- **[OpenZiti Mesh]({{< ref "./tools/openziti.md" >}})**: Programmable zero-trust overlay network.

### 6. Tools Showcase
- **[Nix & Dev Environments]({{< ref "./tools/nix.md" >}})**: Hermetic, reproducible shells via Nix flakes.
- **[Pre-commit Framework]({{< ref "./tools/pre-commit.md" >}})**: Automated linters, formatters, and secret scans.
- **[Release Management with Changesets]({{< ref "./tools/changesets.md" >}})**: Intentional monorepo versioning and release workflows.
- **[1Password CLI]({{< ref "./tools/1password-cli.md" >}})**: Secure secret injection without committed credentials.
- **[Boilerplate Generator]({{< ref "./tools/boilerplate.md" >}})**: Rapid project scaffolding.
- **[Hugo Documentation Site]({{< ref "./tools/hugo.md" >}})**: Fast static documentation publishing.
