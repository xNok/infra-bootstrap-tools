---
type: project
status: active
description: Installation and operational planning for KubeOpenCode on the K3s cluster, separating controller lifecycle from agent/task configuration.
related_projects:
  - dark-k3s-stack
  - kubernetes-flux-d2
  - agentic-framework
related_areas:
  - kubernetes-fleet
  - ai-workflow-automation
---

# KubeOpenCode on K3s Stack: Planning & Architecture

## 1. Overview & Objective

The goal of this project is to install and operate [KubeOpenCode](https://github.com/kubeopencode/kubeopencode) on our K3s cluster (specifically the "dark" K3s environment).

KubeOpenCode is a Kubernetes-native AI agent execution platform built on [OpenCode](https://opencode.ai). It brings autonomous agentic development, batch tasks, and human-in-the-loop interactive agent sessions into Kubernetes using Custom Resource Definitions (`Agent`, `Task`, `CronTask`, `AgentTemplate`, `KubeOpenCodeConfig`).

### Core Principle: Application Separation & Controller vs. Configuration
- **Application, Not Infra-Addon**: KubeOpenCode is an **application / platform workload**, not a core infrastructure addon. It must not be bundled into `kubernetes/infra-addons` (which is reserved for foundational cluster primitives like `cert-manager` and `openziti`).
- **Differentiate Controller from Configuration**:
  - **Controller Plane (Operator & API/UI Server)**: The core system components deployed in `kubeopencode-system` (Helm chart `oci://ghcr.io/kubeopencode/helm-charts/kubeopencode`), managing CRDs, watching resources, and maintaining the web UI/proxy.
  - **Configuration Plane (Agents, Tasks, Templates, Credentials)**: User-defined AI agents, task triggers, credentials, and workspace configurations deployed across designated workload namespaces.
- **Simplified Pattern**: Unlike `infra-addons` which uses Kustomize `Component` objects, two-tiered ConfigMap overrides, and complex `${CLUSTER_NAME}` substitutions, KubeOpenCode should follow a simpler, application-centric GitOps pattern while preserving CRD lifecycle separation.

---

## 2. Benefit vs. Risk Analysis

| Dimension | Benefits | Risks & Challenges | Mitigations |
| :--- | :--- | :--- | :--- |
| **Architectural** | - **Declarative Agent Ops**: Agents and tasks versioned in Git alongside infrastructure.<br>- **Native K8s Primitives**: Reuses K8s RBAC, logging, PVCs, and scheduling. | - **Alpha Maturity**: Project is at `v0.1.x` (`v1alpha1` API); upstream breaking changes may occur.<br>- **CRD Timing**: Applying CRs before CRD registration causes reconcile failures. | - Pin chart versions (e.g. `0.1.9`).<br>- Decouple controller deployment from agent CR manifests via Flux `dependsOn`. |
| **Operational & Resource** | - **Flexible Compute**: Supports ephemeral task pods or persistent agents.<br>- **Idle Suspend**: Native `standby` and `suspend` scaling down idle agents to 0 replicas. | - **Resource Saturation**: Multiple devbox pods running compilers, Node.js, and Python can overwhelm a single-node K3s host.<br>- **Storage Pressure**: SQLite session persistence and workspace volumes consuming host disk. | - Enforce strict Pod `resources.requests` and `resources.limits`.<br>- Enable `standby` auto-suspend.<br>- Clean up completed Task pods via `cleanup` policy. |
| **Security & Privacy** | - **Container Isolation**: Tasks execute inside bounded containers with restricted Linux capabilities.<br>- **Encrypted Secrets**: API keys (Anthropic, Gemini, OpenAI, GitHub PATs) mounted via K8s Secrets. | - **Prompt Injection & Command Execution**: AI agents run shell commands; overprivileged ServiceAccounts could compromise the cluster.<br>- **Secret Exfiltration**: Untrusted tasks or prompts could leak mounted tokens. | - Follow principle of least privilege for `Agent.spec.serviceAccountName`.<br>- Restrict RBAC to target namespaces only.<br>- Apply `NetworkPolicy` to restrict egress where possible. |
| **Integration** | - **OpenZiti Zero-Trust Integration**: K3s API and Web UI can remain private and accessed over the dark overlay network.<br>- **Multi-Provider Support**: 75+ LLM providers supported via OpenCode config. | - **Web UI Exposure**: Default port 2746 server without Ingress auth could expose agent control plane if made public. | - Bind Web UI to ClusterIP only; access via `kubectl port-forward` or authenticated OpenZiti service. |

---

## 3. Alternatives Evaluated

### Alternative A: Packaging as `infra-addons` Component
- **Approach**: Create `kubernetes/infra-addons/components/kubeopencode` alongside `cert-manager` and `openziti`, publish via the existing shared `infra-addons` OCI artifact.
- **Why Rejected**:
  - Violates separation of concerns: KubeOpenCode is a developer tool / workload, not infrastructure.
  - Couples application deployment cycles to base cluster bootstrap.
  - Adds unnecessary complexity (`kind: Component`, values layering, `${CLUSTER_NAME}` substitution).

### Alternative B: Single Monolithic Manifest (Controller + Agents together)
- **Approach**: Bundle HelmRelease, Agent CRs, Secrets, and Tasks in a single Kustomization.
- **Why Rejected**:
  - **Chicken-and-egg problem**: When installing KubeOpenCode on a fresh cluster, Kubernetes will reject `kind: Agent` or `kind: Task` before the Helm chart has installed and registered the CRDs.
  - Violates the separation of system controller lifecycle from user workload lifecycle.

### Alternative C: In-Tree Fleet App vs. Dedicated `apps/` OCI Artifact
- **Option C1 (In-Tree under `kubernetes/fleet/k3s/apps/kubeopencode`)**:
  - Deployed directly within the `fleet/k3s` OCI artifact.
  - Two distinct subdirectories: `controller/` (HelmRepository + HelmRelease) and `config/` (ServiceAccount, RBAC, Agent, Task).
  - *Pros*: Zero changes to GitHub Actions CI pipelines; immediately reconcilable by existing `flux-instance.yaml` in k3s.
  - *Cons*: Manifests reside in `k3s` fleet directory rather than shared `apps` directory (fine if initially experimented on k3s).
- **Option C2 (Shared `kubernetes/apps/kubeopencode` + 3rd OCI Artifact)**:
  - Create a new top-level `kubernetes/apps` directory, add a GitHub Actions workflow to publish `oci://ghcr.io/.../apps`, and reference it in `fleet/k3s`.
  - *Pros*: Follows strict 3-tier ControlPlane D2 architecture (`fleet`, `infra`, `apps`).
  - *Cons*: Additional CI/CD pipeline overhead and extra OCI artifact to maintain before proving out the tool.
- **Recommendation**: Begin with **Option C1** (or a clean modular directory in `kubernetes/fleet/k3s/apps/kubeopencode` or `kubernetes/apps` referenced locally) to validate and iterate quickly, while architecturally keeping the controller and config layers strictly separated.

---

## 4. Architecture: Differentiating Controller vs. Configuration

```
kubernetes/fleet/k3s/
├── flux-system/
│   ├── flux-instance.yaml
│   └── runtime-info.yaml
├── infra-addons/
│   ├── 0-source.yaml
│   ├── 1-kustomize.yaml
│   └── values/
├── apps/
│   └── kubeopencode/
│       ├── kustomization.yaml             # Emits Flux Kustomization CRs
│       ├── 0-controller.yaml              # Flux Kustomization: kubeopencode-controller
│       ├── 1-config.yaml                  # Flux Kustomization: kubeopencode-config (dependsOn controller)
│       ├── 0-controller/                  # SYSTEM / CONTROLLER PLANE (reconciled by 0-controller.yaml)
│       │   ├── kustomization.yaml
│       │   ├── namespace.yaml             # kubeopencode-system
│       │   ├── helm-repository.yaml       # oci://ghcr.io/kubeopencode/helm-charts
│       │   └── helm-release.yaml          # HelmRelease with server enabled, CRD install
│       └── 1-config/                      # USER / WORKLOAD PLANE (reconciled by 1-config.yaml)
│           ├── kustomization.yaml
│           ├── namespace.yaml             # kubeopencode-apps
│           ├── rbac.yaml                  # Agent ServiceAccount + scoped Role/RoleBinding
│           ├── secrets.example.yaml       # Template for LLM API keys / Git credentials
│           ├── default-agent.yaml         # Base Agent definition (e.g. devbox, model spec)
│           └── smoke-task.yaml            # Smoke-test Task verification
```

### Key Differences Between Layers

| Aspect | 0-controller (System) | 1-config (Configuration) |
| :--- | :--- | :--- |
| **Namespace** | `kubeopencode-system` | Dedicated workload namespace (e.g., `kubeopencode-apps` or `default`) |
| **Contents** | CRDs, Controller Deployment, Web UI Server & Service, ClusterRoles | Agent specs, AgentTemplates, Tasks, CronTasks, Workload ServiceAccounts, Secrets |
| **Permissions** | Broad operator permissions across cluster | Scoped exclusively to the workload namespace |
| **Lifecycle** | Infrequent updates (Helm chart versions) | High-frequency iterations (prompts, models, repositories, task runs) |
| **Flux Dependency** | Deployed first | Uses `dependsOn: [kubeopencode-controller]` to guarantee CRDs exist before applying CRs |

---

## 5. Technical Manifest Blueprint

### 5.1 Controller (`0-controller/helm-release.yaml`)
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: kubeopencode
  namespace: flux-system
spec:
  interval: 1h
  targetNamespace: kubeopencode-system
  install:
    crds: CreateReplace
    remediation:
      retries: 3
  upgrade:
    crds: CreateReplace
    remediation:
      retries: 3
  chart:
    spec:
      chart: kubeopencode
      version: "0.1.9"
      sourceRef:
        kind: HelmRepository
        name: kubeopencode
        namespace: flux-system
  values:
    controller:
      replicas: 1
      resources:
        limits:
          cpu: 500m
          memory: 512Mi
        requests:
          cpu: 100m
          memory: 128Mi
    server:
      enabled: true
      service:
        type: ClusterIP
        port: 2746
      auth:
        enabled: true
      resources:
        limits:
          cpu: 500m
          memory: 256Mi
        requests:
          cpu: 100m
          memory: 128Mi
    kubeopencodeConfig:
      create: true
```

### 5.2 Agent RBAC (`1-config/rbac.yaml`)
KubeOpenCode requires each Agent to have a dedicated ServiceAccount in its namespace:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kubeopencode-agent
  namespace: kubeopencode-apps
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: kubeopencode-agent-role
  namespace: kubeopencode-apps
rules:
  - apiGroups: ["kubeopencode.io"]
    resources: ["tasks"]
    verbs: ["get", "list", "watch", "update", "patch"]
  - apiGroups: [""]
    resources: ["pods", "pods/log", "events"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: kubeopencode-agent-rolebinding
  namespace: kubeopencode-apps
subjects:
  - kind: ServiceAccount
    name: kubeopencode-agent
    namespace: kubeopencode-apps
roleRef:
  kind: Role
  name: kubeopencode-agent-role
  apiGroup: rbac.authorization.k8s.io
```

### 5.3 Agent Definition (`1-config/default-agent.yaml`)
```yaml
apiVersion: kubeopencode.io/v1alpha1
kind: Agent
metadata:
  name: dev-agent
  namespace: kubeopencode-apps
spec:
  profile: "General-purpose dev agent on K3s"
  workspaceDir: /workspace
  serviceAccountName: kubeopencode-agent
  standby:
    idleTimeout: 30m
  config:
    $schema: https://opencode.ai/config.json
    model: opencode/big-pickle # Zero API-key required default, or custom model
```

---

## 6. Implementation Phasing & Milestones

1. **Phase 1: Architecture Review & Alignment**
   - Confirm monorepo location (`kubernetes/fleet/k3s/apps/kubeopencode` vs top-level `kubernetes/apps`).
   - Finalize values and resource boundaries.
2. **Phase 2: Controller Deployment**
   - Add OCI `HelmRepository` for `oci://ghcr.io/kubeopencode/helm-charts`.
   - Add `HelmRelease` with CRD installation and hardened resource requests/limits.
   - Verify controller and server pods are running in `kubeopencode-system`.
3. **Phase 3: Workload Configuration & RBAC**
   - Create workload namespace, ServiceAccount, and namespace-scoped RoleBinding.
   - Create Secret scaffolding (for OpenAI, Anthropic, or Gemini tokens).
   - Define baseline `Agent` with auto-standby enabled.
4. **Phase 4: Smoke Test & Task Execution**
   - Submit a test `Task` (e.g. system info or echo test).
   - Validate task pod creation, execution log streaming, and completion phase.
5. **Phase 5: Exposure & Access**
   - Test UI port-forwarding (`kubectl port-forward -n kubeopencode-system svc/kubeopencode-server 2746:2746`).
   - (Optional) Configure OpenZiti service mapping for zero-trust remote access to the UI.

---

## 7. Current Status & Next Actions
- [x] Initial research on KubeOpenCode architecture, Helm chart, CRDs, and security model.
- [x] Captured PARA Project note in `docs/1-projects/install-kubeopencode-k3s.md`.
- [x] Prepared implementation plan artifact and aligned on application architecture.
- [x] Created `0-controller/` manifests (namespace, OCI `HelmRepository`, `HelmRelease`).
- [x] Created `1-config/` manifests (workload namespace, `kubeopencode-agent` ServiceAccount, scoped Role/RoleBinding, `dev-agent` CR, and `smoke-test` Task).
- [x] Integrated `apps/` into `kubernetes/fleet/k3s/kustomization.yaml`.
- [x] Opened Pull Request [#244](https://github.com/xNok/infra-bootstrap-tools/pull/244) for review.
- [ ] Evaluate reusable controller vs. in-tree per-namespace agent workload architecture.
- [ ] Deploy and verify controller pod health and CRD registration on K3s cluster.
- [ ] Verify agent pod initialization and smoke test task completion.
- [ ] Configure OpenZiti / port-forward access for the KubeOpenCode web UI (port 2746).

---

## 8. Architectural Evaluation: Reusable Controller & In-Tree Per-Namespace Agents

### 8.1 The Proposed Concept
Instead of coupling the controller and an ad-hoc single config layer inside `fleet/k3s/apps/kubeopencode/`:
1. **Reusable Controller**: Package the KubeOpenCode operator installation (namespace, OCI HelmRepository, HelmRelease, and controller configuration) into a shared, reusable location (e.g. `kubernetes/apps/kubeopencode/controller/`), publishable or consumable across any fleet cluster (`k3s`, `kind`, production).
2. **In-Tree Agent Workloads per Namespace**: Organize cluster-specific agent definitions around **application namespaces** in the cluster tree (e.g. `fleet/k3s/apps/<namespace>/` or `apps/<namespace>/`). Each application namespace defines its own Agent, ServiceAccount, RBAC, and credentials, with an explicit Flux dependency: `dependsOn: [kubeopencode-controller]`.

```
kubernetes/
├── apps/                                      # SHARED / REUSABLE APPS
│   └── kubeopencode/
│       └── controller/                        # Controller & Server HelmRelease (reusable)
│           ├── kustomization.yaml
│           ├── namespace.yaml                 # kubeopencode-system
│           ├── helm-repository.yaml           # oci://ghcr.io/kubeopencode/helm-charts
│           └── helm-release.yaml              # Operator + UI server + CRDs
│
└── fleet/
    └── k3s/
        ├── flux-system/
        ├── infra-addons/
        └── apps/                              # IN-TREE CLUSTER WORKLOADS
            ├── kustomization.yaml             # Coordinates controller + app namespaces
            ├── kubeopencode-controller.yaml   # Flux Kustomization deploying reusable controller
            │
            ├── agentic/                       # Workload Namespace 1 (e.g. Prefect/AI flows)
            │   ├── kustomization.yaml         # Flux Kustomization (dependsOn: kubeopencode-controller)
            │   ├── namespace.yaml
            │   ├── rbac.yaml                  # Scoped agent SA in 'agentic'
            │   ├── agent.yaml                 # Agent tailored for workflow automation
            │   └── tasks/
            │
            └── devbox/                        # Workload Namespace 2 (e.g. developer sandbox)
                ├── kustomization.yaml         # Flux Kustomization (dependsOn: kubeopencode-controller)
                ├── namespace.yaml
                ├── rbac.yaml                  # Scoped agent SA in 'devbox'
                ├── agent.yaml                 # Interactive dev agent with auto-standby
                └── tasks/
```

### 8.2 Dimension Analysis & Evaluation

| Dimension | Current Approach (Coupled `kubeopencode` folder) | Proposed Approach (Reusable Controller + In-Tree Namespace Agents) | Verdict |
| :--- | :--- | :--- | :--- |
| **Separation of Concerns** | Controller and single config are co-located under `fleet/k3s/apps/kubeopencode/`. | Platform operator separated from app/team workloads; each team owns their agent folder. | **Proposed is superior**: strictly aligns platform engineering with multi-tenant developer workloads. |
| **Reusability Across Clusters** | Controller manifests are duplicated if added to `kind` or other clusters. | Shared controller manifests (`kubernetes/apps/kubeopencode/controller`) can be reused across all fleet clusters. | **Proposed is superior**: eliminates manifest duplication across `fleet/kind` and `fleet/k3s`. |
| **Security & Blast Radius** | Single `kubeopencode-apps` namespace with one shared ServiceAccount. | Independent ServiceAccounts, Roles, and Secrets per namespace; agents cannot access adjacent workloads. | **Proposed is superior**: satisfies Kubernetes least-privilege principles and bounds prompt injection risks. |
| **Operational Scalability** | Adding a new agent requires editing the monolithic config directory. | Onboarding a new agent/team is as simple as adding a new `apps/<namespace>/` folder. | **Proposed is superior**: declarative, modular, and non-blocking for teams. |
| **GitOps Delivery & CRD Safety** | Flux Kustomization gates config behind controller readiness. | Flux Kustomizations per namespace all declare `dependsOn: [kubeopencode-controller]`. | **Both safe**, but proposed scales across N namespaces without race conditions. |
| **CI/CD & Pipeline Complexity** | Minimal CI impact (everything lives in `fleet/k3s`). | Requires either publishing a shared `apps` OCI artifact or referencing via GitRepository. | **Trade-off**: Requires updating `.github/workflows/flux-oci-publish.yml` if using OCI. |

### 8.3 Implementation Paths for Reusable Controller

1. **Path A (Full Flux D2 — Dedicated `apps` OCI Artifact)**:
   - Create `kubernetes/apps/kubeopencode/controller`.
   - Update `.github/workflows/flux-oci-publish.yml` to publish `oci://ghcr.io/xnok/manifests/kubernetes/apps`.
   - In `fleet/k3s`, declare `OCIRepository/apps` and `Kustomization/kubeopencode-controller`.
   - *Best for*: Pure Gitless GitOps, matching how `infra-addons` is delivered.
2. **Path B (GitRepository Source in Fleet)**:
   - Fleet declares a `GitRepository` pointing to the repo, and a `Kustomization` targeting `./kubernetes/apps/kubeopencode/controller`.
   - *Best for*: Avoiding OCI pipeline changes while keeping directories reusable in git.
3. **Path C (Fleet Modular In-Tree Apps)**:
   - In `fleet/k3s/apps/`: maintain `controller.yaml` deploying the upstream Helm chart, while converting `apps/` into modular namespaces (`apps/agentic/`, `apps/devbox/`, etc.).
   - *Best for*: Immediate zero-overhead adoption while still achieving the per-namespace agent architecture.

---

### 8.4 The `ResourceSet` Agent Catalogue Pattern

The [Flux Operator ResourceSet API](https://fluxoperator.dev/docs/crd/resourceset/) offers an alternative pattern inspired by the multi-tenant pattern: **an Agent Catalogue**.

Instead of writing 5 distinct Kubernetes manifests per agent across nested directories, a single `ResourceSet` defines the canonical agent runtime template, and uses `spec.inputs` as a lightweight catalogue:

```yaml
apiVersion: fluxcd.controlplane.io/v1
kind: ResourceSet
metadata:
  name: kubeopencode-agents
  namespace: flux-system
  annotations:
    fluxcd.controlplane.io/reconcile: "enabled"
spec:
  # Native CRD dependency gating: only generates agents after CRDs exist!
  dependsOn:
    - apiVersion: apiextensions.k8s.io/v1
      kind: CustomResourceDefinition
      name: agents.kubeopencode.io
      ready: true

  # The Agent Catalogue: Define all agents in one clean table
  inputs:
    - name: workflow-agent
      namespace: agentic
      profile: "AI workflow orchestrator"
      model: "anthropic/claude-3-7-sonnet"
      standby: "30m"
    - name: dev-agent
      namespace: default
      profile: "General development agent"
      model: "opencode/big-pickle"
      standby: "15m"

  # Canonical template generated for every catalogue entry
  resources:
    - apiVersion: v1
      kind: Namespace
      metadata:
        name: << inputs.namespace >>
    - apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: kubeopencode-agent
        namespace: << inputs.namespace >>
    - apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        name: kubeopencode-agent-role
        namespace: << inputs.namespace >>
      rules:
        - apiGroups: ["kubeopencode.io"]
          resources: ["tasks"]
          verbs: ["get", "list", "watch", "update", "patch"]
        - apiGroups: [""]
          resources: ["pods", "pods/log", "events"]
          verbs: ["get", "list", "watch"]
    - apiVersion: rbac.authorization.k8s.io/v1
      kind: RoleBinding
      metadata:
        name: kubeopencode-agent-rolebinding
        namespace: << inputs.namespace >>
      subjects:
        - kind: ServiceAccount
          name: kubeopencode-agent
          namespace: << inputs.namespace >>
      roleRef:
        kind: Role
        name: kubeopencode-agent-role
        apiGroup: rbac.authorization.k8s.io
    - apiVersion: kubeopencode.io/v1alpha1
      kind: Agent
      metadata:
        name: << inputs.name >>
        namespace: << inputs.namespace >>
      spec:
        profile: << inputs.profile | quote >>
        workspaceDir: /workspace
        serviceAccountName: kubeopencode-agent
        standby:
          idleTimeout: << inputs.standby | default "30m" | quote >>
        config:
          $schema: https://opencode.ai/config.json
          model: << inputs.model | quote >>
```

#### Why the ResourceSet Pattern is Compelling:
1. **Zero Boilerplate**: Adding a new agent in a new namespace is just adding 5 lines to `inputs` in a single file, rather than creating 5 new YAML files and nested folders.
2. **Built-in CRD Safety**: `spec.dependsOn` natively checks `CustomResourceDefinition: agents.kubeopencode.io (ready: true)`. The operator will not template agents until the HelmRelease completes.
3. **Resource Deduplication**: Flux Operator automatically deduplicates resources (e.g. if two agents share a namespace, the `Namespace` resource is applied only once).
4. **Already Installed**: `flux-operator` is already active in `k3s` and `kind` (`flux-operator.yaml`).
