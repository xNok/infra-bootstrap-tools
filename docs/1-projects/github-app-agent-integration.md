---
type: project
status: active
description: Architecture, security model, and registration flow for running KubeOpenCode agents authenticated via GitHub Apps using Kustomize remote bases and least-privilege appliers
related_projects:
  - agentic-framework
  - kubernetes-flux-d2
related_resources:
  - kubeopencode
  - external-secrets-operator
  - github-apps
related_areas:
  - ai-workflow-automation
  - kubernetes-gitops
---

# GitHub App Integration for OpenCode & KubeOpenCode

## Overview

This project designs and implements the architecture, security model, and GitOps registration flow for running **OpenCode** agents in **KubeOpenCode** authenticated via **GitHub Apps**, adopting the **Flux Tenant Pattern (Tenant per Repo)** and **Remote Kustomize Base Overlays**.

### Core Principles

1. **Tenant per Repo Isolation**: Each onboarded repository is treated as an isolated tenant with its own dedicated namespace, least-privilege applier ServiceAccount, least-privilege controller RBAC, and egress firewall.
2. **Natural Upstream Convention (`.kubeopencode/`)**: Upstream repository authors define pure workload intent (prompt, models, tasks) under `.kubeopencode/` with an in-tree `kustomization.yaml` and **zero secret bindings**.
3. **Remote Kustomize Base Overlays**: The central infrastructure (`infra-bootstrap-tools`) references the upstream repository directly via a URL as a Kustomize base (`https://github.com/<owner>/<repo>//.kubeopencode?ref=main`). Central overlays inject credentials, Git bot committer identities, and security contexts without redundant in-cluster Flux CR loops.
4. **Least-Privilege Tenant Applier**: Manifests are applied to the cluster using an applier ServiceAccount whose RBAC permissions strictly allow only `kubeopencode.io/*` and tenant resources. Crucially, permissions for `apps/v1` `Deployment`, `batch/v1` `Job`, or `core/v1` `Pod` are withheld, preventing an upstream tenant repository from installing unauthorized workloads.
5. **Self-Dogfooding**: The pattern is applied to both external repositories (e.g. [`cncf-landscape-a-to-z`](https://github.com/mekitmedia/cncf-landscape-a-to-z)) and this repository itself ([`infra-bootstrap-tools`](https://github.com/xNok/infra-bootstrap-tools)), providing an immediate in-tree reference implementation.

---

## Directory Organization

```
kubernetes/apps/
├── kustomization.yaml                      # Root apps kustomization
└── tenants/
    ├── cncf-landscape-a-to-z/              # Tenant 1: External repo
    │   ├── base/
    │   │   └── kustomization.yaml          # Base pointing to remote URL (cncf-landscape-a-to-z)
    │   ├── namespace.yaml                  # Namespace: tenant-cncf-landscape
    │   ├── applier-rbac.yaml               # Least-privilege applier SA & Role (blocks Deployments)
    │   ├── controller-rbac.yaml            # Scopes kubeopencode-controller to this namespace
    │   ├── network-policy.yaml             # Egress firewall (DNS, GitHub HTTPS, LLM APIs)
    │   ├── github-app-token.yaml           # ESO GithubAccessToken -> Secret github-creds
    │   ├── patch-agent-template.yaml       # Injects credentials & bot committer identity
    │   └── kustomization.yaml              # Bundles base, local manifests, and patches
    └── infra-bootstrap-tools/              # Tenant 2: Current repo (dogfooding)
        ├── base/
        │   └── kustomization.yaml          # Base pointing to in-tree .kubeopencode
        ├── namespace.yaml                  # Namespace: tenant-infra-bootstrap-tools
        ├── applier-rbac.yaml               # Least-privilege applier SA & Role (blocks Deployments)
        ├── controller-rbac.yaml            # Scopes kubeopencode-controller to this namespace
        ├── network-policy.yaml             # Egress firewall (DNS, GitHub HTTPS, LLM APIs)
        ├── github-app-token.yaml           # ESO GithubAccessToken -> Secret github-creds
        ├── patch-agent-template.yaml       # Injects credentials & bot committer identity
        └── kustomization.yaml              # Bundles base, local manifests, and patches

.kubeopencode/                              # Pure upstream agent intent for infra-bootstrap-tools
├── agent-template.yaml                     # Pure intent template (NO secretRef)
├── agents.yaml                             # Agent CR: infra-bootstrap-agent
├── crontask-docs-audit.yaml                # CronTask: scheduled docs & nix audit
└── kustomization.yaml
```

---

## Architecture Diagram (Remote Base & Applier Model)

```
┌────────────────────────────────────────────────────────┐
│ GitHub Repositories                                    │
│                                                        │
│  [mekitmedia/cncf-landscape-a-to-z]                    │
│  └── .kubeopencode/ (Pure intent: agent + tasks)       │
│                                                        │
│  [xNok/infra-bootstrap-tools]                          │
│  └── .kubeopencode/ (Pure intent: agent + tasks)       │
└──────────────────────────┬─────────────────────────────┘
                           │
                           │ 1. Kustomize resolves remote base URL
                           │ 2. Dynamic Token Generation (GitHub App via ESO)
                           ▼
┌────────────────────────────────────────────────────────┐
│ Central GitOps Repository (infra-bootstrap-tools)       │
│ kubernetes/apps/tenants/                               │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Tenant: cncf-landscape-a-to-z                    │  │
│  │ - Base: https://github.com/...//.kubeopencode    │  │
│  │ - Namespace: tenant-cncf-landscape               │  │
│  │ - Applier SA: tenant-cncf-landscape-applier      │  │
│  │   (Restricted RBAC: NO Deployments/Pods)         │  │
│  │ - Controller RBAC: namespaced RoleBinding        │  │
│  │ - Overlay Patch: injects credentials & bot comm  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Tenant: infra-bootstrap-tools (Dogfooding)       │  │
│  │ - Base: in-tree .kubeopencode                    │  │
│  │ - Namespace: tenant-infra-bootstrap-tools        │  │
│  │ - Applier SA: tenant-infra-bootstrap-applier     │  │
│  │   (Restricted RBAC: NO Deployments/Pods)         │  │
│  │ - Controller RBAC: namespaced RoleBinding        │  │
│  │ - Overlay Patch: injects credentials & bot comm  │  │
│  └──────────────────────────────────────────────────┘  │
└──────────────────────────┬─────────────────────────────┘
                           │
                           │ 3. Applied by Least-Privilege Applier SA
                           ▼
┌────────────────────────────────────────────────────────┐
│ Kubernetes Cluster (e.g. k3s / kind)                   │
│                                                        │
│  [flux-system Namespace]                               │
│  ├── ServiceAccount 'tenant-cncf-landscape-applier'    │
│  └── ServiceAccount 'tenant-infra-bootstrap-applier'   │
│                                                        │
│  [kubeopencode-system Namespace]                       │
│  └── Controller Pod (kubeopencode-controller)          │
│                                                        │
│  [tenant-cncf-landscape Namespace]                     │
│  ├── ExternalSecret 'github-creds' (auto-rotated)      │
│  ├── NetworkPolicy (egress lockdown)                   │
│  └── Agent Pods (cncf-landscape-agent)                 │
│                                                        │
│  [tenant-infra-bootstrap-tools Namespace]              │
│  ├── ExternalSecret 'github-creds' (auto-rotated)      │
│  ├── NetworkPolicy (egress lockdown)                   │
│  └── Agent Pods (infra-bootstrap-agent)                │
└────────────────────────────────────────────────────────┘
```

---

## 1. Tenant Specification & Manifests

Each tenant is a self-contained directory under `kubernetes/apps/tenants/<repo-name>/`:

### A. Namespace (`namespace.yaml`)
Creates `tenant-<repo-name>` with Pod Security Standard `restricted`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-infra-bootstrap-tools
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
    app.kubernetes.io/part-of: infra-bootstrap-tools
    app.kubernetes.io/component: tenant-runtime
```

### B. Least-Privilege Tenant Applier (`applier-rbac.yaml`)
When the tenant manifests are applied, the apply step impersonates `tenant-<repo-name>-applier`.
The `Role` grants permissions **only** for `kubeopencode.io/*` CRDs, External Secrets, NetworkPolicy, and local ConfigMaps/Secrets/ServiceAccounts:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tenant-infra-bootstrap-tools-applier
  namespace: flux-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: tenant-infra-bootstrap-tools-applier-role
  namespace: tenant-infra-bootstrap-tools
rules:
  # Allow managing KubeOpenCode CRDs
  - apiGroups: ["kubeopencode.io"]
    resources: ["agents", "agenttemplates", "crontasks", "tasks"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  # Allow External Secrets Operator primitives
  - apiGroups: ["external-secrets.io"]
    resources: ["externalsecrets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["generators.external-secrets.io"]
    resources: ["githubaccesstokens"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  # Allow NetworkPolicy
  - apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  # Allow managing tenant-scoped RBAC
  - apiGroups: ["rbac.authorization.k8s.io"]
    resources: ["roles", "rolebindings"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  # Allow ConfigMaps, Secrets, ServiceAccounts
  - apiGroups: [""]
    resources: ["configmaps", "secrets", "serviceaccounts"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: tenant-infra-bootstrap-tools-applier-binding
  namespace: tenant-infra-bootstrap-tools
subjects:
  - kind: ServiceAccount
    name: tenant-infra-bootstrap-tools-applier
    namespace: flux-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: tenant-infra-bootstrap-tools-applier-role
```

> [!SECURITY]
> **Preventing Arbitrary Workload Installation**:
> The `tenant-*-applier-role` intentionally contains **NO rules** for:
> - `apps/v1` (`Deployment`, `StatefulSet`, `DaemonSet`, `ReplicaSet`)
> - `batch/v1` (`Job`, `CronJob`)
> - `core/v1` (`Pod`)
> If an upstream tenant attempts to define a `Deployment` or run cryptominers in `.kubeopencode/`, the Kubernetes API server will reject the apply operation with `403 Forbidden`. Only the trusted controller can spawn worker pods when executing authorized tasks.

### C. Controller Least-Privilege RBAC (`controller-rbac.yaml`)
Binds `kubeopencode-controller` to a namespaced `Role` inside `tenant-<repo-name>`, granting pod and CRD reconciliation rights **exclusively inside this namespace**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: kubeopencode-controller-tenant-role
  namespace: tenant-infra-bootstrap-tools
rules:
  - apiGroups: ["kubeopencode.io"]
    resources:
      - agents
      - agents/status
      - agents/finalizers
      - agenttemplates
      - crontasks
      - tasks
      - tasks/status
      - tasks/finalizers
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["pods", "pods/exec", "pods/log", "pods/status", "configmaps", "secrets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["batch"]
    resources: ["jobs", "jobs/status"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: kubeopencode-controller-tenant-binding
  namespace: tenant-infra-bootstrap-tools
subjects:
  - kind: ServiceAccount
    name: kubeopencode-controller
    namespace: kubeopencode-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: kubeopencode-controller-tenant-role
```

### D. Egress Firewall (`network-policy.yaml`)
Locks down the tenant's agent pods:
- Ingress: Intra-namespace only.
- Egress: DNS (port 53), HTTPS (port 443) to internet (GitHub, LLMs).
- Denies all RFC1918 internal subnets (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) and cloud metadata (`169.254.169.254/32`).

### E. GitHub App Token Broker (`github-app-token.yaml`)
- ESO's `GithubAccessToken` generator configured with `appID` and `installID`.
- `ExternalSecret` creates `github-creds` and rotates every 50 minutes.

### F. Central Overlay & Remote Base (`base/kustomization.yaml` + `patch-agent-template.yaml`)
- `base/kustomization.yaml` sets `namespace: tenant-<name>` and references the remote base URL:
  ```yaml
  apiVersion: kustomize.config.k8s.io/v1beta1
  kind: Kustomization
  namespace: tenant-cncf-landscape
  resources:
    - https://github.com/mekitmedia/cncf-landscape-a-to-z//.kubeopencode?ref=main
  ```
- `spec.patches` in `kustomization.yaml` overlays `credentials`, security contexts, and bot git identity without touching the upstream repository.

---

## 2. Dogfooding: The `infra-bootstrap-tools` Tenant & Agent

To provide a concrete starting point, `infra-bootstrap-tools` defines its own agent under `.kubeopencode/`:
- **`agent-template.yaml`**: Pure intent definition:
  - `repository: https://github.com/xNok/infra-bootstrap-tools.git`
  - Images: OpenCode init container + Devbox worker.
  - Model: `google/gemini-flash-lite-latest`.
  - Zero secrets defined.
- **`agents.yaml`**: `Agent` resource `infra-bootstrap-agent`.
- **`crontask-docs-audit.yaml`**: Weekly scheduled task auditing repository documentation, Nix flake dependencies, and GitOps sync state.
- **`kustomization.yaml`**: Standard Kustomize entrypoint bundling the agent manifests.
