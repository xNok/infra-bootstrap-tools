---
type: project
status: active
description: Architecture, security model, and registration flow for running KubeOpenCode agents authenticated via GitHub Apps using Flux multi-tenancy, two-tier applier lifecycle, and least privilege
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

This project designs and implements the architecture, security model, and GitOps registration flow for running **OpenCode** agents in **KubeOpenCode** authenticated via **GitHub Apps**, adopting the official **Flux Multi-Tenancy Architecture**, **Two-Tier Composable Applier Lifecycle**, and **Least-Privilege Workload Isolation**.

---

## 1. Deep Architectural Research: Official Flux & Flux Operator Patterns

Research from the official **CNCF Flux CD documentation** (`fluxcd.io`, `fluxcd/flux2-multi-tenancy`) and the **Flux Operator** (`fluxoperator.dev`, ControlPlane) reveals critical design principles for multi-tenant GitOps:

### A. The Core Security Boundaries & Impersonation
By default, Flux controllers operate with cluster-wide privileges (`cluster-admin`). In multi-tenant environments, this creates extreme risks of privilege escalation and lateral movement.
The official Flux pattern achieves strict isolation via **Kubernetes Service Account Impersonation**:
1. Platform administrators configure Flux API objects (`Kustomization` or `HelmRelease`) with `.spec.serviceAccountName`.
2. When reconciling, the controller impersonates this specific Kubernetes ServiceAccount.
3. The Kubernetes API server evaluates all requests against the RBAC permissions (`Role` and `RoleBinding`) bound to that ServiceAccount.
4. If a tenant attempts to deploy unauthorized primitives (such as `apps/v1` `Deployment`, `DaemonSet`, or `core/v1` `Pod`), the API server immediately denies the request with `403 Forbidden`.

### B. Control-Plane Lockdown Mechanisms
In official Flux and Flux Operator multi-tenancy mode (`FluxInstance.spec.cluster.multitenant: true` or controller flags):
- **`--no-cross-namespace-refs=true`**: Forbids tenant custom resources in namespace A from referencing sources, secrets, or targets in namespace B.
- **`--no-remote-bases=true`**: Forbids Kustomize from fetching arbitrary unauthenticated remote git URLs (`https://github.com/...`) on the fly during reconciliation. All source fetches must be brokered through Flux's `source-controller` (`GitRepository` or `OCIRepository`) with managed credentials, commit verification, and audit logging.
- **`--default-service-account`**: Enforces that any resource omitting `serviceAccountName` drops back to a restricted default rather than inheriting cluster-admin.

### C. The Two Fundamental Planes
Official Flux architectures (`flux2-multi-tenancy`) strictly partition GitOps into two separate planes:
1. **Platform Admin Plane (Tenant Enrollment)**:
   - Resides in the platform/infrastructure GitOps repository.
   - Provisions the tenant's security envelope: `Namespace`, `NetworkPolicy`, `ExternalSecret`, tenant applier `ServiceAccount`, and RBAC `RoleBinding`.
   - Applied by a high-privilege **Tenant Enrollment Applier** (or platform controller).
   - **Crucial Rule**: The tenant never has write access to this plane.
2. **Tenant Workload Plane (Tenant Delivery)**:
   - Resides in the tenant repository (`.kubeopencode/`).
   - Declares the workload intent (`AgentTemplate`, `Agent`, `CronTask`, `Task`).
   - Applied by the **Tenant Workload Applier** (`tenant-<repo>-applier`) which is restricted exclusively to `kubeopencode.io/*`.

---

## 2. Evaluation of Architectural Approaches

