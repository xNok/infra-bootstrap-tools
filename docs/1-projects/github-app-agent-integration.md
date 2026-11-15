---
type: project
status: active
description: Architecture, security model, and registration flow for running KubeOpenCode agents authenticated via GitHub Apps using the Flux Tenant Pattern
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

This project designs and implements the architecture, security model, and GitOps registration flow for running **OpenCode** agents in **KubeOpenCode** authenticated via **GitHub Apps**, adopting the **Flux Tenant Pattern (Tenant per Repo)**.

### Core Principles

1. **Tenant per Repo Isolation**: Each onboarded repository is treated as a first-class Flux tenant with its own dedicated namespace, restricted `ServiceAccount`, least-privilege controller RBAC, and egress firewall.
2. **Central Overlay with Pure Upstream Intent**: Upstream repository authors define pure workload intent (prompt, models, tasks) under `k8s/kubeopencode/` with **zero secret bindings**. The central infrastructure (`infra-bootstrap-tools`) acts as a **Kustomize Overlay** via Flux patches to inject credentials, Git bot committer identities, and security contexts.
3. **Self-Dogfooding**: The pattern is applied to both external repositories (e.g. [`cncf-landscape-a-to-z`](https://github.com/mekitmedia/cncf-landscape-a-to-z/tree/main/k8s/kubeopencode)) and this repository itself ([`infra-bootstrap-tools`](https://github.com/xNok/infra-bootstrap-tools)), providing an immediate in-tree reference implementation.

---

## Directory Organization: Flux Tenant Pattern

```
kubernetes/apps/
├── kustomization.yaml                      # Root apps kustomization
└── tenants/
    ├── cncf-landscape-a-to-z/              # Tenant 1: External repo
    │   ├── namespace.yaml                  # Namespace: tenant-cncf-landscape
    │   ├── tenant-rbac.yaml                # Flux impersonation SA & restricted Role
    │   ├── controller-rbac.yaml            # Scopes kubeopencode-controller to this namespace
    │   ├── network-policy.yaml             # Egress firewall (DNS, GitHub HTTPS, LLM APIs)
    │   ├── github-app-token.yaml           # ESO GithubAccessToken -> Secret github-creds
    │   ├── patch-agent-template.yaml       # Injects credentials & bot committer identity
    │   ├── flux-source.yaml                # GitRepository & Kustomization (SA: flux-tenant-sa)
    │   └── kustomization.yaml
    └── infra-bootstrap-tools/              # Tenant 2: Current repo (dogfooding)
        ├── namespace.yaml                  # Namespace: tenant-infra-bootstrap-tools
        ├── tenant-rbac.yaml                # Flux impersonation SA & restricted Role
        ├── controller-rbac.yaml            # Scopes kubeopencode-controller to this namespace
        ├── network-policy.yaml             # Egress firewall (DNS, GitHub HTTPS, LLM APIs)
        ├── github-app-token.yaml           # ESO GithubAccessToken -> Secret github-creds
        ├── patch-agent-template.yaml       # Injects credentials & bot committer identity
        ├── flux-source.yaml                # GitRepository & Kustomization (SA: flux-tenant-sa)
        └── kustomization.yaml

k8s/kubeopencode/                           # Pure upstream agent intent for infra-bootstrap-tools
├── agent-template.yaml                     # Pure intent template (NO secretRef)
├── agents.yaml                             # Agent CR: infra-bootstrap-agent
├── crontask-docs-audit.yaml                # CronTask: scheduled docs & nix audit
└── kustomization.yaml
```

---

## Architecture Diagram (Flux Tenant Pattern)

```
┌────────────────────────────────────────────────────────┐
│ GitHub Repositories                                    │
│                                                        │
│  [mekitmedia/cncf-landscape-a-to-z]                    │
│  └── k8s/kubeopencode/ (Pure intent: agent + tasks)    │
│                                                        │
│  [xNok/infra-bootstrap-tools]                          │
│  └── k8s/kubeopencode/ (Pure intent: agent + tasks)    │
└──────────────────────────┬─────────────────────────────┘
                           │
                           │ 1. GitOps Sync per Tenant
                           │ 2. Dynamic Token Generation (GitHub App)
                           ▼
┌────────────────────────────────────────────────────────┐
│ Central GitOps Repository (infra-bootstrap-tools)       │
│ kubernetes/apps/tenants/                               │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Tenant: cncf-landscape-a-to-z                    │  │
│  │ - Namespace: tenant-cncf-landscape               │  │
│  │ - Flux SA: flux-tenant-sa (locked to namespace)  │  │
│  │ - Controller RBAC: namespaced RoleBinding        │  │
│  │ - Overlay Patch: injects credentials & bot comm  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Tenant: infra-bootstrap-tools (Dogfooding)       │  │
│  │ - Namespace: tenant-infra-bootstrap-tools        │  │
│  │ - Flux SA: flux-tenant-sa (locked to namespace)  │  │
│  │ - Controller RBAC: namespaced RoleBinding        │  │
│  │ - Overlay Patch: injects credentials & bot comm  │  │
│  └──────────────────────────────────────────────────┘  │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│ Kubernetes Fleet Cluster (e.g. k3s / kind)             │
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
    app.kubernetes.io/component: agent-runtime
```

### B. Tenant Flux RBAC (`tenant-rbac.yaml`)
Flux impersonates `flux-tenant-sa` when reconciling the tenant repository. The `Role` grants permissions **only** for `kubeopencode.io/*` CRDs and local ConfigMaps:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flux-tenant-sa
  namespace: tenant-infra-bootstrap-tools
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: flux-tenant-role
  namespace: tenant-infra-bootstrap-tools
rules:
  - apiGroups: ["kubeopencode.io"]
    resources: ["agents", "agenttemplates", "crontasks", "tasks"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: flux-tenant-rolebinding
  namespace: tenant-infra-bootstrap-tools
subjects:
  - kind: ServiceAccount
    name: flux-tenant-sa
    namespace: tenant-infra-bootstrap-tools
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: flux-tenant-role
```

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

### F. Central Overlay & Flux Source (`flux-source.yaml` + `patch-agent-template.yaml`)
- `GitRepository` pulls the repository's `k8s/kubeopencode/`.
- `Kustomization` applies manifests into `tenant-<repo-name>` using `serviceAccountName: flux-tenant-sa`.
- `spec.patches` overlays `credentials` and bot git identity without touching the upstream repository.

---

## 2. Dogfooding: The `infra-bootstrap-tools` Tenant & Agent

To provide a concrete starting point, `infra-bootstrap-tools` defines its own agent under `k8s/kubeopencode/`:
- **`agent-template.yaml`**: Pure intent definition:
  - `repository: https://github.com/xNok/infra-bootstrap-tools.git`
  - Images: OpenCode init container + Devbox worker.
  - Model: `google/gemini-flash-lite-latest`.
  - Zero secrets defined.
- **`agents.yaml`**: `Agent` resource `infra-bootstrap-agent`.
- **`crontask-docs-audit.yaml`**: Weekly scheduled task auditing repository documentation, Nix flake dependencies, and GitOps sync state.
