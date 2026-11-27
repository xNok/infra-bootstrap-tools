---
title: "Building a Dark K3s Cluster: Hiding the Kubernetes API Server Behind OpenZiti"
date: 2026-11-22
author: xNok
summary: "Why we bound our K3s control plane strictly to localhost, locked down all public firewall ports with UFW, and exposed our Kubernetes cluster exclusively over an OpenZiti zero-trust overlay."
tags:
  - Kubernetes
  - K3s
  - OpenZiti
  - Zero-Trust
  - GitOps
  - Homelab
---

# Building a Dark K3s Cluster: Hiding the Kubernetes API Server Behind OpenZiti

If you have ever exposed a self-hosted Kubernetes cluster to the public internet, you are likely familiar with the uneasy feeling of leaving port `6443` open.

Within minutes of assigning a public IP to a cloud server or router, port scanners like Shodan and automated vulnerability bots begin knocking on your API server. Even with strong TLS certificates and RBAC, exposing the primary administrative entry point of your cluster to anyone with an internet connection violates the core tenets of modern defense-in-depth.

For years, the standard answer has been: *"Put it behind a VPN."*

We tried that. We ran WireGuard and OpenVPN. But managing VPN servers introduces its own operational debt: opening UDP firewall ports, wrestling with split-DNS configurations, managing client subnet IP routing tables, and granting wide network-level access to any connected device.

In `infra-bootstrap-tools`, we decided to step away from traditional perimeter security entirely. Instead, we built **Dark K3s**: a cluster whose control plane is bound strictly to `127.0.0.1`, shielded behind a default-deny firewall, and reachable **only** across an [OpenZiti](https://openziti.io/) zero-trust programmable overlay mesh.

Here is why we built it, how the architecture works, and the hard-earned lessons we learned along the way.

---

## What Does "Going Dark" Mean?

In zero-trust terminology, a service is "dark" if it has no listening ports accessible from the untrusted network. If an attacker runs `nmap` against your server's public IP address, the Kubernetes API server does not appear closed or filtered—it does not appear at all.

![Dark K3s Zero-Trust Network Topology](/images/diagrams/dark-k3s-zero-trust-topology.png)

Only two ports are open to the outside world: OpenZiti's cryptographic listener ports (8441 and 8442). Connecting to these ports requires valid mutual TLS (mTLS) certificates or signed tokens; port scanners cannot determine what software is running behind them.

Inside the host, K3s is configured via `/etc/rancher/k3s/config.yaml`:

```yaml
write-kubeconfig-mode: "600"
bind-address: "127.0.0.1"
tls-san:
  - "k3s.ziti"
disable:
  - "traefik"
```

Because `bind-address` is `127.0.0.1`, K3s will not listen on public or private cloud network interfaces. It can only talk to processes running locally on the same operating system.

---

## Bridging the Gap: The OpenZiti In-Cluster Router

If the API server is locked to `127.0.0.1`, how do we manage the cluster with `kubectl` from our laptop?

This is where the OpenZiti overlay mesh comes in:

1. **In-Cluster Router Pod**: We deploy an OpenZiti Edge Router directly as a Kubernetes pod inside the cluster. Because pods share host networking or can bridge directly into local endpoints, the router pod has access to `127.0.0.1:6443`.
2. **OpenZiti Service Definition**: We define an OpenZiti Service named `k3s-control-plane` with intercept address `k3s.ziti:6443` and host destination `127.0.0.1:6443`.
3. **Client-Side Interception (`ziti-edge-tunnel`)**: On our administrative workstation, we run the lightweight `ziti-edge-tunnel` daemon.
4. **Transparent Routing**: When we execute:
   ```bash
   kubectl --kubeconfig ~/.kube/k3s-dark.yaml get nodes
   ```
   The local tunnel daemon intercepts the DNS resolution for `k3s.ziti`, packages the TCP packet inside an end-to-end encrypted OpenZiti overlay circuit, transmits it across the internet to the router pod, which decrypts it and forwards it locally to the K3s API server.

No public port `6443`. No network-level VPN granting access to our entire home or cloud subnet. Pure, identity-based least-privilege access.

---

## Enterprise GitOps: Monorepo Flux D2

A dark cluster is only half the battle. Managing clusters imperatively via `kubectl apply` breaks down when managing multiple environments.

To manage workloads declaratively without opening inbound CI/CD ports, we implemented the **ControlPlane Enterprise Flux D2** pattern directly in our monorepo:

- **Branchless OCI Delivery**: On every commit to `main`, GitHub Actions packages our Kubernetes configurations into versioned OCI artifacts on GitHub Container Registry (`ghcr.io/xnok/infra-bootstrap-tools/manifests/*`).
- **Fleet vs. Add-ons Separation**:
  - `fleet/<cluster>`: Manages cluster-specific bootstrap (`FluxInstance`), source repos, and override ConfigMaps.
  - `infra-addons`: Packages shared, reusable platform components (cert-manager, trust-manager, openziti, keycloak) as Kustomize components.
- **Values Layering**: We established a strict rule: **never use `spec.values` in HelmRelease**. By relying exclusively on `valuesFrom` ConfigMaps tagged with `reconcile.fluxcd.io/watch: Enabled`, default configurations shipped with platform add-ons can be overridden seamlessly on a per-cluster basis.

---

## Key Takeaways & Lessons Learned

Building this stack revealed several crucial architectural gotchas that are not documented in standard tutorials:

1. **Watch Annotations are Mandatory**: Flux HelmReleases do not react to ConfigMap updates immediately unless annotated with `reconcile.fluxcd.io/watch: Enabled`. Without this, cluster updates will silently wait for the background polling interval.
2. **`postBuild` Shell Escaping**: When using Flux's `postBuild.substituteFrom` to inject cluster names, any shell variable like `${TOKEN}` in mounted scripts gets erased! Escaping them as `$${TOKEN}` in the source manifests completely resolves the problem.
3. **trust-manager Namespace Gotcha**: `trust-manager` can only read CA bundles from a single `--trust-namespace`. While its default is `cert-manager`, OpenZiti creates its signing secret inside `openziti`. Designing for this early saves hours of debugging TLS handshake failures.
4. **Local Testing is Paramount**: We created `make test-flux-d2`, which spins up a Kind cluster and a local Docker registry in seconds, pushing local manifests and asserting router enrollment. Testing the entire mesh locally eliminated cloud iteration delays.

---

## Next Steps

The entire automation suite—including Ansible roles for host hardening (`k3s_os_hardening`), declarative K3s installation (`k3s_server`), and the complete Flux D2 manifest tree—is now available and documented in the repository:

- Explore the **[Dark K3s Architecture Guide]({{< relref "docs/kubernetes/k1.overview.md" >}})**
- Follow the **[Getting Started Quickstart]({{< relref "docs/gs1.getting_started.md" >}})**
- Check out the **[Local Kind Test Harness]({{< relref "docs/kubernetes/k7.local_testing_kind.md" >}})**