| Approach | Mechanics | Benefits | Risks & Vulnerabilities | Intuition & Composability |
| :--- | :--- | :--- | :--- | :--- |
| **Approach 1: Single Lump Overlay (Rejected)** | A single `kustomization.yaml` contains `Namespace`, `applier-rbac`, `github-app-token`, and the upstream base. | Minimal file count. | **Severe Privilege Paradox**: A tenant applier cannot create its own `Role` or `Namespace`. If given RBAC write rights, the tenant can escalate to cluster-admin. No apply ordering. | Low; mixes platform infrastructure with developer application manifests. |
| **Approach 2: Two-Tier Sub-Overlays (`0-enrollment` + `1-workload`) [Adopted]** | Each tenant directory is divided into `0-enrollment/` (platform envelope) and `1-workload/` (agent workload + overlay patch). | **Zero Privilege Leakage**: Tenant applier only touches `1-workload`.<br>**Deterministic Ordering**: `1-workload` depends on `0-enrollment`.<br>**Composable**: Platform and developer planes are decoupled. | Requires two apply stages (orchestrated via Flux `dependsOn` or multi-tier Kustomize). | **High**: Immediately clear separation between Day-1 Tenant Onboarding and Day-2 Agent Operations. |
| **Approach 3: Flux Operator `ResourceSet` Factory** | Platform defines a parameterized `ResourceSet` custom resource that stamps out the namespace, RBAC, and child Kustomization for any registered repository. | Very DRY for onboarding 50+ repositories from a single config file. | Adds abstraction indirection; harder to inspect raw compiled manifests; tightly coupled to Flux Operator CRDs. | High for platform teams managing hundreds of repos, but excessive for initial dogfooding. |
| **Approach 4: Custom Tenant Controller / CRD** | A custom Kubernetes operator watches a `Tenant` CRD and reconciles the namespace, RBAC, and ExternalSecret. | Pure Kubernetes API experience. | Requires writing, compiling, releasing, and maintaining a custom controller; premature optimization. | High API ergonomics, high maintenance overhead. |

---

## 3. Recommended & Implemented Architecture: Two-Tier Composable Model

### Directory Structure

```
kubernetes/apps/
├── kustomization.yaml                          # Root apps kustomization
└── tenants/
    ├── cncf-landscape-a-to-z/                  # Tenant 1: External repo
    │   ├── 0-enrollment/                       # Platform Security & Identity Envelope
    │   │   ├── namespace.yaml                  # Namespace: tenant-cncf-landscape (PSS: restricted)
    │   │   ├── applier-rbac.yaml               # ServiceAccount tenant-cncf-landscape-applier (kubeopencode.io only)
    │   │   ├── controller-rbac.yaml            # Scopes kubeopencode-controller to tenant namespace
    │   │   ├── github-app-token.yaml           # ESO GithubAccessToken generator -> Secret github-creds
    │   │   ├── network-policy.yaml             # Egress firewall (DNS, GitHub HTTPS, LLM APIs)
    │   │   └── kustomization.yaml
    │   ├── 1-workload/                         # Developer Agent Workloads
    │   │   ├── base/
    │   │   │   └── kustomization.yaml          # URL: https://github.com/mekitmedia/cncf-landscape-a-to-z//.kubeopencode?ref=main
    │   │   ├── patch-agent-template.yaml       # Injects credentials, bot git identity, security context
    │   │   └── kustomization.yaml
    │   └── kustomization.yaml                  # Aggregates 0-enrollment & 1-workload
    │
    └── infra-bootstrap-tools/                  # Tenant 2: Current repo (dogfooding)
        ├── 0-enrollment/                       # Platform Security & Identity Envelope
        │   ├── namespace.yaml                  # Namespace: tenant-infra-bootstrap-tools (PSS: restricted)
        │   ├── applier-rbac.yaml               # ServiceAccount tenant-infra-bootstrap-tools-applier (kubeopencode.io only)
        │   ├── controller-rbac.yaml            # Scopes kubeopencode-controller to tenant namespace
        │   ├── github-app-token.yaml           # ESO GithubAccessToken generator -> Secret github-creds
        │   ├── network-policy.yaml             # Egress firewall (DNS, GitHub HTTPS, LLM APIs)
        │   └── kustomization.yaml
        ├── 1-workload/                         # Developer Agent Workloads
        │   ├── base/
        │   │   └── kustomization.yaml          # URL: https://github.com/xNok/infra-bootstrap-tools//.kubeopencode?ref=main
        │   ├── patch-agent-template.yaml       # Injects credentials, bot git identity, security context
        │   └── kustomization.yaml
        └── kustomization.yaml                  # Aggregates 0-enrollment & 1-workload

.kubeopencode/                                  # Pure upstream agent intent for infra-bootstrap-tools
├── agent-template.yaml                         # Pure intent template (NO secretRef)
├── agents.yaml                                 # Agent CR: infra-bootstrap-agent
├── crontask-docs-audit.yaml                    # CronTask: scheduled docs & nix audit
└── kustomization.yaml
```

---

