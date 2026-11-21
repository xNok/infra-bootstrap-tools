---
type: resource
description: Architectural design, security posture, and step-by-step configuration for running a Dark Kubernetes (K3s) control plane accessible solely over OpenZiti zero-trust mesh
related_resources:
  - openziti
related_projects:
  - dark-k3s-stack
---

# Dark Kubernetes: Zero-Ingress Cluster Control Plane

## Overview

The standard deployment pattern for Kubernetes exposes the API server (`kube-apiserver` on port `6443/TCP`) to the public internet or requires a legacy VPN. Even with strong TLS certificates and RBAC, exposing port 6443 invites continuous automated port scans, brute-force attempts, and zero-day API server vulnerability exposure.

The **Dark Kubernetes** pattern fundamentally eliminates this attack surface by:
1. Binding the Kubernetes API server strictly to `127.0.0.1` on the control plane node.
2. Closing port `6443` on all external firewalls and public network interfaces.
3. Hosting the API server as an OpenZiti dark service.
4. Authorizing operators to dial the API server via cryptographically verified OpenZiti client certificates.

To the outside internet, the Kubernetes control plane does not exist.

---

## 1. Architectural Topology

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        DARK KUBERNETES TOPOLOGY                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ OPERATOR LAPTOP (Client)                                                    │
│    • Runs kubectl cluster-info                                              │
│    • Target: https://k3s.ziti:6443                                          │
│    • ziti-edge-tunnel intercepts virtual DNS (k3s.ziti)                      │
│    • Encrypts payload with client mTLS identity certificate                 │
├─────────────────────────────────────────────────────────────────────────────┤
│ PUBLIC INTERNET (Transit)                                                   │
│    • Zero open ports on K3s node (port 6443 CLOSED)                         │
│    • Only public port: OpenZiti Edge Router (443/TCP or 8444/TCP)           │
│    • Traffic travels over end-to-end encrypted OpenZiti mesh circuit        │
├─────────────────────────────────────────────────────────────────────────────┤
│ K3S SERVER NODE (Dark Host)                                                 │
│    • OpenZiti Host identity binds service k3s-api                           │
│    • Terminates overlay tunnel and forwards to local 127.0.0.1:6443         │
│    • K3s API server processes request safely behind loopback interface      │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Server-Side Configuration (K3s & Ansible)

In our Ansible role `ansible/roles/k3s_server`, the dark control plane is enabled via the `k3s_server_use_openziti_dark` flag:

```yaml
# host_vars/k3s-server.yml
k3s_server_use_openziti_dark: true
k3s_server_bind_address: "127.0.0.1"
```

When enabled:
- K3s `config.yaml` sets `bind-address: "127.0.0.1"`.
- Host firewall (`ufw` or cloud security groups) drops all inbound traffic on port `6443`.
- The K3s cluster certificate includes `k3s.ziti` in its Subject Alternative Names (`tls-san: ["k3s.ziti"]`).

---

## 3. OpenZiti Service Declaration

To route traffic from the mesh to the loopback API server, the OpenZiti controller configures:

### 1. Intercept Configuration (`intercept.v1`)
Tells client tunnels what virtual hostname and port to intercept:
```json
{
  "addresses": ["k3s.ziti"],
  "portRanges": [{"low": 6443, "high": 6443}],
  "protocols": ["tcp"]
}
```

### 2. Host Configuration (`host.v1`)
Tells the terminating host router where to forward incoming packets:
```json
{
  "address": "127.0.0.1",
  "port": 6443,
  "protocol": "tcp"
}
```

### 3. Service & Policies
- Service: `k3s-api`
- Bind Policy: Grants `@k3s-server-node` permission to host the service.
- Dial Policy: Grants `#k8s-admins` permission to connect to the service.

---

## 4. Operator Workflow: Connecting via `kubectl`

1. Start `ziti-edge-tunnel` daemon with an enrolled identity in the `#k8s-admins` role.
2. In your `~/.kube/config`, target the virtual OpenZiti address:
   ```yaml
   apiVersion: v1
   clusters:
     - cluster:
         certificate-authority-data: <k3s-ca-data>
         server: https://k3s.ziti:6443
       name: dark-k3s
   ```
3. Run standard commands:
   ```bash
   kubectl get nodes
   kubectl get pods -A
   ```
   The traffic is automatically captured by OpenZiti's local DNS interceptor, routed over the encrypted overlay, and delivered directly to the loopback interface of the K3s server.
