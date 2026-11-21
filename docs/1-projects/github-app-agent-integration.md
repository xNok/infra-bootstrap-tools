---
type: project
status: active
description: Architecture, security model, and registration flow for running KubeOpenCode agents authenticated via GitHub Apps using Flux multi-tenancy, two-tier applier lifecycle, ResourceSet factory, and least privilege
related_projects:
  - agentic-framework
  - kubernetes-flux-d2
related_resources:
  - kubeopencode
  - external-secrets-operator
  - github-apps
  - flux-artifact-generator
related_areas:
  - ai-workflow-automation
  - kubernetes-gitops
---

# GitHub App Integration for OpenCode & KubeOpenCode

## Overview

This project designs and implements the architecture, security model, and GitOps registration flow for running **OpenCode** agents in **KubeOpenCode** authenticated via **GitHub Apps**, adopting the official **Flux Multi-Tenancy Architecture**, **Two-Tier Composable Applier Lifecycle**, **Flux Operator ResourceSet Factory**, and **Least-Privilege Workload Isolation**.

---

## 1. Deep Architectural Research: Official Flux & Flux Operator Patterns

Research from the official **CNCF Flux CD documentation** ([Service Account Reference](https://fluxcd.io/flux/components/kustomize/kustomizations/#service-account-reference), `fluxcd/flux2-multi-tenancy`) and the **Flux Operator** ([ResourceSet CRD](https://fluxoperator.dev/docs/crd/resourceset/), [ResourceSetInputProvider CRD](https://fluxoperator.dev/docs/crd/resourcesetinputprovider/)) reveals critical design principles for multi-tenant GitOps:

### A. The Core Security Boundaries & Service Account Impersonation
By default, Flux controllers operate with cluster-wide privileges (`cluster-admin`). In multi-tenant environments, this creates extreme risks of privilege escalation and lateral movement.
The official Flux pattern achieves strict isolation via **Kubernetes Service Account Impersonation**:
1. Platform administrators configure Flux API objects (`Kustomization` or `HelmRelease`) with `.spec.serviceAccountName`.
2. When reconciling, the `kustomize-controller` impersonates this specific Kubernetes ServiceAccount via Kubernetes API impersonation headers.
3. The Kubernetes API server evaluates all requests against the RBAC permissions (`Role` and `RoleBinding`) bound to that ServiceAccount.
4. If a tenant attempts to deploy unauthorized primitives (such as `apps/v1` `Deployment`, `DaemonSet`, or `core/v1` `Pod`), the API server immediately denies the request with `403 Forbidden`.

### B. Control-Plane Lockdown Mechanisms
In official Flux and Flux Operator multi-tenancy mode (`FluxInstance.spec.cluster.multitenant: true` or controller flags):
- **`--no-cross-namespace-refs=true`**: Forbids tenant custom resources in namespace A from referencing sources, secrets, or targets in namespace B.
- **`--no-remote-bases=true`**: Forbids Kustomize from fetching arbitrary unauthenticated remote git URLs (`https://github.com/...`) on the fly during reconciliation. All source fetches must be brokered through Flux's `source-controller` (`GitRepository` or `OCIRepository`) with managed credentials, commit verification, and audit logging.
- **`--default-service-account`**: Enforces that any resource omitting `serviceAccountName` drops back to a restricted default rather than inheriting cluster-admin.

### C. The Two Fundamental Planes & The Flaw of Mixed Kustomize Overlays
Official Flux architectures strictly partition GitOps into two separate planes:
1. **Platform Admin Plane (Tenant Enrollment)**:
   - Resides in the platform/infrastructure GitOps repository.
   - Provisions the tenant's security envelope: `Namespace`, `NetworkPolicy`, `ExternalSecret`, tenant applier `ServiceAccount`, and RBAC `RoleBinding`.
   - Applied by a high-privilege **Tenant Enrollment Applier** (or platform controller).
   - **Crucial Rule**: The tenant never has write access to this plane.
2. **Tenant Workload Plane (Tenant Delivery)**:
   - Resides in the tenant repository (`.kubeopencode/`).
   - Declares the workload intent (`AgentTemplate`, `Agent`, `CronTask`, `Task`).
   - Applied by the **Tenant Workload Applier** (`tenant-<repo>-applier`) which is restricted exclusively to `kubeopencode.io/*`.

> [!CAUTION]
> **The Flaw of Mixed Kustomize Overlays**:
> If a tenant directory contains a `kustomization.yaml` that simply aggregates:
> ```yaml
> resources:
>   - 0-enrollment
>   - 1-workload
> ```
> then standard Kustomize flattens all manifests into a single stream. When the platform reconciler applies this stream, it applies `1-workload` directly as `cluster-admin`!
> The tenant applier ServiceAccount is **never impersonated**. Furthermore, Kustomize attempts to perform unauthenticated remote git clones against upstream URLs at build time, failing under sandboxed or offline environments.
> To preserve the separation of concerns, `1-workload` **must never** be included in the platform Kustomization. It must be delivered through a Flux `Kustomization` CR (or `ResourceSet`) that explicitly sets `.spec.serviceAccountName: tenant-<name>-applier` and `.spec.targetNamespace: tenant-<name>`.

---

## 2. Complementary Paradigms: Shared Agent Catalogue vs. Sovereign Tenant Agents

A crucial architectural principle of this system is that **the new Tenant Onboarding pattern does NOT invalidate the Agent Catalogue pattern** previously established. They are complementary layers addressing different operational models:

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           AGENT PLATFORM TAXONOMY                               │
├──────────────────────────────────────┬──────────────────────────────────────────┤
│ 1. THE SHARED AGENT CATALOGUE        │ 2. THE SOVEREIGN TENANT PATTERN          │
│ (e.g. Palette Agent)                 │ (e.g. .kubeopencode/ in tenant repos)    │
├──────────────────────────────────────┼──────────────────────────────────────────┤
│ • Focus: Reusable Agent Roles        │ • Focus: Repository Sovereignty & Domain │
│ • Governance: Platform/Central Team  │ • Governance: Repository Developers      │
│ • Experiment in Reusability:         │ • Decentralized Intent:                  │
│   Shared templates (AgentTemplate,   │   Custom Agent, AgentTemplate, CronTasks │
│   CronTask) curated in catalogue     │   committed directly to .kubeopencode/   │
│ • Namespace: Central/shared          │ • Namespace: Dedicated tenant boundary   │
│   (e.g. agentic-workflows)          │   (tenant-<repo> with PSS: restricted)   │
│ • Reusability: Write once, target    │ • Identity: Isolated GitHub App token    │
│   multiple repos from central runner │   minted per-tenant via ExternalSecrets  │
│ • Security: Platform-managed SA      │ • Security: Least-privilege tenant applier│
│                                      │   (kubeopencode.io/* only) + egress fw   │
└──────────────────────────────────────┴──────────────────────────────────────────┘
```

### How They Coexist and Interlock:
1. **The Shared Agent Catalogue (`kubernetes/apps/kubeopencode-agents/`)**:
   - Acts as an internal "app store" for agents with specialized personas.
   - Example: **Palette** (`palette-agent-template`) is an experiment in a reusable, focused UX and accessibility auditor. Any repository can be targeted by Palette without having to author prompts, configure images, or reinvent UX guidelines.
   - The catalogue lives in `kubernetes/apps` and is deployed centrally to `agentic-workflows`.
2. **The Sovereign Tenant Pattern (`kubernetes/apps/tenants/` & `.kubeopencode/`)**:
   - Solves the problem of repository-owned, custom agent workflows. A development team can define bespoke prompts, cron schedules, and agent definitions specific to their application domain.
   - Provides a hardened security envelope (`tenant-<name>`) with its own short-lived GitHub App tokens, network egress controls, and impersonated appliers.
3. **The Synergistic Intersection**:
   - A tenant repository's `.kubeopencode/` can either define entirely custom agents **OR** reference/overlay a template from the Shared Agent Catalogue.
   - In either case, the execution occurs safely within the tenant's isolated security boundary. The two patterns reinforce each other.

---

## 3. Evaluation of Architectural Approaches

| Dimension | Approach 1: Single Lump Overlay | Approach 2: Static 2-Tier with Flux CRs | Approach 3: Static `ResourceSet` Factory (Adopted) | Approach 4: Dynamic `ResourceSetInputProvider` |
| :--- | :--- | :--- | :--- | :--- |
| **Mechanics** | One `kustomization.yaml` combining envelope and workload. | `0-enrollment/` + `flux-kustomization.yaml` emitting a child Flux `Kustomization` CR. | Parameterized `ResourceSet` CR templating envelope, SA, and child Kustomization from static `inputs`. | `ResourceSet` fed by `ResourceSetInputProvider` querying an external API, GitHub PRs, or tags. |
| **Privilege Isolation** | ❌ Broken (Runs as cluster-admin; self-RBAC paradox). | ✅ **Strict**: Workload applied via SA impersonation. | ✅ **Strict**: Workload applied via SA impersonation. | ✅ **Strict**: Workload applied via SA impersonation. |
| **Apply Ordering** | ❌ None (Random batch apply). | ✅ Flux `dependsOn` state machine. | ✅ Native `spec.steps` or `dependsOn`. | ✅ Native `spec.steps` or `dependsOn`. |
| **Boilerplate & Scaling** | Minimal files, fatal security flaws. | Moderate (7-9 YAML files per tenant committed to Git). | **Zero boilerplate** (5 lines in `inputs:` per tenant). | **Zero Git commits** (automated discovery from external system). |
| **Garbage Collection Lifecycle** | ❌ High risk of orphan deadlock if SA deleted before resources. | ⚠️ Requires manual sequencing when deleting tenants. | 🌟 **Native Staged GC**: Prunes workloads via SA *before* deleting SA & namespace. | 🌟 **Native Staged GC**: Prunes workloads via SA *before* deleting SA & namespace. |
| **Tooling & Auditability** | Raw YAML. | **100% standard YAML**, visible in PR diffs, lintable. | Dynamic rendering in-cluster; inspected via `kubectl describe rset`. | Dynamic in-cluster; inspected via `kubectl describe rsip,rset`. |
| **Best For** | Anti-pattern; do not use. | Small installations (1-10 tenants) needing explicit git reviews per tenant. | **Current State (2 Repos)**: Ideal dogfooding with minimal footprint. | Future scaling (20+ tenants, Gitless GitOps, PR previews). |

---

## 4. Implemented Architecture: Cluster-Root Factory with File-Based Workload Overlays

### Directory Structure

```
kubernetes/fleet/k3s/apps/
├── 0-source.yaml                               # OCIRepository source: apps
├── kubeopencode/                               # KubeOpenCode controller deployment
├── palette-agent/                              # Palette agent instance
├── tenants.yaml                                # Flux Operator ResourceSet Factory (Cluster Root Envelope)
└── kustomization.yaml                          # Aggregates sources, controllers, agents, and tenants factory

kubernetes/apps/
├── kustomization.yaml                          # Root apps kustomization (kubeopencode, palette, policies)
└── tenants/
    ├── policies/                               # Admission control policies
    │   ├── kustomization.yaml
    │   └── tenant-workload-isolation.yaml      # CEL-based ValidatingPolicies
    │
    ├── cncf-landscape-a-to-z/                  # Tenant 1: External repo
    │   └── 1-workload/                         # Developer Agent Workloads (applied by child Flux Kustomization)
    │       ├── base/
    │       │   └── kustomization.yaml          # URL: https://github.com/mekitmedia/cncf-landscape-a-to-z//.kubeopencode?ref=main
    │       ├── patch-agent-template.yaml       # Injects credentials, bot git identity, security context
    │       └── kustomization.yaml
    │
    └── infra-bootstrap-tools/                  # Tenant 2: Current repo (dogfooding)
        └── 1-workload/                         # Developer Agent Workloads (applied by child Flux Kustomization)
            ├── base/
            │   └── kustomization.yaml          # URL: https://github.com/xNok/infra-bootstrap-tools//.kubeopencode?ref=main
            ├── patch-agent-template.yaml       # Injects credentials, bot git identity, security context
            └── kustomization.yaml

.kubeopencode/                                  # Pure upstream agent intent for infra-bootstrap-tools
├── agent-template.yaml                         # Pure intent template (NO secretRef)
├── agents.yaml                                 # Agent CR: infra-bootstrap-agent
├── crontask-docs-audit.yaml                    # CronTask: scheduled docs & nix audit
└── kustomization.yaml
```

### The Manifest Contract: `flux-kustomization.yaml`

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: tenant-infra-bootstrap-workload
  namespace: flux-system
spec:
  interval: 10m
  path: ./tenants/infra-bootstrap-tools/1-workload
  prune: true
  targetNamespace: tenant-infra-bootstrap-tools
  serviceAccountName: tenant-infra-bootstrap-tools-applier
  sourceRef:
    kind: OCIRepository
    name: apps
```

### Key Guarantees:
1. **Separation of Concerns**: The platform reconciler only applies `0-enrollment` (creating the namespace and RBAC) and the `tenant-infra-bootstrap-workload` Flux `Kustomization` CR. It **never** touches `1-workload`.
2. **Impersonated Execution**: Flux's `kustomize-controller` executes `1-workload` under `spec.serviceAccountName: tenant-infra-bootstrap-tools-applier`.
3. **Forced Namespace via `spec.targetNamespace`**: Regardless of what namespace is declared upstream in `.kubeopencode/`, Flux overrides it to `tenant-infra-bootstrap-tools`.
4. **Offline Clean Compilation**: Because `1-workload` is omitted from `kustomization.yaml`, `kubectl kustomize kubernetes/apps` compiles in milliseconds without attempting remote git clones.

---

## 5. Flux Operator `ResourceSet` Factory Architecture

The **Flux Operator** ([ResourceSet CRD](https://fluxoperator.dev/docs/crd/resourceset/)) provides a Kubernetes-native templating engine based on Go text templates (with `<< >>` delimiters and slim-sprig functions) that natively solves the boilerplate and lifecycle challenges of multi-tenancy.

### A. The Staged Garbage Collection Advantage
In Kubernetes GitOps, deleting a tenant typically suffers from a dangerous race condition:
- If the tenant `ServiceAccount` and `Namespace` are deleted at the same time as or before the tenant workload custom resources (`Agent`, `Task`), the finalizers on the custom resources cannot complete because the impersonated ServiceAccount no longer exists!
- The tenant namespace becomes permanently stuck in `Terminating` status.

**How `ResourceSet` Solves This**:
The Flux Operator garbage collection process removes stale resources in **strict stages**:
1. It deletes the child Flux custom resources (`Kustomization`, `HelmRelease`) first.
2. It waits for the Flux controllers to finalize and clean up the child resources using the impersonated `ServiceAccount`.
3. Only after the Flux child resources are completely finalized does the operator proceed with deleting the `ServiceAccount`, `RoleBinding`, and `Namespace`.

### B. Placement in Cluster Root (`kubernetes/fleet/k3s/apps/tenants.yaml`)
In accordance with the Flux 3-Tier D2 architecture:
- `kubernetes/apps/` houses reusable packages, admission policies, and tenant workload overlays published to OCI (`oci://ghcr.io/xnok/manifests/kubernetes/apps`).
- `kubernetes/fleet/k3s/apps/` is the cluster root for the `k3s` cluster. It contains the active instantiation of which applications and tenants run on `k3s`.
- The `ResourceSet` factory is deployed in [`kubernetes/fleet/k3s/apps/tenants.yaml`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/github_app_agent_integration/kubernetes/fleet/k3s/apps/tenants.yaml) and registered in `kubernetes/fleet/k3s/apps/kustomization.yaml`.
- This eliminates all duplicated `0-enrollment/` directories (16 files) from `kubernetes/apps/tenants/`, making the platform envelope 100% DRY.

```yaml
apiVersion: fluxcd.controlplane.io/v1
kind: ResourceSet
metadata:
  name: kubeopencode-tenant-factory
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
    # 1. Tenant Namespace with Restricted Pod Security Standard
    - apiVersion: v1
      kind: Namespace
      metadata:
        name: tenant-<< inputs.name >>
        labels:
          pod-security.kubernetes.io/enforce: restricted
          pod-security.kubernetes.io/audit: restricted
          pod-security.kubernetes.io/warn: restricted
          app.kubernetes.io/part-of: << inputs.name >>

    # 2. Impersonated ServiceAccount in flux-system
    - apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: tenant-<< inputs.name >>-applier
        namespace: flux-system

    # 3. Restricted Workload Role (kubeopencode.io only)
    - apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        name: tenant-<< inputs.name >>-applier-role
        namespace: tenant-<< inputs.name >>
      rules:
        - apiGroups: ["kubeopencode.io"]
          resources: ["agents", "agents/status", "agents/finalizers", "agenttemplates", "crontasks", "tasks", "tasks/status", "tasks/finalizers"]
          verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
        - apiGroups: [""]
          resources: ["configmaps"]
          verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

    # 4. Applier RoleBinding
    - apiVersion: rbac.authorization.k8s.io/v1
      kind: RoleBinding
      metadata:
        name: tenant-<< inputs.name >>-applier-binding
        namespace: tenant-<< inputs.name >>
      roleRef:
        apiGroup: rbac.authorization.k8s.io
        kind: Role
        name: tenant-<< inputs.name >>-applier-role
      subjects:
        - kind: ServiceAccount
          name: tenant-<< inputs.name >>-applier
          namespace: flux-system

    # 5. Controller RBAC Role
    - apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        name: kubeopencode-controller-tenant-role
        namespace: tenant-<< inputs.name >>
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
          resources:
            - pods
            - pods/exec
            - pods/log
            - pods/status
            - configmaps
            - secrets
          verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
        - apiGroups: ["batch"]
          resources:
            - jobs
            - jobs/status
          verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
        - apiGroups: [""]
          resources:
            - events
          verbs: ["create", "patch"]

    # 6. Controller RBAC RoleBinding
    - apiVersion: rbac.authorization.k8s.io/v1
      kind: RoleBinding
      metadata:
        name: kubeopencode-controller-<< inputs.name >>-binding
        namespace: tenant-<< inputs.name >>
      roleRef:
        apiGroup: rbac.authorization.k8s.io
        kind: Role
        name: kubeopencode-controller-tenant-role
      subjects:
        - kind: ServiceAccount
          name: kubeopencode-controller
          namespace: kubeopencode-system

    # 7. ExternalSecret & GithubAccessToken Generator
    - apiVersion: external-secrets.io/v1beta1
      kind: ExternalSecret
      metadata:
        name: github-creds
        namespace: tenant-<< inputs.name >>
      spec:
        refreshInterval: 50m
        target:
          name: github-creds
          creationPolicy: Owner
          template:
            engineVersion: v2
            data:
              token: "{{ .token }}"
        dataFrom:
          - sourceRef:
              generatorRef:
                apiVersion: generators.external-secrets.io/v1alpha1
                kind: GithubAccessToken
                name: github-app-token-generator
    - apiVersion: generators.external-secrets.io/v1alpha1
      kind: GithubAccessToken
      metadata:
        name: github-app-token-generator
        namespace: tenant-<< inputs.name >>
      spec:
        appID: << inputs.appId | quote >>
        installID: << inputs.installId | quote >>
        url: https://api.github.com
        auth:
          privateKey:
            secretRef:
              name: github-app-private-key
              key: private-key.pem

    # 8. ExternalSecret for Shared LLM Credentials
    - apiVersion: external-secrets.io/v1
      kind: ExternalSecret
      metadata:
        name: google-creds
        namespace: tenant-<< inputs.name >>
      spec:
        refreshInterval: 1h
        secretStoreRef:
          kind: ClusterSecretStore
          name: onepassword
        target:
          name: google-creds
          creationPolicy: Owner
        data:
          - secretKey: api-key
            remoteRef:
              key: KUBEOPENCODE_GOOGLE_API_KEY/password

    # 9. Egress NetworkPolicy
    - apiVersion: networking.k8s.io/v1
      kind: NetworkPolicy
      metadata:
        name: isolate-tenant-egress
        namespace: tenant-<< inputs.name >>
      spec:
        podSelector: {}
        policyTypes: [Ingress, Egress]
        ingress:
          - from:
              - podSelector: {}
        egress:
          - to:
              - namespaceSelector:
                  matchLabels:
                    kubernetes.io/metadata.name: kube-system
                podSelector:
                  matchLabels:
                    k8s-app: kube-dns
            ports:
              - protocol: UDP
                port: 53
              - protocol: TCP
                port: 53
          - to:
              - ipBlock:
                  cidr: 0.0.0.0/0
                  except:
                    - 10.0.0.0/8
                    - 172.16.0.0/12
                    - 192.168.0.0/16
                    - 169.254.169.254/32
            ports:
              - protocol: TCP
                port: 443

    # 10. Child Flux Kustomization (Impersonating Tenant Applier with File-Based Overlay)
    - apiVersion: kustomize.toolkit.fluxcd.io/v1
      kind: Kustomization
      metadata:
        name: tenant-<< inputs.name >>-workload
        namespace: flux-system
      spec:
        interval: 10m
        path: << inputs.workloadPath | default (printf "./tenants/%s/1-workload" inputs.name) >>
        prune: true
        targetNamespace: tenant-<< inputs.name >>
        serviceAccountName: tenant-<< inputs.name >>-applier
        sourceRef:
          kind: OCIRepository
          name: apps
        dependsOn:
          - name: kubeopencode-controller
```

> [!NOTE]
> **Why File-Based Overlays Win Over Inline Overlays**:
> - **Rejection of Inline Overlays**: Embedding 40-line YAML patch strings (`spec.patches: [ - patch: | ... ]`) directly into the `ResourceSet` CR introduces brittle string escaping, prevents schema validation/linting by `yamllint`, and bloats the platform factory with application-layer schema details.
> - **Clean File-Based Overlays**: By targeting `./tenants/<< inputs.name >>/1-workload` from `OCIRepository/apps`, all environment variables (`GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`), credentials (`github-creds`, `google-creds`), and security contexts reside in dedicated, lintable, native YAML files ([`patch-agent-template.yaml`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/github_app_agent_integration/kubernetes/apps/tenants/infra-bootstrap-tools/1-workload/patch-agent-template.yaml)). The factory remains 100% clean and focused purely on envelope lifecycle.

### C. Future Evolution: Dynamic Discovery via `ResourceSetInputProvider`
When scaling beyond the initial repositories to dozens or hundreds of tenants, the static `ResourceSet` can seamlessly adopt `.spec.inputsFrom` referencing a [ResourceSetInputProvider](https://fluxoperator.dev/docs/crd/resourcesetinputprovider/):
- **`type: ExternalService`**: Integrates with Backstage or an internal developer portal API that tracks GitHub App installations in real time.
- **`type: GitHubPullRequest` / `GitHubBranch`**: Automatically provisions and tears down ephemeral preview environments.
- For our current phase, this remains a zero-change architectural evolution: the `resources` template stays identical, only the input source expands.

---

## 6. Defense-in-Depth: Modern CEL Admission Control (Replacing Deprecated `ClusterPolicy`)

RBAC operates at the Kubernetes API authorization boundary, but admission control provides an in-tree policy engine that validates invariants regardless of RBAC permissions.

> [!NOTE]
> **Deprecation of `ClusterPolicy`**: Legacy `ClusterPolicy` and `Policy` custom resources (`kyverno.io/v1`) are officially deprecated in modern Kyverno in favor of native Common Expression Language (CEL) policy types under **`policies.kyverno.io/v1`** (`ValidatingPolicy`, `MutatingPolicy`, `GeneratingPolicy`). This aligns directly with Kubernetes' native `ValidatingAdmissionPolicy` architecture while retaining Kyverno's policy reporting and exception framework.

We deploy two CEL-based [`ValidatingPolicy`](file:///kubernetes/apps/tenants/policies/tenant-workload-isolation.yaml) resources:

### Policy 1: `tenant-workload-isolation`
- **Kind**: `ValidatingPolicy` (`policies.kyverno.io/v1`)
- **Blocked Kinds**: `Deployment`, `StatefulSet`, `DaemonSet`, `ReplicaSet` (`apps/v1`).
- **CEL Rule**: `expression: "!request.namespace.startsWith('tenant-')"`
- **Action**: `Deny` (Hard Rejection).
- **Rationale**: Tenants must NEVER run arbitrary long-running container daemons, cryptominers, or unmanaged web servers. Only the `kubeopencode-controller` is permitted to spawn ephemeral task execution pods.

### Policy 2: `require-tenant-applier-service-account`
- **Kind**: `ValidatingPolicy` (`policies.kyverno.io/v1`)
- **Target**: `Kustomization` resources (`kustomize.toolkit.fluxcd.io/v1`).
- **CEL Rule 1 (Forced Namespace)**: `expression: "!has(object.spec.path) || !object.spec.path.contains('tenants/') || (has(object.spec.targetNamespace) && object.spec.targetNamespace.startsWith('tenant-'))"`
  - Enforces that any Flux Kustomization deploying tenant workloads MUST force the namespace via `spec.targetNamespace`.
- **CEL Rule 2 (Restricted Applier)**: `expression: "!has(object.spec.targetNamespace) || !object.spec.targetNamespace.startsWith('tenant-') || !object.spec.path.contains('1-workload') || (has(object.spec.serviceAccountName) && object.spec.serviceAccountName.startsWith('tenant-') && object.spec.serviceAccountName.endsWith('-applier'))"`
  - Enforces that tenant workload Kustomizations drop cluster-admin privileges and impersonate the restricted `tenant-*-applier`.
- **Action**: `Deny`.

---

## 7. The Runbook: Onboarding Repo #3 in 3 Steps

To onboard a 3rd repository (e.g., `cool-tool`), follow this 3-step runbook:

### Step 1: Register in Cluster Root ([`kubernetes/fleet/k3s/apps/tenants.yaml`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/github_app_agent_integration/kubernetes/fleet/k3s/apps/tenants.yaml))
Add 6 lines to `spec.inputs`:
```yaml
    - name: cool-tool
      repo: https://github.com/myorg/cool-tool.git
      branch: main
      appId: "123456"
      installId: "7891013"
```
*Result*: The `ResourceSet` automatically creates the entire security envelope (`Namespace/tenant-cool-tool`, `ServiceAccount/tenant-cool-tool-applier`, RBAC, ExternalSecrets, NetworkPolicy, and child Flux Kustomization) with zero additional envelope files!

### Step 2: Create Workload Overlay (`kubernetes/apps/tenants/cool-tool/1-workload/`)
Create just 2 files in `kubernetes/apps/tenants/cool-tool/1-workload/`:

1. **`kustomization.yaml`**:
   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   resources:
     - https://github.com/myorg/cool-tool//.kubeopencode?ref=main
   patches:
     - path: patch-agent-template.yaml
   ```

2. **`patch-agent-template.yaml`**:
   ```yaml
   apiVersion: kubeopencode.io/v1alpha1
   kind: AgentTemplate
   metadata:
     name: cool-tool-base
   spec:
     credentials:
       - name: github-token
         secretRef:
           name: github-creds
           key: token
         env: GITHUB_TOKEN
       - name: google-api-key
         secretRef:
           name: google-creds
           key: api-key
         env: GOOGLE_API_KEY
     podSpec:
       env:
         - name: GIT_AUTHOR_NAME
           value: "cool-tool-agent[bot]"
         - name: GIT_AUTHOR_EMAIL
           value: "123456+cool-tool-agent[bot]@users.noreply.github.com"
         - name: GIT_COMMITTER_NAME
           value: "cool-tool-agent[bot]"
         - name: GIT_COMMITTER_EMAIL
           value: "123456+cool-tool-agent[bot]@users.noreply.github.com"
   ```

### Step 3: Git Commit & Push
Commit and push. Flux reconciles the cluster root, stamps out the envelope from `tenants.yaml`, and impersonates `tenant-cool-tool-applier` to deliver the workload overlay into `tenant-cool-tool`.

---

## 8. Tenant Differentiation (Opt-In Overrides)

When a tenant requires custom behavior, developers have full control:
1. **Custom LLM Model / System Prompts**: Edit `patch-agent-template.yaml` in the tenant's `1-workload/` (e.g. `model: anthropic/claude-3-5-sonnet`).
2. **Custom Third-Party Secrets**: Add an `ExternalSecret` manifest directly into `1-workload/` and reference it under `spec.credentials`.
3. **Custom Network Egress**: Add a specialized `NetworkPolicy` directly into `1-workload/`.
4. **Custom Subpath or Branch**: Specify `workloadPath` or `branch` in `kubernetes/fleet/k3s/apps/tenants.yaml`:
   ```yaml
   - name: special-repo
     repo: https://github.com/myorg/special-repo.git
     branch: release-v2
     workloadPath: ./tenants/special-repo/custom-overlay
     appId: "123456"
     installId: "7891014"
   ```

---

## 9. Future Escape Gate: Dynamic Config Composition via Flux `ArtifactGenerator`

As the platform scales beyond static repositories, [Flux ArtifactGenerator](https://fluxcd.io/flux/components/source/artifactgenerators/) (`source.extensions.fluxcd.io/v1beta1`) serves as our **future architectural escape gate**. It resolves the tension between repository sovereignty (pure developer intent in `.kubeopencode/`) and platform governance (injecting credentials, bot identities, and security contexts) by enabling **in-cluster source composition and decomposition** at the source-controller tier.

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        FLUX ARTIFACT GENERATOR PIPELINE                                │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. UPSTREAM SOURCES                                                                    │
│    • Tenant GitRepository (@repo)        ──► Pure developer intent (.kubeopencode/)   │
│    • Platform OCIRepository (@platform)  ──► Platform base overlay & credentials       │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 2. ARTIFACT GENERATOR (source.extensions.fluxcd.io/v1beta1)                            │
│    • Composition: Combines @repo and @platform into a unified filesystem tree.         │
│    • Strategy: Merge / Overwrite applies platform patches cleanly in memory.           │
│    • Directory Discovery: pathPattern (@repo/agents/{agent}) auto-discovers targets.   │
│    • Input Export: inputsFrom exports YAML metadata to .status.exportedInputs.         │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 3. OUTPUT & CONSUMPTION                                                                │
│    • Emits: ExternalArtifact (revision: latest@sha256:<composite-hash>)                │
│    • Ingestion:                                                                        │
│      - ResourceSet: Consumes .status.exportedInputs for dynamic envelope templating.   │
│      - Flux Kustomization: spec.sourceRef -> ExternalArtifact (applies the workload)   │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### A. Why `ArtifactGenerator` is the Ultimate Escape Gate

1. **Elimination of GitOps Glue Boilerplate ("Zero-File Apps")**:
   - In our current Phase 2 model, onboarding a repository requires maintaining 2 small overlay files in `kubernetes/apps/tenants/<tenant>/1-workload/`.
   - With `ArtifactGenerator`, **zero files** need to be committed to `kubernetes/apps/` for new tenants. The platform dynamically composes the upstream `.kubeopencode/` with the central platform patch in-cluster.
2. **Safe from String Escaping & YAML-in-YAML**:
   - Unlike the rejected inline patch anti-pattern (`spec.patches: [ - patch: | ... ]`), `ArtifactGenerator` performs native file-based copies and YAML merges (`strategy: Merge` or `strategy: Overwrite`) using real, validated YAML files from managed sources.
3. **Automatic Multi-Source Drift & Revision Hashing**:
   - The revision of an `ExternalArtifact` is computed as `latest@sha256:<hash>`, where `<hash>` is the SHA256 checksum of the final composed files.
   - If *either* the developer updates `.kubeopencode/` in their repository *or* the platform team updates the base security patch in `apps`, Flux generates a new artifact revision and automatically reconciles downstream workloads.

---

### B. Blueprint: In-Cluster Tenant Workload Composition

Below is the concrete configuration blueprint for generating a composite tenant workload from an upstream repository and a shared platform overlay:

```yaml
apiVersion: source.extensions.fluxcd.io/v1beta1
kind: ArtifactGenerator
metadata:
  name: tenant-cool-tool
  namespace: flux-system
spec:
  interval: 10m
  sources:
    # Source A: Upstream Tenant Repository (Developer Intent)
    - alias: repo
      kind: GitRepository
      name: tenant-cool-tool
    # Source B: Central Platform Library (Governance & Credentials)
    - alias: platform
      kind: OCIRepository
      name: apps
  artifacts:
    - name: cool-tool-workload
      originRevision: "@repo"
      copy:
        # 1. Copy upstream developer agent manifests
        - from: "@repo/.kubeopencode/**"
          to: "@artifact/"
        # 2. Merge platform credentials, bot committer identity, and PSS hardening
        - from: "@platform/tenants/_base/patch-agent-template.yaml"
          to: "@artifact/patch-agent-template.yaml"
          strategy: Overwrite
        # 3. Inject root kustomization to link base and patch
        - from: "@platform/tenants/_base/kustomization.yaml"
          to: "@artifact/kustomization.yaml"
          strategy: Overwrite
```

The downstream Flux `Kustomization` then simply references the generated `ExternalArtifact`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: tenant-cool-tool-workload
  namespace: flux-system
spec:
  interval: 10m
  prune: true
  targetNamespace: tenant-cool-tool
  serviceAccountName: tenant-cool-tool-applier
  sourceRef:
    kind: ExternalArtifact
    name: cool-tool-workload
```

---

### C. Advanced Synergy: Dynamic Discovery with `pathPattern` and `inputsFrom`

`ArtifactGenerator` provides two transformative capabilities that unlock fully automated, self-service onboarding:

#### 1. Dynamic Monorepo / Multi-Agent Discovery (`pathPattern`)
If a tenant repository hosts multiple agents in subdirectories:
```yaml
spec:
  pathPattern: "@repo/agents/{agent}"
  artifacts:
    - name: "agent-{agent}"
      copy:
        - from: "@repo/agents/{agent}/**"
          to: "@artifact/"
```
Flux automatically traverses the repository, discovers every directory under `agents/`, extracts the `{agent}` capture variable, and stamps out an `ExternalArtifact` named `agent-<name>` without any platform team intervention.

#### 2. Feeding the Factory with `inputsFrom`
`ArtifactGenerator` can inspect a tenant's in-repo configuration file (e.g. `@repo/.kubeopencode/config.yaml`) using `.spec.artifacts[].inputsFrom`:
```yaml
spec:
  artifacts:
    - name: cool-tool-workload
      inputsFrom: "@repo/.kubeopencode/config.yaml"
```
The key-value pairs from `config.yaml` are exported directly into `ExternalArtifact.status.exportedInputs`. Downstream controllers, specifically the **Flux Operator `ResourceSet`**, can bind to these exported inputs to dynamically provision namespace envelopes, external secrets, and applier RBAC without any static lists committed to platform Git!

---

## 10. Architectural Retrospective & Decision Check Matrix

### A. What Went Wrong: Retrospective on Flawed Directions

| Flawed Direction | Fatal Symptom / Failure Mode | Root Cause & Resolution |
| :--- | :--- | :--- |
| **1. Single Lump Overlay** (Merging `0-enrollment` and `1-workload`) | Privilege escalation (applied as `cluster-admin`). Sandbox git clone failures (`evalsymlink /tmp/kustomize` error). | Conflated platform envelope with developer workload in one Kustomize tree. Resolved by strict Two-Tier separation; `1-workload` applied exclusively by Flux SA impersonation. |
| **2. Deprecated Kyverno `ClusterPolicy`** | Deprecated CRD warnings. Out of sync with modern Kubernetes admission control. | Kyverno deprecated legacy `ClusterPolicy` in v1.13+. Replaced with native CEL `ValidatingPolicy` custom resources (`policies.kyverno.io/v1`). |
| **3. Invalidation Fallacy** (Catalogue vs Tenant) | Confusion over whether Sovereign Tenant Agents invalidated the Shared Agent Catalogue. | Conflated reusable cross-cutting tools (UX auditor "Palette") with domain-specific repository agents. Established that Catalogue and Sovereign Agents are complementary layers. |
| **4. Inline String Patch** (`spec.patches` in `ResourceSet`) | 40 lines of YAML string escaping inside Go templates. Unlintable by `yamllint`. High risk of syntax bugs. | Embedded application schema into an infrastructure CRD. Rejected: adopted clean, lintable file-based overlays in Git. |
| **5. Misplaced Factory** (`ResourceSet` in `kubernetes/apps/`) | Violated Flux 3-Tier D2 architecture. Factory not reconciled by cluster root sync. | Stored concrete cluster state inside reusable OCI apps package. Resolved by moving `ResourceSet` to cluster root (`kubernetes/fleet/k3s/apps/tenants.yaml`). |
| **6. The 16-File Boilerplate Explosion** | 16 redundant files committed for 2 tenants. Adding repo #3 required copying 8 files. | Maintained static enrollment folders alongside the `ResourceSet`. Resolved by deleting all 16 static enrollment files; `ResourceSet` is single source of truth. |

---

### B. Decision Check Matrix (Is the Current Architecture Right?)

| # | Architectural Dimension | Requirement | Current Implementation Status |
| :-: | :--- | :--- | :--- |
| **1** | **Privilege Isolation** | Workloads must NEVER execute as `cluster-admin`. | ✅ **VERIFIED**: Applied exclusively by Flux `kustomize-controller` impersonating `tenant-<name>-applier` (`spec.serviceAccountName`), strictly restricted to `kubeopencode.io/*` and `configmaps`. |
| **2** | **Admission Hardening** | Invariant admission enforcement beyond RBAC. | ✅ **VERIFIED**: Kyverno CEL `ValidatingPolicy` denies non-agent workloads (`Deployment`, `DaemonSet`, `StatefulSet`) in tenant namespaces and enforces applier SA and `targetNamespace`. |
| **3** | **Cluster Root Placement** | Factory must reside in the cluster sync root. | ✅ **VERIFIED**: `ResourceSet` deployed in `kubernetes/fleet/k3s/apps/tenants.yaml`, reconciled directly by the `k3s` root `FluxInstance`. `kubernetes/apps` remains a pure OCI package library. |
| **4** | **DRY Platform Envelopes** | Zero boilerplate duplication for platform security primitives. | ✅ **VERIFIED**: 16 redundant files deleted. A single parameterized `ResourceSet` stamps out Namespace, ServiceAccount, RBAC Roles/RoleBindings, ExternalSecrets, NetworkPolicy, and child Kustomizations. |
| **5** | **Clean Workload Overlays** | No YAML-in-YAML strings; standard lintable Kustomize. | ✅ **VERIFIED**: Workload overlays reside in dedicated files (`patch-agent-template.yaml` and `kustomization.yaml`). Zero inline patch strings in the factory. |
| **6** | **Repo #3 Onboarding** | Adding a new repo must be fast, minimal, and repeatable. | ✅ **VERIFIED**: **3 Steps**: Add 6 lines to `tenants.yaml`, add 2 files to `apps/tenants/<repo>/1-workload/`, commit and push. All envelope resources are auto-generated. |
| **7** | **Future Escape Gate** | Path to zero-file GitOps and dynamic config composition. | ✅ **VERIFIED**: Fully documented [Flux ArtifactGenerator](https://fluxcd.io/flux/components/source/artifactgenerators/) (`source.extensions.fluxcd.io/v1beta1`) as the future escape gate to compose sources in-cluster and feed `ResourceSet.inputsFrom`. |

---

## 11. Production GitHub App Provisioning & Credentials Integration

The production GitHub App has been provisioned, installed, and wired into the cluster GitOps configuration with automated token rotation and verified bot committer identities.

### A. GitHub App Parameters & Verified Permissions

| Parameter | Production Value | Description |
| :--- | :--- | :--- |
| **App Name** | `xNok KubeOpencode` | Display name in GitHub UI |
| **App Slug** | `xnok-kubeopencode` | Canonical identifier for GitHub bot URLs and badges |
| **App ID** | `5866072` | Top-level GitHub application identifier |
| **HTML URL** | `https://github.com/apps/xnok-kubeopencode` | Public profile for the GitHub App |
| **Homepage URL** | `https://github.com/xNok/infra-bootstrap-tools` | Informational project homepage |
| **Webhooks** | **Disabled** (`active: false`) | Tasks run via Kubernetes/Flux CronTask schedules; no ingress webhook needed |
| **Installation 1** | `184455973` | Target: `xNok/infra-bootstrap-tools` (Personal Account) |
| **Installation 2** | `184456098` | Target: `mekitmedia/cncf-landscape-a-to-z` (Organization) |

#### Granted Repository Permissions (Tested & Verified via GitHub API)
- **`contents: write`**: Clone source code, create git branches, commit files, and push changes.
- **`pull_requests: write`**: Open PRs, update PR descriptions, assign reviewers, and comment.
- **`issues: write`**: Read issue descriptions, comment on agent progress, and manage labels.
- **`workflows: write`**: Author or modify CI workflows under `.github/workflows/`.
- **`metadata: read`**: Access repository metadata (default requirement for GitHub Apps).

---

### B. Automated Secret Management & Dynamic Token Rotation Pipeline

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                        GITHUB APP TOKEN ROTATION PIPELINE                             │
├───────────────────────────────────────────────────────────────────────────────────────┤
│ 1. VAULT STORAGE (1Password)                                                          │
│    • Item: xnok-kubeopencode.2026-11-21.private-key                                   │
│    • Field: private key (SSHKEY / RSA 2048-bit PEM)                                   │
│    • Vault: infra-bootstrap-tools                                                     │
├───────────────────────────────────────────────────────────────────────────────────────┤
│ 2. IN-CLUSTER SYNCHRONIZATION (External Secrets Operator)                             │
│    • ClusterSecretStore: onepassword (provider: onepasswordSDK)                       │
│    • ResourceSet templates ExternalSecret in each tenant namespace:                   │
│      - Secret/github-app-private-key (key: private-key.pem, refresh: 1h)              │
├───────────────────────────────────────────────────────────────────────────────────────┤
│ 3. DYNAMIC TOKEN EXCHANGE (generators.external-secrets.io/v1alpha1)                   │
│    • ResourceSet templates GithubAccessToken generator per tenant:                    │
│      - appID: "5866072"                                                               │
│      - installID: << inputs.installId >> (184455973 or 184456098)                    │
│      - privateKey: Secret/github-app-private-key                                      │
│    • ExternalSecret/github-creds triggers exchange every 50m (token lifetime: 1h)     │
│    • Injects short-lived installation token into Secret/github-creds (key: token)     │
├───────────────────────────────────────────────────────────────────────────────────────┤
│ 4. AGENT POD INGESTION                                                                │
│    • AgentTemplate mounts Secret/github-creds as GITHUB_TOKEN                         │
│    • Workloads authenticate autonomously without long-lived personal tokens           │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

---

### C. Bot Committer Identity Standard

When an agent commits code or creates branches, Git commits are signed and attributed to the official GitHub App bot:
- **`GIT_AUTHOR_NAME`**: `xnok-kubeopencode[bot]`
- **`GIT_AUTHOR_EMAIL`**: `5866072+xnok-kubeopencode[bot]@users.noreply.github.com`
- **`GIT_COMMITTER_NAME`**: `xnok-kubeopencode[bot]`
- **`GIT_COMMITTER_EMAIL`**: `5866072+xnok-kubeopencode[bot]@users.noreply.github.com`

*Outcome*: GitHub automatically associates all agent commits with the official verified `bot` badge linked directly to `https://github.com/apps/xnok-kubeopencode`.

---

## 12. Cluster Live Deployment & Schema Validation (`k3s-ziti`)

Direct cluster reconciliation and server dry-run validation against the live cluster (`ns3118807`, context `k3s-ziti`) revealed four critical production schema constraints:

### A. Diagnosed Production Blockers & Fixes

| Issue Identified in Cluster | Root Cause | Fix Applied |
| :--- | :--- | :--- |
| **1. ResourceSet Template Crash** | Go text template crashed on missing map key: `map has no entry for key "workloadPath"`. | Explicitly declared `workloadPath` in `inputs:` and safely accessed via `<< index inputs "workloadPath" \| default ... >>`. |
| **2. Deprecated `v1beta1` ExternalSecret** | ESO cluster CRD only serves `v1` (`v1beta1 served=false`). Dry-run failed with `no matches for kind ExternalSecret in version external-secrets.io/v1beta1`. | Updated `github-creds` to `apiVersion: external-secrets.io/v1`. |
| **3. 1Password Secret Reference Format** | ESO 1Password SDK rejected `key` without slash when `property` was used (`secret reference has invalid format`). | Changed to standard `key: xnok-kubeopencode.2026-11-21.private-key/private key`. |
| **4. AgentTemplate Schema Mismatch** | KubeOpenCode `AgentTemplate` CRD does not have `podSpec.env`; it defines `podSpec.extraEnv`. | Renamed `env:` to `extraEnv:` in workload patch overlays. |
| **5. Cross-Namespace Patch Selection** | Upstream base declared `tenant-cncf-landscape`; Kustomize patch failed to match target. | Switched to Kustomize `target: {kind: AgentTemplate, name: ...}` selector with root `namespace:` transformation. |

### B. Live Cluster Status

Following these fixes:
1. **`ResourceSet/kubeopencode-tenant-factory`**: Successfully reconciled (`Reconciliation finished in 779ms`, Status: `True`).
2. **Namespaces Created**: `tenant-infra-bootstrap-tools` and `tenant-cncf-landscape-a-to-z` are Active.
3. **Applier ServiceAccounts & RBAC**: `tenant-*-applier` created in `flux-system` with impersonation permissions strictly bound to `kubeopencode.io/*` and `configmaps`.
4. **Secret Synchronization**:
   - `Secret/github-app-private-key`: Successfully synced from 1Password (`SecretSynced: True`).
   - `Secret/github-creds`: Dynamic 1-hour GitHub App access token generated and auto-rotated every 50m (`SecretSynced: True`).
   - `Secret/google-creds`: Successfully synced from 1Password (`SecretSynced: True`).
5. **Workload Server Dry-Run**: Validated via impersonation (`--as=system:serviceaccount:flux-system:tenant-*-applier`); all `Agent`, `AgentTemplate`, and `CronTask` resources compile and validate against Kubernetes API admission controls.