## 4. Privilege Matrix & Security Enforcement

| Resource Type | Managed in Layer | Applied By | Permissions Granted |
| :--- | :--- | :--- | :--- |
| `Namespace` | `0-enrollment/` | Platform Enrollment Applier | Full control over tenant namespace lifecycle |
| `NetworkPolicy` | `0-enrollment/` | Platform Enrollment Applier | Egress firewall: DNS + HTTPS to internet, blocks internal RFC1918 subnets |
| `ExternalSecret` & `GithubAccessToken` | `0-enrollment/` | Platform Enrollment Applier | Mints GitHub App IAT tokens rotated every 50m |
| `ServiceAccount` (`tenant-*-applier`) | `0-enrollment/` | Platform Enrollment Applier | Lives in `flux-system` (required for Flux impersonation) |
| `Role` & `RoleBinding` (Applier) | `0-enrollment/` | Platform Enrollment Applier | Authorizes applier **strictly** for `kubeopencode.io/*` inside tenant namespace |
| `Role` & `RoleBinding` (Controller) | `0-enrollment/` | Platform Enrollment Applier | Authorizes `kubeopencode-controller` to manage agent pods/jobs inside tenant namespace |
| `AgentTemplate`, `Agent`, `CronTask` | `1-workload/` | Tenant Workload Applier (`tenant-*-applier`) | Read/write access on `kubeopencode.io/*` only |
| `apps/v1` `Deployment`, `DaemonSet` | **Forbidden** | N/A | **Zero permissions**. Rejected by Kubernetes API server with `403 Forbidden` |
| `core/v1` `Pod`, `Secret`, `PV` | **Forbidden** | N/A | **Zero permissions**. Workload applier cannot create pods or secrets directly |

---

## 5. Apply Ordering in Fleet Delivery

In cluster deployments (such as `kubernetes/fleet/k3s/` or `kind/`), delivery is structured into two stages using Flux's dependency engine:

```yaml
# Stage 1: Tenant Enrollment (applied by Platform Reconciler)
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: tenant-infra-bootstrap-enrollment
  namespace: flux-system
spec:
  interval: 1h
  path: ./tenants/infra-bootstrap-tools/0-enrollment
  prune: true
  sourceRef:
    kind: OCIRepository
    name: apps
---
# Stage 2: Tenant Workload (applied by Tenant Applier, depends on Stage 1)
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: tenant-infra-bootstrap-workload
  namespace: flux-system
spec:
  interval: 10m
  path: ./tenants/infra-bootstrap-tools/1-workload
  prune: true
  serviceAccountName: tenant-infra-bootstrap-tools-applier
  sourceRef:
    kind: OCIRepository
    name: apps
  dependsOn:
    - name: tenant-infra-bootstrap-enrollment
```

### Guarantees:
1. **Determinism**: The `tenant-infra-bootstrap-enrollment` stage verifies that the `Namespace`, `NetworkPolicy`, `ExternalSecret` (`github-creds`), and applier `ServiceAccount` exist before any agent template is processed.
2. **Hard Isolation**: The workload reconciliation is executed by `tenant-infra-bootstrap-tools-applier`. Even if an upstream contributor submits a malicious PR adding a cryptominer `Deployment` into `.kubeopencode/`, the apply step fails with `403 Forbidden`.
3. **Consistency**: Both `cncf-landscape-a-to-z` and `infra-bootstrap-tools` reference their `.kubeopencode` via `https://github.com/<owner>/<repo>//.kubeopencode?ref=main`, establishing a uniform standard for all future repositories onboarded to the platform.

---

## 6. Deep Dive: The Privilege Escalation Paradox

A central question in GitOps multi-tenancy is: **Can a tenant create or mutate its own `applier-rbac.yaml`?**

### The Paradox:
- If a tenant applier possesses the RBAC permissions to apply `applier-rbac.yaml`, it must possess `create`, `update`, and `patch` verbs on `rbac.authorization.k8s.io/roles` and `rbac.authorization.k8s.io/rolebindings` (or `clusterroles` and `clusterrolebindings`).
- In Kubernetes RBAC, anyone with `create` or `escalate` rights on `RoleBinding` can bind themselves or any service account to `cluster-admin` or high-privilege roles.
- Even with namespace-scoped RBAC, an attacker with `RoleBinding` write access can bind to existing cluster roles inside the namespace or read all secrets in that namespace (including ESO secrets, cloud credentials, or external tokens).
- Therefore, **the tenant cannot be responsible for creating its own applier RBAC**.

