---
type: project
status: active
description: DNS management automation and bare-metal LoadBalancer architecture for the Dark K3s Stack
related_projects:
  - dark-k3s-stack
related_resources:
  - openziti
related_areas:
  - networking
  - infra-orchestration
---

# DNS Management & Bare-Metal Load Balancing Strategy

This document captures the design decisions, trade-offs, and multi-node roadmap for DNS automation and load balancing across the Dark K3s Stack.

---

## 1. DNS Management: Cert-Manager vs. ExternalDNS vs. Ansible

When designing cloud-agnostic GitOps infrastructure, confusion often arises around which component manages DNS:

| Component | Primary Function | Can it manage A / CNAME records? | Typical Use Case |
| :--- | :--- | :--- | :--- |
| **`cert-manager`** | TLS Certificate Lifecycle (X.509) | **No** (Only creates temporary `TXT` records for ACME DNS-01 challenges) | Issuing TLS certificates from Let's Encrypt or in-cluster CA |
| **`external-dns`** | Cloud-native DNS Synchronization | **Yes** (Creates `A`, `AAAA`, `CNAME`, `TXT` records) | Automatically pointing domains to cloud-allocated LoadBalancer IPs or Ingresses |
| **`ansible`** | Host Provisioning & Bootstrap | **Yes** (Via provider REST API or modules) | Pointing domain names to static bare-metal VPS node IPs during host bootstrap |

---

## 2. Evolution: From Static Ansible DNS to Dynamic ExternalDNS

### Initial Baseline (Single Node Static VPS)
On a single fixed-IP VPS, Ansible was initially configured to provision the DigitalOcean A record (`ziti.nokwebspace.ovh -> 147.135.212.219`) before cluster bootstrap to guarantee immediate DNS resolution with zero in-cluster overhead.

### The Multi-Node / Burst Compute Challenge
When expanding from 1 node to 2+ nodes (e.g. adding a second VPS or on-prem node for temporary burst compute), a static host-provisioning approach breaks down:
1. **Manual Upkeep**: Adding or terminating nodes would require re-running Ansible playbooks manually from an external workstation to adjust DNS records.
2. **Delayed Ingress**: New edge routers or workloads on temporary compute nodes would not be reachable until DNS is manually updated.
3. **Ghost Records**: Terminated nodes would leave stale A records pointing to defunct IPs until manually cleaned up.

### Why ExternalDNS + DNS Round-Robin is an Ideal Solution
By running **ExternalDNS** as an in-cluster GitOps addon:
1. **Autonomic Lifecycle**: ExternalDNS continuously watches Kubernetes `Service` and `Node` resources. When a new node joins K3s and ServiceLB (Klipper) schedules the edge router onto it, ExternalDNS immediately detects the new external IP and publishes an additional `A` record in DigitalOcean.
2. **Native DNS Round-Robin**: DigitalOcean DNS supports multiple `A` records for the same hostname. Clients querying `ziti.nokwebspace.ovh` receive both IPs in round-robin order.
3. **OpenZiti Mesh Synergy**:
   - Unlike HTTP browsers where a dead IP can cause connection timeouts or 502 errors before DNS caches expire, OpenZiti SDKs and `ziti-edge-tunnel` natively iterate over all resolved DNS addresses until a healthy connection is made.
   - Furthermore, OpenZiti edge routers interconnect into a mesh fabric. Traffic arriving at Router 1 on Node 1 is routed dynamically across the fabric to service terminators on Node 2 (and vice versa).
4. **Clean Decoupling via Ansible Bootstrap**:
   - Ansible's role narrows down to its proper scope: host bootstrap and initial secret provisioning.
   - Ansible retrieves the DigitalOcean API token from 1Password and creates a single Kubernetes Secret (`digitalocean-dns`) in the `external-dns` namespace.
   - From that point onward, the cluster manages its own external DNS records autonomically.

---

## 3. Load Balancing Strategy: Today vs. Multi-Node Expansion

### Current State: K3s ServiceLB (Klipper)
* **How it works**: K3s includes an embedded controller called **Klipper-LB** (ServiceLB).
* When a Service is configured with `type: LoadBalancer` (ports `1280` and `8442` for OpenZiti), Klipper binds the ports on the host and automatically populates `status.loadBalancer.ingress[0].ip: 147.135.212.219`.
* **Verdict**: Perfect for single-node setups. Zero installation, zero external dependencies.

### Future Multi-Node Expansion Roadmap
When expanding from 1 node to a multi-node cluster, Klipper cannot provide floating Virtual IPs (VIPs) or sub-second failover. The roadmap for multi-node on-prem:

| Solution | Architecture | Floating VIP Failover | When to Choose |
| :--- | :--- | :--- | :--- |
| **MetalLB** | Controller + Speaker DaemonSet (L2 ARP or BGP) | ✅ Yes | The undisputed industry standard for bare-metal Kubernetes services. |
| **Kube-VIP** | Lightweight static pod or DaemonSet | ✅ Yes | When you also need a floating VIP for the K3s Control Plane API (`:6443`) in multi-master setups. |
| **Cilium CNI** | Native L2 Announce / BGP in eBPF CNI | ✅ Yes | If migrating the entire cluster CNI from Flannel to Cilium. |

### How MetalLB Plugs into the "AWS Addon" GitOps Model
When multi-node expansion happens:
1. Disable Klipper in K3s: `--disable servicelb`.
2. Add **MetalLB** as a generic component in `kubernetes/infra-addons/components/metallb/`.
3. Configure the cluster IP pool via fleet values in `kubernetes/fleet/k3s/infra-addons/values/metallb.values.yaml`:
   ```yaml
   ipAddressPools:
     - name: default-pool
       addresses:
         - 192.168.1.200-192.168.1.220
   ```
4. Fleet `1-kustomize.yaml` remains **100% patch-free**.
