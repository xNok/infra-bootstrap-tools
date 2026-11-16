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

## 4. Implemented Architecture: Two-Tier Static Model with Flux Workload Applier

### Directory Structure

```
kubernetes/apps/
├── kustomization.yaml                          # Root apps kustomization
└── tenants/
    ├── policies/                               # Admission control policies
    │   ├── kustomization.yaml
    │   └── tenant-workload-isolation.yaml      # CEL-based ValidatingPolicies
    │
    ├── cncf-landscape-a-to-z/                  # Tenant 1: External repo
    │   ├── 0-enrollment/                       # Platform Security & Identity Envelope
    │   │   ├── namespace.yaml                  # Namespace: tenant-cncf-landscape (PSS: restricted)
    │   │   ├── applier-rbac.yaml               # ServiceAccount tenant-cncf-landscape-applier in flux-system
    │   │   ├── controller-rbac.yaml            # Scopes kubeopencode-controller to tenant namespace
    │   │   ├── github-app-token.yaml           # ESO GithubAccessToken generator -> Secret github-creds
    │   │   ├── network-policy.yaml             # Egress firewall (DNS, GitHub HTTPS, LLM APIs)
    │   │   └── kustomization.yaml
    │   ├── 1-workload/                         # Developer Agent Workloads (applied by child Flux Kustomization)
    │   │   ├── base/
    │   │   │   └── kustomization.yaml          # URL: https://github.com/mekitmedia/cncf-landscape-a-to-z//.kubeopencode?ref=main
    │   │   ├── patch-agent-template.yaml       # Injects credentials, bot git identity, security context
    │   │   └── kustomization.yaml
    │   ├── flux-kustomization.yaml             # Flux Kustomization CR (impersonates applier SA)
    │   └── kustomization.yaml                  # Aggregates 0-enrollment & flux-kustomization.yaml ONLY
    │
    ├── infra-bootstrap-tools/                  # Tenant 2: Current repo (dogfooding)
    │   ├── 0-enrollment/                       # Platform Security & Identity Envelope
    │   │   ├── namespace.yaml                  # Namespace: tenant-infra-bootstrap-tools (PSS: restricted)
    │   │   ├── applier-rbac.yaml               # ServiceAccount tenant-infra-bootstrap-tools-applier in flux-system
    │   │   ├── controller-rbac.yaml            # Scopes kubeopencode-controller to tenant namespace
    │   │   ├── github-app-token.yaml           # ESO GithubAccessToken generator -> Secret github-creds
    │   │   ├── network-policy.yaml             # Egress firewall (DNS, GitHub HTTPS, LLM APIs)
    │   │   └── kustomization.yaml
    │   ├── 1-workload/                         # Developer Agent Workloads (applied by child Flux Kustomization)
    │   │   ├── base/
    │   │   │   └── kustomization.yaml          # URL: https://github.com/xNok/infra-bootstrap-tools//.kubeopencode?ref=main
    │   │   ├── patch-agent-template.yaml       # Injects credentials, bot git identity, security context
    │   │   └── kustomization.yaml
    │   ├── flux-kustomization.yaml             # Flux Kustomization CR (impersonates applier SA)
    │   └── kustomization.yaml                  # Aggregates 0-enrollment & flux-kustomization.yaml ONLY
    │
    └── tenant-factory.yaml                     # Static ResourceSet blueprint for 2 repos

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

### B. Starting Simple: Static 2-Tenant Factory
Because we currently have only two dogfooding repositories (`cncf-landscape-a-to-z` and `infra-bootstrap-tools`), introducing `ResourceSetInputProvider` and an external service registry adds premature complexity.
We start with a **static `ResourceSet`** configuring both repositories directly in `spec.inputs`:

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

    # 5. Controller RBAC RoleBinding
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

    # 6. ExternalSecret & GithubAccessToken Generator
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

    # 7. Egress NetworkPolicy
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

    # 8. Source: GitRepository for the tenant
    - apiVersion: source.toolkit.fluxcd.io/v1
      kind: GitRepository
      metadata:
        name: tenant-<< inputs.name >>
        namespace: flux-system
      spec:
        interval: 10m
        url: << inputs.repo >>
        ref:
          branch: << inputs.branch | default "main" >>
        ignore: |
          /*
          !/.kubeopencode

    # 9. Child Flux Kustomization (Impersonating Tenant Applier with Environment Overlay)
    - apiVersion: kustomize.toolkit.fluxcd.io/v1
      kind: Kustomization
      metadata:
        name: tenant-<< inputs.name >>-workload
        namespace: flux-system
      spec:
        interval: 10m
        path: "./.kubeopencode"
        prune: true
        targetNamespace: tenant-<< inputs.name >>
        serviceAccountName: tenant-<< inputs.name >>-applier
        sourceRef:
          kind: GitRepository
          name: tenant-<< inputs.name >>
        patches:
          # Overlay: Inject in-cluster credentials, bot committer identity, and security hardening
          - target:
              kind: AgentTemplate
            patch: |
              apiVersion: kubeopencode.io/v1alpha1
              kind: AgentTemplate
              metadata:
                name: ignored
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
                      value: "<< inputs.name >>-agent[bot]"
                    - name: GIT_AUTHOR_EMAIL
                      value: "<< inputs.appId >>+<< inputs.name >>-agent[bot]@users.noreply.github.com"
                    - name: GIT_COMMITTER_NAME
                      value: "<< inputs.name >>-agent[bot]"
                    - name: GIT_COMMITTER_EMAIL
                      value: "<< inputs.appId >>+<< inputs.name >>-agent[bot]@users.noreply.github.com"
                  securityContext:
                    runAsNonRoot: true
                    allowPrivilegeEscalation: false
                    capabilities:
                      drop:
                        - ALL
                    seccompProfile:
                      type: RuntimeDefault
```

### C. Future Evolution: Dynamic Discovery via `ResourceSetInputProvider`
When scaling beyond the initial two repositories to dozens or hundreds of tenants, the static `ResourceSet` can seamlessly adopt `.spec.inputsFrom` referencing a [ResourceSetInputProvider](https://fluxoperator.dev/docs/crd/resourcesetinputprovider/):
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

## 7. Summary Decision & Evolution Path

1. **Phase 1 (Current PR #253)**:
   - Fix the separation of concerns in `kubernetes/apps/tenants/`: `kustomization.yaml` files reference `0-enrollment` and `flux-kustomization.yaml`.
   - Workload manifests (`1-workload`) are kept out of the parent Kustomize tree, resolving the sandbox git clone error and guaranteeing SA impersonation.
   - Enforce CEL-based `ValidatingPolicy` admission control.
   - Clarify the relationship between the Shared Agent Catalogue (reusable agent library) and Sovereign Tenant Agents (repo-specific domain workflows).
2. **Phase 2 (Fleet Deployment & Factory Scaling)**:
   - Deploy `tenant-factory.yaml` using the static Flux Operator `ResourceSet` (2 repos) in `kubernetes/fleet/k3s/apps/` to manage multiple tenants via a unified template.
   - Introduce `ResourceSetInputProvider` for automated repository discovery when expanding beyond the initial dogfooding tenants.