### The Solution: Two Distinct Identities & Lifecycles
```
┌──────────────────────────────────────────────────────────────────┐
│ PLATFORM PLANE (Day 1 Onboarding)                                │
│ Actor: Tenant Enrollment Applier (Platform Reconciler)          │
│ Privilege: High / Platform Admin                                 │
│ Scope: Cluster-wide / Namespace creation                         │
│ Actions:                                                         │
│   1. Creates Namespace: tenant-<repo>                            │
│   2. Creates ServiceAccount: tenant-<repo>-applier in flux-sys   │
│   3. Grants Role to tenant-<repo>-applier (kubeopencode.io ONLY) │
│   4. Deploys ExternalSecret (GitHub App token broker)            │
│   5. Enforces Egress NetworkPolicy                               │
└────────────────────────────────┬─────────────────────────────────┘
                                 │ Hands off control
                                 ▼
┌──────────────────────────────────────────────────────────────────┐
│ TENANT PLANE (Day 2 Agent Operations)                            │
│ Actor: Tenant Workload Applier (tenant-<repo>-applier)           │
│ Privilege: Strictly Least-Privilege                              │
│ Scope: tenant-<repo> namespace only                              │
│ Actions:                                                         │
│   1. Applies AgentTemplate, Agent, CronTask                      │
│   2. ZERO rights on Role, RoleBinding, Secret, Pod, Deployment   │
│   3. Completely incapable of escalating its own permissions      │
└──────────────────────────────────────────────────────────────────┘
```

---

## 7. Source Acquisition: Remote Kustomize Bases vs `source-controller`

Two main mechanisms exist for referencing upstream `.kubeopencode/` manifests from external repositories:

### Option A: Kustomize Remote Bases (`https://github.com/...//.kubeopencode?ref=main`)
- **How it works**: Kustomize executes an unauthenticated `git clone` during manifest generation.
- **Benefits**: Simple file syntax in `kustomization.yaml`; requires no custom resources.
- **Risks & Drawbacks**:
  - **Violates Flux Multi-Tenancy**: Official Flux multi-tenancy enforces `--no-remote-bases=true` to prevent arbitrary egress and unauthenticated code execution.
  - **No Caching / High Latency**: Every reconciliation clones the entire repository afresh.
  - **Fragile Branch Resolution**: Pointing to `?ref=main` fails during PR testing when the `.kubeopencode` folder only exists in a feature branch.
  - **No Webhook Triggers**: Cannot respond instantly to GitHub push webhooks.

### Option B: Flux `source-controller` (`GitRepository` CRD) [Recommended for Fleet]
- **How it works**: A Flux `GitRepository` custom resource tracks the external repository, handles git authentication (deploy keys, GitHub App tokens), verifies commit signatures (GPG/Cosign), and caches the git tree locally in `flux-system`.
- **Benefits**:
  - **Native Caching**: `source-controller` maintains local bare repositories and serves tarballs over HTTP within the cluster.
  - **Authenticated & Private Repos**: Seamlessly uses `secretRef` to access private tenant repositories.
  - **Webhook Support**: Notified immediately by GitHub Actions webhooks via Flux `Receiver`.
  - **Enforces `--no-remote-bases`**: Eliminates remote base fetching entirely.

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: tenant-cncf-landscape
  namespace: flux-system
