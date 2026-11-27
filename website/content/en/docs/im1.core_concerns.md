---
title: "Infrastructure Management: Core Concerns & Parity"
slug: infrastructure-concerns
description: "Why every self-hosted stack shares the same six foundational concerns, and how infra-bootstrap-tools addresses them across Docker Swarm and Kubernetes."
---

## The Universal Concerns of Infrastructure

When building a self-hosted platform—whether a single-node homelab on a budget VPS or a hardened multi-node edge deployment—it is tempting to focus solely on container orchestrator syntax (`compose.yaml` versus `kustomization.yaml`).

However, orchestrator engines are merely runtimes. Regardless of the tool chosen, every infrastructure stack must solve the exact same **six fundamental concerns**:

| # | Universal Concern | Core Responsibility |
|---|---|---|
| **1** | **Compute Provisioning** | How VMs, DNS, and cloud resources are created |
| **2** | **OS & Host Hardening** | Minimizing attack surface and firewall locking |
| **3** | **Orchestration Engine** | Scheduling, clustering, and container lifecycle |
| **4** | **Cluster Operations** | Declarative delivery, visual UI, and GitOps |
| **5** | **Ingress & Perimeter** | Exposing services, TLS certificates, and auth |
| **6** | **Secrets & Config Mgmt** | Injection of credentials without Git leaks |

`infra-bootstrap-tools` structures its automation around these universal concerns. By establishing strict architectural parity between **Docker Swarm** and **Kubernetes (Dark K3s)**, you can navigate both stacks using the same mental model.

---

## Architectural Parity & Mirroring

The diagram below illustrates how each track solves these six foundational concerns:

![Architectural Parity: Docker Swarm vs Dark K3s](/images/diagrams/architectural-parity-swarm-k3s.png)

---

## Detailed Breakdown of Concerns

### Concern 1: Compute Provisioning
Both tracks share identical provisioning foundations. We use **Terraform** to provision cloud compute droplets/instances on DigitalOcean or AWS, configure SSH keys, and create private VPC networking. Because compute is decoupled from the runtime, you can swap providers without altering your application stacks.

### Concern 2: OS & Host Hardening
A cluster is only as secure as the underlying operating system.
- In **Docker Swarm**, Ansible ensures Docker packages and dependencies are installed with standard security defaults.
- In **Dark K3s**, Ansible runs the `k3s_os_hardening` role first. It configures UFW to drop all incoming packets by default, isolates port `6443` strictly to internal network interfaces, and ensures no administrative ports are exposed publicly.

### Concern 3: Orchestration Runtime
- **Docker Swarm** is ideal for small, resource-constrained environments (1–2 vCPUs, 1GB RAM). It is built directly into Docker, uses Raft consensus for managers, and provides zero-overhead container clustering.
- **K3s** delivers a fully compliant CNCF Kubernetes control plane packaged as a single ~100MB binary. It provides access to the vast Kubernetes ecosystem (CRDs, Operators, Helm charts) while binding loopback (`127.0.0.1`) to prevent external exposure.

### Concern 4: Cluster Operations & Delivery (Portainer vs. FluxCD)
Notice the deliberate operational mirroring:
- In **Docker Swarm**, cluster management is handled visually by **Portainer**. Operators deploy and monitor application stacks via a clean web UI, inspecting container logs and resource usage.
- In **Kubernetes**, cluster delivery is handled declaratively by **FluxCD Operator**. Instead of manual UI deployments, Flux pulls versioned, signed OCI artifacts from GHCR and continuously reconciles desired cluster state.

### Concern 5: Ingress & Perimeter Defense (Caddy vs. OpenZiti)
How external traffic reaches workloads represents the largest architectural divergence:
- **Traditional Edge Ingress (Caddy)**: Swarm uses Caddy to listen on public ports 80 and 443. Caddy automatically negotiates Let's Encrypt certificates, reverse-proxies requests to backend Swarm overlay networks, and secures endpoints using OAuth/GitHub authentication.
- **Zero-Trust Dark Mesh (OpenZiti)**: In K3s, we go **one step further**. Inbound port `6443` is completely closed to the internet. Traffic reaches workloads and the control plane exclusively through an encrypted, identity-authenticated OpenZiti overlay network. Public scanners cannot probe or exploit the API server because it does not listen on any public port.

### Concern 6: Secrets & Configuration Layering
Hardcoded secrets in Git repositories are the number one source of infrastructure compromise:
- Both tracks retrieve sensitive tokens at deploy time using the **1Password CLI (`op`)** via Ansible lookup plugins.
- In K3s, configuration layering follows a strict rule: **never hardcode `spec.values` in HelmRelease**. Instead, default values ConfigMaps are combined with cluster override ConfigMaps using `reconcile.fluxcd.io/watch: Enabled`, ensuring immediate reconciliation when configurations change.

---

## Next Steps

To explore how these concerns are implemented in code:
- **[Understanding Ansible Concepts]({{< relref "./b1.ansible_concepts.md" >}})**: How playbooks and roles automate host configuration.
- **[Cloud Provisioning with Terraform]({{< relref "./b2.terraform_ansible.md" >}})**: How compute resources are provisioned.
- **[Docker Swarm Track]({{< relref "./b3.docker_swarm.md" >}})**: Explore the minimalist Swarm implementation.
- **[Kubernetes Track]({{< relref "./kubernetes/k1.overview.md" >}})**: Deep-dive into Dark K3s, Flux D2, and OpenZiti.
