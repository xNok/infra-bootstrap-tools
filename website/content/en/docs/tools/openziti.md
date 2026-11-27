---
title: "OpenZiti: Programmable Zero-Trust Mesh"
slug: openziti
description: "How OpenZiti enables Dark Kubernetes clusters, eliminates public API exposure, and delivers programmable zero-trust overlay networking."
tags:
  - zero-trust
  - openziti
  - networking
  - security
  - kubernetes
---

## What is OpenZiti?

[OpenZiti](https://openziti.io/) is an open-source, programmable zero-trust networking platform that embeds secure connectivity directly into applications and infrastructures. Instead of relying on traditional IP addresses, firewalls, and subnets, OpenZiti creates a dynamic, end-to-end encrypted overlay network based on **cryptographic identity**.

In `infra-bootstrap-tools`, OpenZiti is used to build **Dark K3s**: hiding the Kubernetes API server behind a zero-trust mesh so that port `6443` is never exposed to the public internet.

---

## Why OpenZiti Over Traditional VPNs?

| Feature | Traditional VPN (WireGuard/OpenVPN) | OpenZiti Zero-Trust Mesh |
| :--- | :--- | :--- |
| **Network Access Model** | Coarse-grained subnet access (connects you to the entire network) | Fine-grained service access (connects you strictly to authorized endpoints) |
| **Inbound Public Ports** | Requires opening public UDP ports (e.g. 51820) | Target services require **zero open inbound ports** (Dark Services) |
| **Identity & Authentication** | Pre-shared keys or basic user/password | Mutual TLS (mTLS) with short-lived x509 certificates and OIDC/JWT integration |
| **DNS Management** | Complex split-DNS and DNS routing tables | Transparent, programmable client-side DNS interception (e.g. `k3s.ziti`) |

---

## OpenZiti Components in This Project

![Dark K3s Zero-Trust Network Topology](/images/diagrams/dark-k3s-zero-trust-topology.png)

1. **Ziti Controller**: The central control plane and policy engine. Manages identity enrollment, issues certificates, and validates authorization policies.
2. **Ziti Edge Router**: The high-performance data plane daemon running as an in-cluster pod. Tunnels mesh traffic to internal loopback services (`127.0.0.1:6443`).
3. **Automated Router Enrollment Job**: A Kubernetes Job (`enroll-router.sh`) that provisions router identities and generates enrollment JWTs automatically on boot.
4. **`ziti-edge-tunnel`**: A lightweight client daemon running on the administrator's workstation that intercepts DNS queries and transparently routes traffic over the mesh.

---

## Interacting with OpenZiti

### Enrolling an Administrator Identity

```bash
# Enroll your identity using a one-time enrollment JWT:
ziti-edge-tunnel enroll --jwt admin.jwt --identity /opt/openziti/identities/admin.json

# Start the tunnel daemon:
sudo ziti-edge-tunnel run --identity-dir /opt/openziti/identities
```

Once the daemon is running, navigating to `https://k3s.ziti:6443` or running `kubectl` works seamlessly—without exposing any ports or configuring hosts files.

---

## Further Reading

- [Zero-Trust Mesh with OpenZiti Guide]({{< relref "../kubernetes/k5.openziti_mesh.md" >}}): Architectural deep dive into router enrollment, ALPN ports, and in-cluster networking.
- [Node Hardening & Firewall (UFW)]({{< relref "../kubernetes/k2.os_hardening.md" >}}): How the host firewall drops public traffic and opens ports 8441/8442 for Ziti listeners.