spec:
  interval: 10m
  url: https://github.com/mekitmedia/cncf-landscape-a-to-z.git
  ref:
    branch: main
  ignore: |
    /*
    !/.kubeopencode
```

---

## 8. Tenant Factory Automation: 2-Tier Directory vs Flux Operator `ResourceSet`

| Dimension | Two-Tier Sub-Overlays (`0-enrollment` + `1-workload`) | Flux Operator `ResourceSet` Factory |
| :--- | :--- | :--- |
| **Mechanics** | Static YAML files per tenant committed to Git. | A single `ResourceSet` CR takes an `inputs` list of repositories and generates all tenant manifests in memory. |
| **Boilerplate** | Moderate (each tenant has a directory with 7 YAML files). | **Minimal**: Onboarding a tenant requires adding 5 lines to an `inputs` array. |
| **Transparency & Auditability** | **Complete**: Every generated manifest is visible in git, lintable by `yamllint`, and reviewable in PR diffs. | Lower: Manifests are rendered dynamically in cluster memory by the Flux Operator controller. |
| **Tooling Compatibility** | Works with standard `kubectl kustomize`, Flux CLI, and GitOps tools. | Requires `flux-operator` CRDs (`fluxcd.controlplane.io/v1`). |
| **Best For** | 1-10 tenants where explicit control and individual review are paramount. | 20+ enterprise tenants where automated self-service onboarding is required. |

### Worked Example: `ResourceSet` Tenant Factory
```yaml
apiVersion: fluxcd.controlplane.io/v1
kind: ResourceSet
metadata:
  name: kubeopencode-tenants
  namespace: flux-system
spec:
  inputs:
    - name: cncf-landscape-a-to-z
      repo: https://github.com/mekitmedia/cncf-landscape-a-to-z.git
      branch: main
      appId: "123456"
      installId: "7891011"
    - name: infra-bootstrap-tools
      repo: https://github.com/xNok/infra-bootstrap-tools.git
      branch: main
      appId: "123456"
      installId: "7891012"
  resources:
    - apiVersion: v1
      kind: Namespace
      metadata:
        name: tenant-<< inputs.name >>
        labels:
          pod-security.kubernetes.io/enforce: restricted
    - apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: tenant-<< inputs.name >>-applier
        namespace: flux-system
    - apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        name: tenant-<< inputs.name >>-applier-role
        namespace: tenant-<< inputs.name >>
      rules:
        - apiGroups: ["kubeopencode.io"]
          resources: ["agents", "agenttemplates", "crontasks", "tasks"]
          verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
        - apiGroups: [""]
          resources: ["configmaps"]
          verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

---

## 9. Defense-in-Depth: Kyverno Admission Control

RBAC operates at the API boundary, but Kyverno admission control provides a kernel-level policy engine that validates invariants regardless of RBAC permissions.

We introduce [`tenant-workload-isolation`](file:///kubernetes/apps/tenants/policies/tenant-workload-isolation.yaml) with two critical enforcement rules:

### Rule 1: `disallow-unauthorized-workloads`
- **Target**: Namespaces matching `tenant-*`.
- **Blocked Kinds**: `Deployment`, `StatefulSet`, `DaemonSet`, `ReplicaSet`.
- **Action**: `Enforce` (Hard Rejection).
- **Rationale**: Tenants must NEVER run arbitrary long-running container daemons, cryptominers, or unmanaged web servers. Only the `kubeopencode-controller` is permitted to spawn ephemeral task execution pods.

### Rule 2: `require-tenant-applier-service-account`
- **Target**: `Kustomization` resources in `flux-system` with `targetNamespace: tenant-*`.
- **Validation**: Enforces that `spec.serviceAccountName` matches `tenant-*-applier`.
- **Action**: `Enforce`.
- **Rationale**: Prevents accidental platform reconciliation where a cluster-admin Flux runner applies tenant manifests without dropping privileges.

---

## 10. Summary Comparison & Decision Matrix

| Requirement | 1-Tier Mixed Kustomize | 2-Tier Sub-Overlays (Current) | Flux Operator ResourceSet | 2-Tier + Kyverno Admission (Adopted) |
| :--- | :--- | :--- | :--- | :--- |
| **No Privilege Escalation** | ❌ Broken (Self-RBAC) | ✅ RBAC Separated | ✅ Template Separated | 🌟 **Dual Gate: RBAC + Kyverno Admission** |
| **Apply Ordering** | ❌ None | ✅ Flux `dependsOn` | ✅ Native CRD gating | ✅ **Flux `dependsOn` state machine** |
| **Source Management** | ❌ Raw Kustomize clone | ⚠️ Remote URLs | ✅ `source-controller` | ✅ **Remote URL / `source-controller`** |
| **Defense Against Rogue Workloads** | ⚠️ RBAC only | ⚠️ RBAC only | ⚠️ RBAC only | 🌟 **Kyverno Enforce (Deny Deployment/DaemonSet)** |
| **Auditability & Tooling** | ⚠️ Tangled | ✅ Pure standard YAML | ⚠️ Go-template string | ✅ **Pure standard YAML + Kyverno Policy** |

