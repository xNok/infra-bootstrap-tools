---
title: "🚀 Getting Started"
slug: getting-started-deploy-your-infrastructure
---

This runbook provides step-by-step instructions to bootstrap your infrastructure in under 10 minutes. 

> [!TIP]
> If you are deciding between Docker Swarm and Kubernetes (Dark K3s), consult the **[Architecture & Strategy Overview]({{< relref "_overview.md" >}})** for the architectural parity diagram, capability comparison, and decision matrix.

---

## Prerequisites

Before deploying, ensure you have the following installed:

* **Ansible**: [Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) (or use our Nix dev shell: `nix develop .#ansible`).
* **Terraform**: [Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli).
* **Cloud Account**: DigitalOcean or AWS account for provisioning VMs.
* **Secrets Management**:
  * **Recommended**: [1Password & 1Password CLI (`op`)](https://developer.1password.com/docs/cli/get-started/). Our automation uses the `community.general.onepassword` Ansible lookup plugin. Run `./bin/bash/setup-secrets.sh` to generate the required vault item placeholders.
  * **Alternatives**: Ansible Vault or environment variables.

### Development Environment Setup (Recommended)

To avoid managing tool versions locally, enter the pre-configured Nix development shell:

```bash
# For Ansible & Swarm deployment
nix develop .#ansible

# For Kubernetes, Flux, and Kind testing
nix develop .#flux

# Or unified shell
nix develop .#full
```

If you use `direnv`, simply `direnv allow` when entering the repository directory to have your environment activate automatically.

---

## Configuration & Inventory

### 1. Cloud & Secrets Configuration
Configure your credentials in:
* `ansible/playbooks/host_vars/localhost.yml`: DigitalOcean API token, SSH keys, AWS credentials for Terraform backend.
* `ansible/playbooks/group_vars/all.yml`: Rclone DigitalOcean credentials for persistent storage.
* `ansible/playbooks/group_vars/managers.yaml`: Caddy OAuth credentials (if using Swarm).

### 2. Node Inventory
Ansible groups separate hosts by role:
* **Docker Swarm**: `docker_swarm_managers` and `docker_swarm_nodes`.
* **K3s Kubernetes**: `k3s_servers` and `k3s_agents`.

---

## Deployment Tracks: Choosing Your Path

### Understanding the Makefile Targets (Disambiguation)

> [!NOTE]
> The target `make swarm-up` (aliased as `make up`) provisions DigitalOcean infrastructure and deploys the **Docker Swarm** stack (`main.yml`). If you are deploying **K3s**, use the dedicated target `make k3s` (or `make k3s-up`).

---

### Track A: Docker Swarm Deployment (Simple & Lightweight)

The Docker Swarm track provisions compute instances, installs Docker, initializes Swarm, and launches Portainer for cluster management and Caddy for automatic HTTPS:

```bash
# Complete one-step deployment:
make swarm-up  # (or 'make up')
```

#### Step-by-Step Modular Swarm Deployment
If you prefer deploying or testing incrementally:
```bash
# 1. Initialize Docker Swarm cluster only:
make swarm

# 2. Add Portainer Management UI:
make swarm-portainer

# 3. Add Caddy Reverse Proxy & TLS:
make swarm-portainer-caddy
```

#### Accessing Swarm Services
* **Caddy Security Portal**: `https://auth.[YOUR_DOMAIN]/portal`
* **Portainer UI**: Accessible via the Caddy portal for graphical container and stack deployment.

---

### Track B: Kubernetes / Dark K3s Deployment (Zero-Trust & GitOps)

The Kubernetes track deploys a hardened, zero-trust K3s cluster managed declaratively by FluxCD.

#### 1. Zero-Cost Local Testing with Kind (No Cloud Required)
Before deploying to cloud servers, you can test the entire GitOps delivery pipeline and OpenZiti integration locally on your machine:
```bash
make test-flux-d2
```
This boots a Kind cluster, starts a local OCI registry on port 5000, packages your local monorepo manifests, and verifies that `cert-manager`, `trust-manager`, `keycloak`, and `openziti` achieve ready status. See the dedicated **[Local Cluster Testing with Kind Guide]({{< relref "./kubernetes/k7.local_testing_kind.md" >}})** for an in-depth walkthrough.

#### 2. Cloud Server Bootstrap with Ansible
To provision a production K3s cluster on your target nodes:
```bash
make k3s
```
This builds the latest Ansible collection and executes `ansible/playbooks/k3s.yml`, orchestrating a 4-stage pipeline:

1. **Stage 1: Host Hardening (`k3s_os_hardening`)**:
   Enables UFW with a default-deny policy. Closes port 6443 to the public internet, restricts internal traffic to cluster CIDRs, and opens ports 8441/8442 for OpenZiti.
2. **Stage 2: K3s Control Plane (`k3s_server`)**:
   Renders declarative `/etc/rancher/k3s/config.yaml` (`bind-address: 127.0.0.1`, `tls-san: k3s.ziti`, `disable: traefik`), starts K3s, and extracts the cluster join token.
3. **Stage 3: GitOps Bootstrap (`k3s_flux_bootstrap`)**:
   Fetches the GitHub token from 1Password, installs the Flux Operator, and applies the `FluxInstance` pointing to the monorepo's OCI fleet artifact.
4. **Stage 4: Worker Node Join (`k3s_agent`)**:
   Connects agent nodes to the control plane over private network CIDRs using the token registered in Stage 2.

#### 3. Accessing the Dark Cluster
Because the API server is dark (`127.0.0.1:6443`), internet scanners cannot reach it. Connect from your workstation using the OpenZiti client:
```bash
# Enroll your identity:
ziti-edge-tunnel enroll --jwt admin.jwt --identity admin.json

# Interact with the dark cluster transparently:
kubectl --kubeconfig ~/.kube/dark-k3s.yaml get nodes
```

---

## Infrastructure Teardown

To destroy all cloud infrastructure provisioned by Terraform:
```bash
make down
```

---

## Next Steps / In-Depth Documentation

* **Docker Swarm Track**:
  * [Architecture & Philosophy]({{< relref "./s1.swarm_architecture.md" >}})
  * [Bootstrapping Swarm with Ansible]({{< relref "./b3.docker_swarm.md" >}})
  * [Reverse Proxy with Caddy]({{< relref "./a1.caddy.md" >}})
  * [Cluster Operations with Portainer]({{< relref "./a2.portainer.md" >}})
* **Kubernetes Track (Dark K3s)**:
  * [Architecture & Philosophy]({{< relref "./kubernetes/k1.overview.md" >}})
  * [Bootstrapping K3s with Ansible]({{< relref "./kubernetes/k3.k3s_ansible.md" >}})
  * [Zero-Trust Mesh with OpenZiti]({{< relref "./kubernetes/k5.openziti_mesh.md" >}})
  * [Enterprise GitOps with Flux D2 & OCI]({{< relref "./kubernetes/k4.flux_d2_gitops.md" >}})
* **Foundations & Tooling**:
  * [Ansible Concepts in IBT]({{< relref "./b1.ansible_concepts.md" >}})
  * [Terraform & Ansible Cloud Provisioning]({{< relref "./b2.terraform_ansible.md" >}})
  * [Nix Development Environments]({{< relref "./tools/nix.md" >}})
