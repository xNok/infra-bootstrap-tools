---
type: project
status: proposed
description: Architectural evaluation and implementation strategy for managing OpenZiti zero-trust overlay entities (services, configs, and policies) declaratively in GitOps
related_projects:
  - dark-k3s-stack
  - install-kubeopencode-k3s
related_areas:
  - security-identity
  - kubernetes-fleet
---

# Declarative Zero-Trust Overlay Management for OpenZiti

## 1. Context & Problem Statement

The dark K3s cluster (`ns3118807`) operates without open public ingress ports. All administrative and web services are routed privately through an in-cluster **OpenZiti** overlay network. 

Currently, the stack exhibits an architectural split between the **infrastructure plane** and the **overlay entity plane**:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        K3S CLUSTER ARCHITECTURE                        │
│                                                                        │
│  1. INFRASTRUCTURE PLANE (100% Declarative via GitOps)                 │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ Flux -> HelmRelease -> ziti-controller, ziti-router              │  │
│  │ cert-manager -> Certificates & trust-manager CA distribution      │  │
│  │ PersistentVolumes, Secrets & NetworkPolicies                     │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│  2. OVERLAY ENTITY PLANE (Imperative / In-Database State)              │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ OpenZiti Internal Edge Database (bbolt)                          │  │
│  │ - Intercept & Host Configs: k3s.ziti, flux.ziti, opencode.ziti   │  │
│  │ - Services: k3s, flux-ui, opencode                               │  │
│  │ - Bind & Dial Policies: @ziti-router, #k3s-clients                │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### The Friction & Operational Risks
1. **Configuration Drift**: If an engineer or subagent adds an overlay service via `ziti edge create ...` in an interactive shell, that configuration is not tracked in version control.
2. **Disaster Recovery Friction**: If the persistent volume for `ziti-controller` is recreated, corrupted, or migrated (e.g. promoting from local `kind` to remote `k3s`), all overlay services vanish and must be manually reprovisioned via CLI commands.
3. **Lack of Peer Review for Network Access**: Zero-trust dial and bind policies dictate which client identities can reach sensitive cluster endpoints. These security rules should undergo standard Git pull-request reviews.

**Objective**: Establish a declarative, GitOps-driven mechanism to define, reconcile, and audit OpenZiti overlay entities alongside our Kubernetes applications.

---

## 2. Target Services to Declaratively Manage

The initial rollout will cover the cluster's existing dark services:

| Service Name | Intercept Address | Cluster Target Destination | Client Roles | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `k3s` | `k3s.ziti:6443` | `127.0.0.1:6443` | `#k3s-clients` | Kubernetes API control plane |
| `flux-ui` | `flux.ziti:80`<br>`flux.ziti:9080` | `flux-operator.flux-system.svc.cluster.local:9080` | `#k3s-clients` | Flux Operator status dashboard |
| `opencode` | `opencode.ziti:80`<br>`opencode.ziti:2746` | `kubeopencode-server.kubeopencode-system.svc.cluster.local:2746` | `#k3s-clients` | KubeOpenCode Agentic UI Dashboard |
| *(Future)* `agents` | `agent-*.ziti` | Dedicated per-namespace agent endpoints | `#k3s-clients` | Direct agent API access |

---

## 3. Architectural Options Evaluated

### Option A: Kubernetes Operator (`ziti-k8s-operator` / CRDs)

- **Mechanism**: Deploy a custom Kubernetes operator in the cluster that introduces CRDs such as `ZitiApp`, `ZitiIdentity`, and `ZitiServicePolicy`.
- **How it Works**: Applications declare a `ZitiApp` manifest directly in their GitOps folder (e.g. `kubernetes/apps/kubeopencode/ziti-service.yaml`). The operator watches these CRs and communicates with the OpenZiti Edge Management API over `localhost:1280`.
- **Manifest Example**:
  ```yaml
  apiVersion: openziti.io/v1alpha1
  kind: ZitiApp
  metadata:
    name: opencode
    namespace: kubeopencode-system
  spec:
    intercept:
      addresses: ["opencode.ziti"]
      ports: [80, 2746]
    destination:
      service: kubeopencode-server.kubeopencode-system.svc.cluster.local
      port: 2746
    dialRoles: ["#k3s-clients"]
    bindRoles: ["@ziti-router"]
  ```
- **Pros**:
  - Native Kubernetes developer experience: developers declare network ingress directly alongside `Deployment` and `Service`.
  - Self-healing: if an entity is accidentally modified or deleted in OpenZiti, the operator automatically restores it.
- **Cons**:
  - Community/third-party operator dependency; requires ongoing maintenance and compatibility testing with new OpenZiti controller versions.

---

### Option B: OpenZiti Terraform / OpenTofu Provider (`netfoundry/ziti`)

