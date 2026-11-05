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

## 2. Why Ansible Manages the Node DNS on Bare-Metal VPS

In managed clouds (AWS EKS, DigitalOcean Kubernetes), `external-dns` is the default choice because cloud controllers dynamically allocate LoadBalancer IPs from cloud pools.

On a **single bare-metal VPS**:
1. **No Cloud LoadBalancer**: There is no AWS ELB or DigitalOcean Managed LB controller allocating external IPs.
2. **Fixed Host Public IP**: The server has one static public IP (`147.135.212.219`) attached directly to its network interface at boot.
3. **Pre-Reconciliation Guarantee**: Ansible discovers `ansible_default_ipv4.address` and creates the DigitalOcean A record (`ziti.nokwebspace.ovh -> 147.135.212.219`) **before** Kubernetes or OpenZiti start. When Flux reconciles OpenZiti, the domain is already resolvable worldwide.
4. **Zero In-Cluster Overhead**: Avoids deploying an extra in-cluster controller pod, CRDs, and storing DigitalOcean API secrets inside Kubernetes just to publish one static node IP.

### Ansible Automated Task Pattern
In `ansible/roles/k3s_flux_bootstrap/tasks/main.yaml`:
```yaml
- name: Ensure DigitalOcean DNS A record for OpenZiti exists
  ansible.builtin.uri:
    url: "https://api.digitalocean.com/v2/domains/{{ k3s_flux_bootstrap_dns_domain }}/records"
    method: POST
    headers:
      Authorization: "Bearer {{ k3s_flux_bootstrap_digitalocean_token }}"
      Content-Type: "application/json"
    body_format: json
    body:
      type: "A"
      name: "{{ k3s_flux_bootstrap_dns_subdomain }}"
      data: "{{ ansible_default_ipv4.address }}"
      ttl: 300
    status_code: [200, 201, 422]
  when: k3s_flux_bootstrap_digitalocean_token is defined
```

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
