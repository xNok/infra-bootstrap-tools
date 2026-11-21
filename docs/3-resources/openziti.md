---
type: resource
description: Programmable, zero-trust overlay networking mesh providing dark services, identity-based mTLS, and clientless/tunneled secure access
related_projects:
  - dark-k3s-stack
  - openziti-mesh
  - changeset-release-mgmt
related_areas:
  - security-identity
  - infra-orchestration
---

# OpenZiti

## Overview

**OpenZiti** is a leading open-source Zero Trust Application Network (ZTAN) platform that enables private, programmable overlay networks over the public internet. Instead of relying on traditional perimeter defenses (VPNs, firewalls, and open public ports), OpenZiti makes services **"dark"**—completely invisible and unreachable to anyone without a cryptographically verified identity certificate and explicit authorization policy.

In the `infra-bootstrap-tools` stack, OpenZiti is used to achieve our highest-security control plane pattern: the **Dark K3s Stack**, where the Kubernetes API server listens strictly on localhost (`127.0.0.1`), entirely eliminating public port `6443` while allowing authorized administrators to run `kubectl` securely over the overlay mesh.

---

## 1. Core Architecture & Primitives

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              OPENZITI NETWORK TOPOLOGY                                 │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. CONTROL PLANE (Ziti Controller)                                                     │
│    • PKI & Certificate Authority (Root CA, Intermediate CA)                            │
│    • Edge Management API & Fabric Controller                                           │
│    • Policy Evaluation (Edge Router Policies, Service Policies)                        │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 2. DATA PLANE (Ziti Edge Routers & Mesh Fabric)                                        │
│    • Mesh overlay forwarding traffic across encrypted mTLS circuits                    │
│    • Only port exposed: Ingress router port (e.g., 8444/TCP or 443/TCP)                │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 3. ENDPOINTS & SERVICES                                                                │
│    • Client Identity: Laptop running ziti-edge-tunnel (Intercepts virtual DNS / IPs)   │
│    • Server Identity / Host: Terminates traffic to private service (e.g. 127.0.0.1:6443)│
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### Key Building Blocks

| Primitive | Purpose | Example in This Stack |
| :--- | :--- | :--- |
| **Ziti Controller** | Central orchestrator, PKI CA, edge management API. | `openziti-ziti-controller` in namespace `openziti` |
| **Ziti Edge Router** | Data plane gateway connecting clients and fabric. | `openziti-ziti-router` (advertised at `ziti.nokwebspace.ovh`) |
| **Identities** | Cryptographic identities (clients, hosts, routers). | `admin-laptop`, `k3s-control-plane` |
| **Configurations** | Declares intercept addresses and host forwarding. | `k3s-intercept-config` (`k3s.ziti:6443`), `k3s-host-config` (`127.0.0.1:6443`) |
| **Services** | Named logical service binding configs to policies. | `k3s-api-service` |
| **Service Policies** | Grants `Dial` (client) or `Bind` (hosting) privileges. | `@admin-laptop Dial @k3s-api-service` |

---

## 2. Evolution Across This Repository

Our implementation of OpenZiti has matured through three distinct architectural phases:

### Phase 1: Docker Swarm Mesh (`stacks/openziti/`)
- Deployed as a multi-container Docker Compose / Swarm stack: `ziti-controller`, `ziti-router`, `ziti-console` (ZAC), and an automated `ziti-bootstrap` container.
- Integrated alongside SPIRE (workload identity) and Keycloak (OIDC identity provider).
- Focused on securing inter-service Docker swarm overlays.

### Phase 2: Decoupled Kubernetes Infra-Addon (`kubernetes/infra-addons/components/openziti`)
- Migrated OpenZiti into a pure, decoupled Kubernetes addon packaged as an immutable OCI artifact (`oci://ghcr.io/xnok/manifests/kubernetes/infra-addons`).
- Integrated with `cert-manager` for dynamic TLS certificate issuance.
- Automated lifecycle jobs (`openziti-bootstrap`) configuring default roles, edge router policies, and administrative users.