- **Mechanism**: Use the official, upstream-maintained OpenZiti Terraform provider (`netfoundry/ziti`).
- **How it Works**: Define overlay resources in HCL under `kubernetes/fleet/k3s/infra-addons/openziti/overlay/`. Reconcile via Flux `TF-Controller` or a GitHub Actions CI workflow.
- **Manifest Example**:
  ```hcl
  resource "ziti_config" "opencode_intercept" {
    name   = "opencode-intercept"
    type   = "intercept.v1"
    data   = jsonencode({
      addresses  = ["opencode.ziti"]
      portRanges = [{ low = 80, high = 80 }, { low = 2746, high = 2746 }]
      protocols  = ["tcp"]
    })
  }

  resource "ziti_config" "opencode_host" {
    name   = "opencode-host"
    type   = "host.v1"
    data   = jsonencode({
      address  = "kubeopencode-server.kubeopencode-system.svc.cluster.local"
      port     = 2746
      protocol = "tcp"
    })
  }

  resource "ziti_service" "opencode" {
    name    = "opencode"
    configs = [ziti_config.opencode_intercept.id, ziti_config.opencode_host.id]
  }

  resource "ziti_service_policy" "opencode_dial" {
    name           = "opencode-dial"
    type           = "Dial"
    service_roles  = ["@${ziti_service.opencode.name}"]
    identity_roles = ["#k3s-clients"]
  }
  ```
- **Pros**:
  - Official, first-party support from NetFoundry / OpenZiti maintainers.
  - Comprehensive coverage of every OpenZiti API feature (posture checks, MFA, edge router policies, auth policies).
  - Robust drift detection and planning stages (`terraform plan`).
- **Cons**:
  - Requires running a Terraform/OpenTofu engine (e.g. Flux TF-Controller) or remote state management.

---

### Option C: In-Tree Declarative GitOps Sync Job (Zero-Dependency)

- **Mechanism**: Store a declarative YAML manifest of desired services in Git. A lightweight Kubernetes `Job` or periodic `CronJob` reconciles the desired state against the local OpenZiti Edge REST API using the admin credentials from `openziti-ziti-controller-admin-secret`.
- **How it Works**:
  1. Define `dark-services.yaml` in `kubernetes/fleet/k3s/infra-addons/openziti/`:
     ```yaml
     services:
       - name: k3s
         intercept: { addresses: ["k3s.ziti"], ports: [6443] }
         host: { address: "127.0.0.1", port: 6443 }
         dialRoles: ["#k3s-clients"]
       - name: flux-ui
         intercept: { addresses: ["flux.ziti"], ports: [80, 9080] }
         host: { address: "flux-operator.flux-system.svc.cluster.local", port: 9080 }
         dialRoles: ["#k3s-clients"]
       - name: opencode
         intercept: { addresses: ["opencode.ziti"], ports: [80, 2746] }
         host: { address: "kubeopencode-server.kubeopencode-system.svc.cluster.local", port: 2746 }
         dialRoles: ["#k3s-clients"]
     ```
  2. A small Python or bash sync script runs on GitOps commit via a Flux post-rollout hook or Kustomize Job. It calls the OpenZiti REST API, creating or updating configs, services, and policies idempotently.
- **Pros**:
  - **Zero extra controllers**: No CRD operators or Terraform controllers to install or maintain.
  - Lightweight and 100% reproducible across `kind` and `k3s`.
  - Immediate implementation path.
- **Cons**:
  - Sync logic must be maintained in-house.

---

## 4. Evaluation Matrix

| Criterion | Option A: K8s Operator | Option B: Terraform Provider | Option C: In-Tree Sync Job |
| :--- | :--- | :--- | :--- |
| **Upstream Support** | Community | **Official (NetFoundry)** | In-Tree |
| **GitOps Integration** | Native K8s CRDs | High (via TF-Controller / CI) | **High (Kustomize / Job)** |
| **Infrastructure Overhead** | Medium (New Controller) | Medium (TF Controller Pods) | **Zero (One-shot Job)** |
| **Feature Completeness** | Basic Services/Identities | **Full OpenZiti Edge Suite** | Targeted Services |
| **Disaster Recovery** | Automatic | Automatic | Automatic |
| **Cluster Portability** | Good | Excellent | **Excellent** |

---

## 5. Recommended Implementation Plan

### Phase 1: In-Tree Declarative Sync Job (Immediate Win)
1. Create `dark-services.yaml` containing the canonical desired state for `k3s`, `flux-ui`, and `opencode`.
2. Package an idempotent sync script (`bin/openziti/sync-dark-services.py` or `.sh`) using the OpenZiti Management REST API.
3. Wire the sync script as a Kubernetes `Job` managed via Flux in `kubernetes/fleet/k3s/infra-addons/` triggered on ConfigMap change.
4. Verify disaster recovery: clear the controller test service and confirm the Job restores `opencode.ziti` automatically.

### Phase 2: Upstream Operator / OpenTofu Evaluation (Long Term)
1. As the agent fleet expands to multi-tenant clusters requiring dynamic posture checks and automated per-agent identity provisioning, evaluate adopting the upstream Terraform provider or an official Kubernetes Gateway API integration.