### Phase 3: The Dark K3s Stack (`docs/1-projects/dark-k3s-stack.md`)
- Bound the K3s server exclusively to localhost:
  ```yaml
  k3s_server_use_openziti_dark: true
  # Binds k3s API server to 127.0.0.1 instead of 0.0.0.0
  ```
- Kubernetes API port `6443` is closed to the outside internet.
- Administrators connect to `https://k3s.ziti:6443` through the `ziti-edge-tunnel` client, achieving zero-attack-surface cluster management.

---

## 3. Hard-Won Architectural Lessons & Gotchas

### 1. The TLS IP SAN Trap & Transition to Real DNS
* **The Symptom**: Upstream `openziti/ziti-controller` Helm charts only expose `dnsNames` in their values schema for web identity certificates. When clients attempted to connect via a public server IP address, Go's `crypto/tls` library threw strict verification panics:
  ```
  x509: cannot validate certificate for 167.99.x.x because it doesn't contain any IP SANs
  ```
* **The Flawed Fix**: Injecting a 40-line Kustomize `postRenderer` patch into `HelmRelease/ziti-controller` to hack `/spec/ipAddresses` into cert-manager Certificate resources.
* **The Architectural Resolution**: Eliminate the leaky `postRenderer` entirely. Instead of connecting over raw IP addresses, register a dedicated, clean DNS hostname (`ziti.nokwebspace.ovh`) via `external-dns` and DigitalOcean DNS. All cert-manager certificates validate seamlessly via standard DNS SANs without custom patches.

### 2. Decoupling Addons from Fleet State
- In early iterations, cluster-specific hostnames and IP addresses leaked into `kubernetes/infra-addons/components/openziti`.
- This violated the Flux 3-Tier D2 architecture: reusable addons in `infra-addons/` must be 100% generic and cluster-agnostic.
- **Adopted Pattern**: `components/openziti` defines generic `ClusterIP` services and baseline Helm releases. All environment-specific DNS hostnames and ingress mappings are injected at the cluster fleet layer (`kubernetes/fleet/k3s/infra-addons/`).

### 3. Resource Footprint Tuning for Homelabs & CI
- The default OpenZiti Helm charts specify generous resource requests suitable for enterprise data centers (2-4 CPU cores, 4-8GB RAM).
- For small homelab nodes (e.g. 2 vCPU / 4GB RAM) and GitHub Actions CI test runners (`fleet/kind`), these defaults resulted in unschedulable pods.
- Sized tuned defaults across controller and edge router:
  - `controller`: `requests: {cpu: 100m, memory: 256Mi}`, `limits: {cpu: 500m, memory: 512Mi}`
  - `edge-router`: `requests: {cpu: 100m, memory: 256Mi}`, `limits: {cpu: 500m, memory: 512Mi}`

---

## 4. Operational Runbook & Common CLI Commands

### Inspecting OpenZiti Mesh State
Execute commands inside the controller or using the `ziti` CLI authenticated to the Edge API:

```bash
# List all registered identities
ziti edge list identities

# List edge routers and connection status
ziti edge list edge-routers

# List active services and intercept configurations
ziti edge list services

# List service policies (Dial / Bind)
ziti edge list service-policies
```

### Enrolling a New Client Identity
```bash
# 1. Create client identity in controller
ziti edge create identity user "developer-laptop" -a "clients" -o developer-laptop.jwt

# 2. Enroll the identity token on client machine
ziti edge enroll developer-laptop.jwt -o ~/.ziti/identities/developer-laptop.json
```

---

## Subtopics & Deep Dives

- [Dark Kubernetes Architecture](openziti/dark-kubernetes.md) — How to configure a zero-ingress Kubernetes cluster with localhost API binding and OpenZiti tunnel access.
- [Client Tunneling & Setup Runbook](openziti/client-tunneling.md) — Installing `ziti-edge-tunnel` daemon on Linux with automatic DNS interception and split routing.
