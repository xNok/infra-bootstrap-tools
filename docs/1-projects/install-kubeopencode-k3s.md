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
- [x] Evaluated reusable controller vs. in-tree per-namespace agent workload architecture.
- [x] Completed deep-dive analysis on the "Whole Agent" architecture and AgentTemplate catalogue pattern.
- [x] Implemented the `palette-agent` catalogue entry in `kubernetes/apps/agents/palette-agent/`.
- [x] Wired `palette-agent` deployment into `kubernetes/fleet/k3s/apps/`.
- [x] Rebased branch onto latest `origin/main` to leverage `kubeztl` Nix package and updated OpenZiti stack.
- [x] Verified controller pod health (`kubeopencode-controller` & `kubeopencode-server` 1/1 Running) on K3s cluster.
- [x] Verified agent pod initialization and smoke test task completion (`smoke-test-pod` Completed) in `kubeopencode-apps`.
- [x] Configured OpenZiti zero-trust dark service `opencode.ziti` (intercepting ports 80 & 2746 -> server:2746) and verified live HTTP 200 web UI access.
- [x] Provisioned `KUBEOPENCODE_OPENCODE_GO` in 1Password Connect vault `infra-bootstrap-tools`.
- [x] Created `ExternalSecret/llm-token-creds` in `kubernetes/fleet/k3s/apps/palette-agent/1-instance/external-secret-llm.yaml`.
- [x] Verified `palette-agent-server` pod transition to `2/2 Running` and `Agent/palette-agent` transition to `READY: true`.
- [x] Verified live task execution and completion (`Task/qwe` -> `Completed` via `qwe-pod`).

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

#### The Critical Limitation (The Homogeneity Trap):
While ResourceSet is very effective for uniform, simple agent instances, real-world agent platforms (such as the official [kubeopencode-agent](https://github.com/kubeopencode/kubeopencode-agent)) feature complex, heterogeneous agents (e.g. `sre-agent`, `slack-agent`) with multi-resource satellite stacks, specialized RBAC, CronTasks, and custom skills. Forcing heterogeneous agents into a single ResourceSet template creates an unmaintainable "mega-template". See **Section 10** for the deep-dive analysis.

---

## 9. Architectural Synthesis: Agentic Platform, Agent Catalogue & Value Layering

### 9.1 The Long-Term Vision
We are transitioning from a single one-off tool deployment to an **Agentic Platform Architecture**:
1. **Agentic Platform (Control Plane / Operators as Apps)**:
   - Infra-like platform services running as applications on the cluster.
   - Core components: `kubeopencode` controller & UI server, and future additions like `kagent`, `agentgateway`, MCP hubs, or model routers.
   - Reusable across clusters via a shared OCI package (`manifests/kubernetes/apps/agentic-platform`).
2. **Agent Catalogue (Shared Agent Blueprints)**:
   - A curated catalogue of reusable agents and tasks (e.g., `code-reviewer`, `ci-triage`, `docs-updater`, `general-devbox`).
   - Defines standard profiles, toolchains, container images, and baseline model choices.
3. **Cluster & Namespace Instantiations (The Overlay / Layering)**:
   - The actual agents running in specific namespaces on a specific cluster (e.g., `agentic` namespace on K3s, `staging` namespace on Kind).

---

### 9.2 Where Does the Overlay / Value Layering Go?

The central design question is: **Where do cluster-specific and namespace-specific overrides live relative to the shared catalogue and controller?**

We identify two distinct layering boundaries:

#### Boundary A: Platform Controller Layering
- **Shared Base**: The chart reference and universal defaults (e.g. leader election, security contexts, metrics).
- **Where the Overrides Go**:
  - In `kubernetes/fleet/<cluster>/apps/agentic-platform/values.yaml` (or via `valuesFrom` ConfigMap).
  - Configures cluster-specifics: ingress/OpenZiti hosts, storage classes, and replica counts (1 on K3s, 2 on cloud).

#### Boundary B: Agent Catalogue Layering (The Workload Layer)
An Agent requires both **catalogue traits** (profile, prompt, images, tools) and **local traits** (namespace, secret references, standby timeouts, resource quotas).

Where does this layering live? Three concrete architectural options exist:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        OPTION 1: Kustomize Base & Overlays             │
│                                                                        │
│   Shared Catalogue (apps/)               Cluster Overlay (fleet/k3s/) │
│  ┌────────────────────────┐             ┌───────────────────────────┐  │
│  │ Base Agent CR          │◀────────────│ Patches:                  │  │
│  │ - profile, tools, image│ (Kustomize) │ - namespace: agentic      │  │
│  │ - default model        │             │ - secretRef: my-api-key   │  │
│  └────────────────────────┘             │ - standby: 15m            │  │
│                                         └───────────────────────────┘  │
├────────────────────────────────────────────────────────────────────────┤
│                        OPTION 2: Flux Operator ResourceSet             │
│                                                                        │
│   Shared Template (in RSet)              Cluster Inputs (in RSet)      │
│  ┌────────────────────────┐             ┌───────────────────────────┐  │
│  │ Template resources:    │◀────────────│ inputs:                   │  │
│  │ - Namespace            │ (Go Template│ - name: reviewer          │  │
│  │ - ServiceAccount, RBAC │ slim-sprig) │   namespace: team-a       │  │
│  │ - Agent CR             │             │   model: gemini-2.5-pro   │  │
│  └────────────────────────┘             └───────────────────────────┘  │
├────────────────────────────────────────────────────────────────────────┤
│                        OPTION 3: KubeOpenCode ConfigRef / Secret       │
│                                                                        │
│   Shared Template (ConfigMap)            Cluster Secret / CR           │
│  ┌────────────────────────┐             ┌───────────────────────────┐  │
│  │ opencode.json config   │◀────────────│ Agent.spec.configRef      │  │
│  │ (prompts, provider cfg)│ (ConfigRef) │ Agent.spec.credentials    │  │
│  └────────────────────────┘             └───────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

---

### 9.3 Structured Evaluation: Benefits, Risks, Alternatives & "Do Nothing"

#### 1. Benefits of the Proposed Agentic Platform + Catalogue Model
- **Platform Reusability**: KubeOpenCode (and future controllers like `kagent` or `agentgateway`) can be deployed to any fleet cluster (`k3s`, `kind`, production) from a single shared definition without duplicating manifests.
- **Tenant & Workload Isolation**: Agents are partitioned into distinct namespaces with independent ServiceAccounts and Secrets. An agent executing code in `agentic` cannot access secrets in `ci-triage` or `kubeopencode-system`.
- **Low-Friction Onboarding**: Adding an agent from the catalogue is declarative and takes minutes instead of writing raw RBAC, namespace, and agent YAML from scratch.
- **Unified Extensibility**: As new agentic tools emerge (e.g. Model Context Protocol proxies, AI gateways), they plug into the `agentic-platform` layer without altering individual agent workflows.

#### 2. Risks & Mitigations
- **Risk: Template / Go-Template Complexity (in ResourceSet)**:
  - *Risk*: Heavy use of slim-sprig syntax in YAML can be hard to read or debug.
  - *Mitigation*: Keep the ResourceSet template strictly focused on standard RBAC + Agent boilerplate; keep complex OpenCode options inside standalone ConfigMaps or Agent CRs.
- **Risk: Secret Exposure via GitOps**:
  - *Risk*: Defining agents in Git might tempt teams to commit API keys.
  - *Mitigation*: Standardize on `SecretRef` pointing to pre-provisioned Kubernetes Secrets (e.g., managed via 1Password/SOPS or External Secrets Operator).
- **Risk: Upstream KubeOpenCode CRD Evolution**:
  - *Risk*: `v1alpha1` schemas may introduce breaking changes across minor releases.
  - *Mitigation*: Pin the Helm chart version in the controller release and validate upgrades on `kind` integration tests before promoting to `k3s`.

#### 3. Alternatives Evaluated for Value Layering

| Alternative | Where Layering Goes | Pros | Cons |
| :--- | :--- | :--- | :--- |
| **Alt A: Kustomize Base & Overlays** | Overlays in `fleet/<cluster>/apps/<app>/` patch base in `kubernetes/apps/` | Standard Kubernetes pattern; clear Git tree. | High file count; requires deep relative paths or OCI packaging of base. |
| **Alt B: ResourceSet Inputs (Catalogue)** | `inputs:` table in `fleet/<cluster>/apps/agents.yaml` | **Zero directory sprawl**; single file declares all cluster agents; built-in CRD dependency gating. | Uses Flux Operator syntax (`<< inputs.x >>`). |
| **Alt C: KubeOpenCode ConfigMap `configRef`** | OpenCode config in ConfigMap; secrets in Secret; thin Agent CR in fleet. | Native to KubeOpenCode; separates model config from credentials. | Doesn't automate Namespace and RBAC creation. |

#### 4. The "Do Nothing" Baseline Analysis
- **What "Do Nothing" Means**: Keeping our current commit where `0-controller` and `1-config` live together under `kubernetes/fleet/k3s/apps/kubeopencode/`.
- **Consequences of Doing Nothing**:
  - **No Cross-Cluster Reusability**: When we want KubeOpenCode on `fleet/kind` for local testing, we would have to copy the entire `0-controller/` directory, causing configuration drift.
  - **Monolithic Agent Namespace**: All agents are dumped into `kubeopencode-apps`, sharing a single ServiceAccount and secret pool, violating least-privilege principles.
  - **Poor Extensibility**: When adding `kagent` or `agentgateway`, we would have to invent another ad-hoc directory rather than having a recognized `agentic-platform` layer.
- **Conclusion**: "Do Nothing" is sufficient for a 1-day smoke test, but fundamentally inadequate for an extensible agentic infrastructure stack.

---

### 9.4 Concrete Recommended Layout

```
kubernetes/
├── apps/                                           # SHARED PLATFORM APPLICATIONS
│   └── agentic-platform/
│       └── kubeopencode/                           # Reusable Controller Layer
│           ├── namespace.yaml                      # kubeopencode-system
│           ├── helm-repository.yaml                # oci://ghcr.io/kubeopencode/helm-charts
│           ├── helm-release.yaml                   # Controller, server, CRD config
│           └── kustomization.yaml
│
└── fleet/
    └── k3s/
        └── apps/                                   # CLUSTER WORKLOAD & AGENT OVERLAYS
            ├── kustomization.yaml
            ├── agentic-platform.yaml               # Flux Kustomization pointing to apps/agentic-platform
            │
            └── agent-catalogue.yaml                # Flux ResourceSet: Instantiates agents per namespace
```

---

## 10. Deep-Dive Analysis: The "Whole Agent" Architecture, SRE Agent Complexity & Multi-Tier Layering

### 10.1 Real-World Case Study: `kubeopencode-agent` Anatomy
A real-world inspection of upstream [`kubeopencode-agent`](https://github.com/kubeopencode/kubeopencode-agent) reveals that modern AI agents in Kubernetes are **composite systems** built on the **"Repo-as-Agent"** pattern.

The repository exhibits a profound division of responsibilities:
1. **The Cognitive Layer (Brain & Skills)**:
   - `AGENTS.md` / `README.md`: Instruction set, execution principles, progressive disclosure checklists.
   - `.claude/skills/`: Reusable specialized agent capabilities (e.g., `github-respond`, `slack-respond`).
   - `workflows/`: Standard Operating Procedures (SOPs) for scheduled routines (`daily-pr-review.md`, `periodic-tiny-refactor.md`, `weekly-fix-vulnerabilities.md`).
   - `.opencode/plugins/`: UI and runtime extensions (e.g. `@kubeopencode/opencode-slack-plugin`).
   - `repos/repos.yaml`: External repository dependencies, cloned dynamically into worktrees on demand.
2. **The Infrastructure Runtime Layer (Kubernetes CRDs)**:
   - `AgentTemplate` (`kubeopencode-base`): Defines the container images (`agent-opencode` + `agent-devbox`), workspace directory, service account, resource quotas, git context hot-reloading (`HotReload: 5m`), proxy configs, and shared credentials.
   - `Agent` (`kubeopencode-agent`, `slack-agent`): Thin resources referencing `templateRef: kubeopencode-base` with specialized standby timeouts, session PVC persistence (`size: 1Gi`), and rate limiting quotas.
   - `CronTask`: Native KubeOpenCode scheduled task resources (`crontask-pr-review.yaml`, `crontask-tiny-refactor.yaml`).
   - `deploy/rbac.yaml`: Granular permissions for the agent ServiceAccount (reading tasks, updating status, self-discovery, pod logs, configmaps).
3. **The Satellite Platform Ecosystem (`deploy/sre/`)**:
   - The SRE agent is not an isolated pod—it is an **operational capability bundle** containing:
     - A full telemetry and alerting stack: `prometheus`, `node-exporter`, `kube-state-metrics`, `alertmanager`, `otel-collector`, and `rules/prometheus-rules.yaml`.
     - Operational daemon CronJobs: `dns-guardian.yaml` (auto-syncing host.k3s.internal DNS entries with dynamic K3s node IPs, with dedicated Roles to patch CoreDNS and restart deployments).
     - ChatOps gateways: `socket-mode-gateway.yaml` connecting Slack directly to agent task creation.

---

### 10.2 Why `ResourceSet` Fails as a Complex Agent Catalogue

In Section 8.4, we evaluated the Flux Operator `ResourceSet` pattern. While `ResourceSet` is very attractive for homogeneous tenant generation (e.g. stamping out 50 identical namespaces with identical standard agent templates), **it breaks down when applied to heterogeneous, complex agents like `sre-agent`**:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   THE RESOURCE-SET HOMOGENEITY TRAP                    │
│                                                                        │
│  ResourceSet Assumption:                                               │
│  ┌──────────────┐   stamps out   ┌──────────────────────────────────┐  │
│  │ inputs: [A,B]│───────────────▶│ Identical YAML skeleton for all  │  │
│  └──────────────┘                │ (Namespace + SA + Role + Agent)  │  │
│                                  └──────────────────────────────────┘  │
│                                                                        │
│  Real-World Heterogeneous Reality:                                     │
│  - Dev Agent:     1 Agent CR + local namespace RBAC                    │
│  - Slack Agent:   1 Agent CR + PVC persistence + Socket Mode Gateway   │
│  - SRE Agent:     1 Agent CR + ClusterRoles + Prometheus stack         │
│                   + Alertmanager + dns-guardian CronJob + CronTasks    │
│                                                                        │
│  Result if forced into ResourceSet:                                    │
│  ❌ Massive "Mega-Template" full of brittle `<< if eq inputs.type >>` │
│  ❌ Templating markdown workflows & bash scripts into raw strings      │
│  ❌ Blast radius: changing 1 agent re-evaluates all cluster agents     │
└────────────────────────────────────────────────────────────────────────┘
```

1. **Heterogeneous vs Homogeneous Lifecycles**: An SRE agent requires cluster-wide node/pod inspection rights and auxiliary cron jobs, while a dev agent requires strictly scoped local namespace rights. Templating this in a single ResourceSet template requires massive conditional branching (`<< if eq inputs.type "sre" >>`).
2. **Loss of Native Tooling**: Storing alerting rules, shell scripts, or Prometheus manifests inside a Go-templated ResourceSet string strips away linting, syntax validation, and Helm/Kustomize diff capabilities.
3. **Coupled Blast Radius**: If the ResourceSet template has a syntax error, every agent across the entire cluster fails reconciliation simultaneously.

---

### 10.3 The "Whole Agent" Paradigm: Why Plain Helm/Kustomize Alone Falls Short

The user rightly observed: *"the sre-agent is a lot more complex and would not work only package as kustomize or helm"*.

Why does a plain Helm chart or plain Kustomize overlay fail to capture the "Whole Agent"?

Because an AI Agent is fundamentally different from a traditional stateless microservice. An AI Agent has a **dual lifecycle**:

| Dimension | Cognitive Lifecycle (The Brain) | Infrastructure Lifecycle (The Platform) |
| :--- | :--- | :--- |
| **Artifacts** | Prompts, `AGENTS.md`, `.claude/skills/`, `workflows/*.md`, OpenCode plugins. | `AgentTemplate`, `Agent` CR, ServiceAccount, RBAC, PVCs, CronJobs. |
| **Authors** | Prompt engineers, SREs, developers. | Platform engineers, cluster administrators. |
| **Velocity** | High velocity (multiple PRs daily; prompts and skills tuned constantly). | Low velocity (versioned platform releases, quarterly upgrades). |
| **Deployment Mechanism** | **Dynamic Hot-Reloading** via Git/OCI context sync into pod workspace. | GitOps controller reconciliation (`HelmRelease`, `Kustomization`). |
| **Impact of Updates** | Zero pod restart; changes active immediately on the next task invocation. | Pod recreation, container pull, rollout restart, potential session disruption. |

**The Failure of Pure Helm Packaging**:
If you attempt to package the "Whole Agent" as a monolithic Helm chart:
- Every prompt change or skill addition requires cutting a new Helm chart version, pushing an OCI chart artifact, and triggering a full Kubernetes rollout.
- Escaping complex markdown checklists, prompt templates, and bash scripts into Helm YAML values is notoriously brittle.
- It conflates platform infrastructure (Prometheus, CoreDNS crons) with the agent's cognitive persona.

---

### 10.4 The 4-Tier Solution: Where Does the Overlay / Value Layering Go?

To package, reuse, and customize complex agents like `sre-agent`, we separate the system into **4 cleanly delineated tiers**:

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                           TIER 1: AGENTIC PLATFORM                               │
│  Scope: Cluster-wide Operator & Control Plane (Reusable across all clusters)     │
│  Path:  kubernetes/apps/agentic-platform/kubeopencode/controller/                │
│  Contains: HelmRepository, HelmRelease (kubeopencode controller, server, CRDs)   │
└────────────────────────────────────────┬─────────────────────────────────────────┘
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                       TIER 2: AGENT BRAIN / KNOWLEDGE BASE                       │
│  Scope: Cognitive capabilities, prompts, skills, workflows (Repo-as-Agent)       │
│  Source: Git repo or OCI artifact (e.g. github.com/kubeopencode/kubeopencode-agent)│
│  Sync:   Hot-reloaded into agent container workspace via spec.contexts[type: Git]│
└────────────────────────────────────────┬─────────────────────────────────────────┘
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                       TIER 3: REUSABLE AGENT BLUEPRINTS                          │
│  Scope: Reusable Agent Catalog (Kustomize Components / AgentTemplate CRDs)       │
│  Path:  kubernetes/apps/agents/<agent-name>/ (e.g. sre-agent, dev-agent)         │
│  Contains: AgentTemplate CR, Agent CR, scoped RBAC, CronTasks, satellite rules   │
└────────────────────────────────────────┬─────────────────────────────────────────┘
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                   TIER 4: CLUSTER & ENVIRONMENT OVERLAYS                         │
│  Scope: Cluster-specific instantiations, secrets, network values                 │
│  Path:  kubernetes/fleet/<cluster>/apps/<namespace>/                             │
│  Contains:                                                                       │
│  - Flux Kustomization (dependsOn: [kubeopencode-controller, monitoring])         │
│  - Namespace declaration                                                         │
│  - SecretRefs (OpenAI / Anthropic / Kimi API keys, GitHub App, Slack tokens)    │
│  - Cluster Proxy & DNS (http://host.k3s.internal:7897)                           │
│  - Model selection & Standby timeout patches                                     │
└──────────────────────────────────────────────────────────────────────────────────┘
```

#### Exactly Where Each Layering Element Lives:
1. **The Brain (Skills, Prompts, Workflows)**: Lives in Git / OCI. It is referenced by `AgentTemplate.spec.contexts`. It updates independently of cluster infrastructure via dynamic git/OCI polling.
2. **The Base Blueprint (The Catalogue)**: Lives in `kubernetes/apps/agents/<agent-name>/`. This defines what the agent *is* (its container images, its RBAC requirements, its CronTasks, and its satellite Prometheus rules).
3. **The Cluster Overlay (The Values / Environment Layer)**: Lives in `kubernetes/fleet/<cluster>/apps/<workload>/`.
   - Uses Kustomize patches or `valuesFrom` secrets.
   - Binds the agent to a target namespace.
   - Injects credentials (pointing to 1Password/SOPS/ExternalSecrets).
   - Injects network endpoints (e.g. Clash proxy `host.k3s.internal:7897`, cluster Prometheus URL `http://prometheus-operated.monitoring:9090`).
   - Declares Flux `dependsOn` dependencies ensuring CRDs and observability stacks exist prior to agent activation.

---

### 10.5 Structured BRAIN Evaluation: Benefits, Risks, Alternatives & Do Nothing

#### 1. Benefits
- **Full Support for Complex Heterogeneous Agents**: SRE agents can bundle Prometheus alerting rules, OpenTelemetry collectors, and `dns-guardian` CronJobs without polluting or destabilizing simple developer agents.
- **Cognitive vs Platform Decoupling**: Prompt engineers and SREs iterate on skills and workflows in their git repository; platform engineers manage cluster RBAC and controller upgrades via GitOps. Neither blocks the other.
- **Zero-Downtime Hot-Reloading**: Context updates (`HotReload: 5m`) refresh agent capabilities inside existing pods without incurring pod restarts, container pulls, or session drops.
- **Least-Privilege Security**: RBAC is packaged strictly per agent capability. A general coding agent receives namespace-local task rights; only the SRE agent receives node/cluster diagnostic permissions.
- **Multi-Cluster Portability**: The same agent blueprint in `kubernetes/apps/agents/sre/` can be instantiated on K3s, Kind, or EKS simply by applying a thin cluster overlay with local secrets and proxy endpoints.

#### 2. Risks & Mitigations
- **Risk: Context Sync Failure in Restricted / Air-Gapped Clusters**:
  - *Detail*: If an agent pod cannot reach github.com to sync its `contexts`, the agent starts with an empty workspace.
  - *Mitigation*: Package the cognitive repository as an OCI artifact (`quay.io/.../agent-brain:v1`) pushed to our internal container registry, or mount it as a local ConfigMap / PVC for offline K3s clusters.
- **Risk: SRE Agent Blast Radius (High RBAC Privileges)**:
  - *Detail*: An SRE agent with permissions to patch CoreDNS and restart deployments could destabilize cluster networking if prompted improperly.
  - *Mitigation*: Separate diagnostic roles (`get, list, watch` on nodes and pods) from mutating operations. Mutating actions should be executed via dedicated, auditable CronJobs (like `dns-guardian`) or require human-in-the-loop task approval annotations.
- **Risk: Secret Reference Misalignment**:
  - *Detail*: A reusable agent blueprint expects a secret named `llm-credentials`, but the cluster overlay provisions `kimi-secret`.
  - *Mitigation*: Establish strict contract naming conventions for secret references across all agents, documented in the catalogue README.

#### 3. Alternatives Evaluated

| Feature | Alternative 1: Flux ResourceSet Matrix | Alternative 2: Monolithic Helm Chart per Agent | Alternative 3: 4-Tier Decoupled Architecture (Recommended) |
| :--- | :--- | :--- | :--- |
| **Agent Complexity** | Limited to uniform, simple agents. | Supports complex agents, but prompts are baked into YAML strings. | **Full support**: Brain, CRDs, RBAC, and satellites are modularized. |
| **Cognitive Velocity** | Low (editing prompts requires editing cluster GitOps YAML). | Low (requires cutting new Helm chart versions for prompt changes). | **Maximum**: Brain hot-reloads dynamically from Git/OCI without pod restarts. |
| **Reusability** | Poor across clusters (templates tied to specific inputs). | Moderate (Helm values provide parameterization, but high boilerplate). | **High**: Blueprints are reusable across K3s, Kind, and cloud fleets. |
| **Value Layering** | Hardcoded inside `inputs:` table in a single file. | Values files (`values.yaml` + `fleet-values.yaml`). | **Clean separation**: Base in `apps/agents/`, environment overlay in `fleet/<cluster>/`. |
| **CRD Dependency Safety** | Built-in via `dependsOn: CustomResourceDefinition`. | Requires manual hooks or Flux Kustomization wrappers. | Flux Kustomization `dependsOn: [kubeopencode-controller]` guarantees safety. |

#### 4. The "Do Nothing" Baseline Analysis
- **Definition**: Retaining the current ad-hoc setup (`fleet/k3s/apps/kubeopencode/` containing controller + single `1-config` namespace).
- **Consequences**:
  - Impossible to run a complex SRE agent or Slack agent without jamming all monitoring, cronjobs, and Slack secrets into `kubeopencode-apps`.
  - No mechanism to share agent definitions across clusters (`kind` vs `k3s`).
  - No separation between prompt/skill development and infrastructure management.
- **Conclusion**: Doing nothing blocks the transition to an autonomous, multi-agent platform.

---

### 10.6 Concrete Target Layout for `infra-bootstrap-tools`

```
kubernetes/
├── apps/
│   ├── agentic-platform/
│   │   └── kubeopencode/
│   │       └── controller/                            # Reusable Controller (HelmRelease)
│   │           ├── namespace.yaml                     # kubeopencode-system
│   │           ├── helm-repository.yaml               # oci://ghcr.io/kubeopencode/helm-charts
│   │           ├── helm-release.yaml                  # Controller + server
│   │           └── kustomization.yaml
│   │
│   └── agents/                                        # THE REUSABLE AGENT CATALOGUE
│       ├── dev-agent/                                 # Lightweight dev agent
│       │   ├── kustomization.yaml
│       │   ├── rbac.yaml                              # Namespace-scoped task/pod access
│       │   └── agent.yaml                             # Agent CR referencing base template
│       │
│       └── sre-agent/                                 # Complex operational agent bundle
│           ├── kustomization.yaml
│           ├── rbac.yaml                              # Cluster-wide diagnostic Role & ServiceAccount
│           ├── agent-template.yaml                    # Base images, devbox, git context sync
│           ├── agent.yaml                             # SRE Agent instance
│           ├── crontasks/                             # Periodic health checks & refactors
│           └── satellites/                            # dns-guardian CronJob, Prometheus alerting rules
│
└── fleet/
    └── k3s/
        └── apps/                                      # CLUSTER-SPECIFIC INSTANTIATIONS & OVERLAYS
            ├── kustomization.yaml
            ├── agentic-platform.yaml                  # Deploys kubeopencode controller
            │
            ├── dev-agent.yaml                         # Flux Kustomization -> apps/agents/dev-agent
            │                                          # Overlay: namespace=dev, secretRef=dev-llm-creds
            │
            └── sre-agent.yaml                         # Flux Kustomization -> apps/agents/sre-agent
                                                       # Overlay: namespace=monitoring, proxy=host.k3s.internal:7897,
                                                       #          dependsOn=[kubeopencode-controller, monitoring]
```

---

## 11. Worked Example: Migrating GitHub Actions Agent (`jules_palette_improvements`) to `AgentTemplate` Catalogue on K3s

### 11.1 The Source Workflow
We analyze a real-world automated agent workflow scheduled in GitHub Actions: [`jules_palette_improvements.yml`](https://github.com/mekitmedia/cncf-landscape-a-to-z/blob/main/.github/workflows/jules_palette_improvements.yml) from `mekitmedia/cncf-landscape-a-to-z`.

```yaml
# Source: .github/workflows/jules_palette_improvements.yml
name: Scheduled Jules Palette Improvement
on:
  schedule:
    - cron: '0 9 * * 4' # Weekly on Thursdays at 09:00 UTC
  workflow_dispatch:
jobs:
  jules-palette:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cat .github/prompts/palette_prompt.md
      - uses: google-labs-code/jules-action@v1.0.0
        with:
          prompt: ${{ steps.prompt.outputs.prompt }}
          jules_api_key: ${{ secrets.JULES_API_KEY }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Goal**: Google's `jules-action` will be decommissioned soon. We replace this GitHub Actions runner with a self-hosted, sovereign **Palette Agent** running on our K3s cluster, packaged cleanly through our Agent Catalogue.

---

### 11.2 Why `AgentTemplate` is the Key to Catalogue Distributability

Traditional folder-based Kustomize overlays (`Approach B` with `patches/` directories) are **not cleanly distributable**:
- They rely on fragile relative filesystem paths (`../../../../apps/agents/...`).
- When packaged as an OCI artifact, relative paths outside the artifact break.

KubeOpenCode's native **`AgentTemplate` CRD** solves this natively:
- **`AgentTemplate` IS the catalogue artifact**: It bundles the runtime environment (container images, devbox with `gh` CLI and `git`, context repositories, proxy configuration, and credential contracts).
- **`Agent` IS the cluster instance**: The cluster deployment only declares a minimal `Agent` CR pointing to `templateRef: { name: palette-agent }`, along with a `CronTask` for the schedule.

---

### 11.3 Step 1: The Catalogue Entry (`kubernetes/apps/agents/palette-agent/`)

In the shared catalogue repository/OCI artifact:

#### 1. `kubernetes/apps/agents/palette-agent/kustomization.yaml`
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - rbac.yaml
  - agent-template.yaml
  - crontask.yaml
```

#### 2. `kubernetes/apps/agents/palette-agent/rbac.yaml`
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: palette-agent-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: palette-agent-role
rules:
  - apiGroups: ["kubeopencode.io"]
    resources: ["tasks", "crontasks"]
    verbs: ["get", "list", "watch", "update", "patch"]
  - apiGroups: [""]
    resources: ["pods", "pods/log", "events"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: palette-agent-binding
subjects:
  - kind: ServiceAccount
    name: palette-agent-sa
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: palette-agent-role
```

#### 3. `kubernetes/apps/agents/palette-agent/agent-template.yaml`
```yaml
apiVersion: kubeopencode.io/v1alpha1
kind: AgentTemplate
metadata:
  name: palette-agent-template
spec:
  # OpenCode binary + devbox executor equipped with git, gh cli, node, and python
  agentImage: quay.io/kubeopencode/kubeopencode-agent-opencode:latest
  executorImage: quay.io/kubeopencode/kubeopencode-agent-devbox:latest
  workspaceDir: /workspace
  serviceAccountName: palette-agent-sa
  podSpec:
    resources:
      requests:
        memory: "512Mi"
        cpu: "250m"
      limits:
        memory: "2Gi"
        cpu: "1000m"
  # Target Repository Context: clones the target repo directly into workspace
  contexts:
    - name: cncf-landscape
      type: Git
      git:
        repository: https://github.com/mekitmedia/cncf-landscape-a-to-z.git
        ref: main
        sync:
          enabled: true
          interval: 10m
          policy: HotReload
      mountPath: .
  # Credential contracts: expects secrets in the running namespace
  credentials:
    - name: github
      secretRef:
        name: github-token-creds
    - name: llm
      secretRef:
        name: llm-api-creds
  # Default model & settings
  config:
    model: opencode/big-pickle
    share: disabled
```

#### 4. `kubernetes/apps/agents/palette-agent/crontask.yaml`
Replaces the GitHub Actions schedule (`cron: '0 9 * * 4'`):
```yaml
apiVersion: kubeopencode.io/v1alpha1
kind: CronTask
metadata:
  name: weekly-palette-improvements
spec:
  schedule: "0 9 * * 4" # Weekly on Thursdays at 09:00 UTC
  taskTemplate:
    spec:
      agentRef:
        name: palette-agent
      description: |
    You are "Palette" 🎨 - a UX-focused agent for this repository.

    Your mission is to implement exactly ONE small UX/accessibility improvement that is immediately visible, low-risk, and easy to review.

    Core rules:
    - Prioritize accessibility (ARIA labels, keyboard focus, semantic markup, alt text, clearer empty/error states).
    - Keep changes focused (<50 changed lines when possible).
    - Use existing design/classes; no dependency additions.
    - Avoid backend/performance/security work in this profile.

    Before coding:
    1. Read .Jules/palette.md (create if missing).
    2. Identify the best single UX win.
    3. If there is no clear UX win, stop and do not open a PR.

    After coding:
    1. Run relevant existing checks.
    2. Open a PR summarizing What/Why/A11y impact.
    3. Add a journal entry to .Jules/palette.md only for critical reusable lessons (not routine edits).
```

---

### 11.4 Step 2: How to Add the Palette Agent to Your K3s Deployment

On your K3s cluster, deploying the Palette Agent requires **only two files** in `kubernetes/fleet/k3s/apps/`:

#### File 1: `kubernetes/fleet/k3s/apps/palette-agent.yaml`
A Flux `Kustomization` that deploys the catalogue entry into the cluster under namespace `agentic-workflows`:
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: palette-agent
  namespace: flux-system
spec:
  interval: 1h
  prune: true
  sourceRef:
    kind: OCIRepository
    name: flux-system
  path: "./apps/agents/palette-agent"
  targetNamespace: agentic-workflows
  dependsOn:
    - name: kubeopencode-controller
```

#### File 2: `kubernetes/fleet/k3s/apps/palette-agent-instance.yaml`
The local cluster instance (the `Agent` CR) and its namespace:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: agentic-workflows
---
apiVersion: kubeopencode.io/v1alpha1
kind: Agent
metadata:
  name: palette-agent
  namespace: agentic-workflows
spec:
  # Inherits everything from the catalogue AgentTemplate!
  templateRef:
    name: palette-agent-template
  profile: "Palette UX Improvement Agent for CNCF Landscape"
  standby:
    idleTimeout: "15m" # Shuts down container after 15m idle to preserve K3s RAM
```

#### File 3: The Secret (Provided via 1Password / SealedSecret / SOPS)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: github-token-creds
  namespace: agentic-workflows
type: Opaque
stringData:
  GITHUB_TOKEN: "ghp_..." # Token with write permissions to mekitmedia/cncf-landscape-a-to-z
---
apiVersion: v1
kind: Secret
metadata:
  name: llm-api-creds
  namespace: agentic-workflows
type: Opaque
stringData:
  ANTHROPIC_API_KEY: "sk-ant-..."
```

---

### 11.5 What Happens During Execution on K3s?
1. **At 09:00 UTC on Thursday**: The `CronTask` triggers.
2. **KubeOpenCode Controller**: Wakes `palette-agent` from standby, mounting the latest `git` commit of `mekitmedia/cncf-landscape-a-to-z`.
3. **Execution**: The devbox executor container executes Claude 3.7 Sonnet, inspecting the repo, picking an a11y improvement, running tests, committing, and opening a Pull Request via GitHub API.
4. **Auto-Standby**: After task completion, the agent automatically suspends after 15 minutes idle, consuming **0 CPU and 0 RAM** on K3s until next Thursday.

---

## 12. Adversarial Code & Security Review (PR #244)

Conducted against high engineering, security, and GitOps standards.

### 12.1 Findings Matrix

| ID | Severity | Category | Target | Description |
| :--- | :--- | :--- | :--- | :--- |
| **SEC-01** | **High** | Privilege Escalation | `palette-agent/rbac.yaml` | `palette-agent-role` grants `update` and `patch` verbs on `crontasks`. An untrusted or prompt-injected LLM can rewrite its own trigger, schedule, or prompt. |
| **SEC-02** | **Medium** | Credential Exposure | `ServiceAccount` definitions | `automountServiceAccountToken` is not disabled. By default, Kubernetes mounts internal service account JWTs into devbox pods executing external target code. |
| **SEC-03** | **Medium** | Supply Chain / Immutability | `agent-template.yaml` | Images are tagged `:latest` (`kubeopencode-agent-opencode:latest`, `kubeopencode-agent-devbox:latest`). Violates GitOps reproducibility and pins. |
| **GIO-01** | **Critical** | Bootstrap Race Condition | `fleet/k3s/apps/palette-agent` | `kustomization.yaml` mixes Flux Kustomization CR (`0-catalogue.yaml`) with raw K8s CRs (`1-instance.yaml`). Root reconciler attempts to apply `kind: Agent` before controller CRDs are established. |
| **GIO-02** | **Medium** | GitOps Purity | `kubeopencode/1-config` | `smoke-task.yaml` (`kind: Task`) is hardcoded in permanent Flux `resources`. Ephemeral verification jobs should not be tracked as continuous desired state. |
| **ARC-01** | **Medium** | Architecture / Naming | `kubeopencode/1-config` | Misleading name `kubeopencode-config` actually deploys a sample `dev-agent`. Collides with expectation of controller settings vs agent workloads. |
| **ARC-02** | **Low** | Code Duplication | `kubernetes/apps` vs `fleet/k3s` | Full duplication of `palette-agent` catalogue manifests between root `kubernetes/apps` and `fleet/k3s/apps/palette-agent/catalogue` due to workflow token scope limitations. |

### 12.2 Remediation & Resolutions Implemented

1. **GIO-01 Resolved (Bootstrap Ordering)**:
   - Converted `1-instance.yaml` into a proper Flux `Kustomization` CR (`metadata.name: palette-agent-instance`) with `dependsOn: [{ name: palette-agent-catalogue }]`.
   - Moved instance manifests to `kubernetes/fleet/k3s/apps/palette-agent/1-instance/agent.yaml`.
   - Added `namespace.yaml` to `catalogue/` so `Namespace/agentic-workflows` is guaranteed to exist before any CR is applied.
2. **SEC-01 Resolved (RBAC Privilege Escalation)**:
   - In both `palette-agent/catalogue/rbac.yaml` and `kubernetes/apps/agents/palette-agent/rbac.yaml`, removed `update` and `patch` verbs on `crontasks`. Restricted `crontasks` verbs strictly to read-only (`get`, `list`, `watch`).
3. **GIO-02 & ARC-01 Resolved (GitOps Purity & Naming)**:
   - Removed `smoke-task.yaml` from continuous GitOps desired state.
   - Renamed `kubeopencode-config` to `kubeopencode-dev-agent` (`1-dev-agent.yaml` pointing to `./apps/kubeopencode/1-dev-agent`), clarifying that it manages the devbox agent workload in `kubeopencode-apps`.
4. **SEC-02/03 Evaluated (Floating Tags in GitOps)**:
   - Following user guidance: in GitOps, tracking HEAD (`:latest`) is expected behavior for rapid-iteration agent runtimes. Rather than freezing tags, logged a dedicated project in [docs/1-projects/floating-tags-slsa-validation.md](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/install_kubeopencode_k3s_cluster/docs/1-projects/floating-tags-slsa-validation.md) to implement SHA digest mutation and SLSA provenance verification via admission control.
5. **ARC-02 Addressed (Catalogue Bridge)**:
   - Added [kubernetes/apps/README.md](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/install_kubeopencode_k3s_cluster/kubernetes/apps/README.md) documenting that `kubernetes/apps/` is the authoritative shared library blueprint, temporarily mirrored into `fleet/k3s` until GitHub Actions workflow scope allows OCI publishing.

---

## 13. Secret & Identity Strategy: GitHub App vs. Personal Access Token (PAT)

When provisioning autonomous development agents (such as KubeOpenCode's `palette-agent`), selecting the appropriate authentication model for GitHub API and Git operations has significant implications for security, attribution, and CI/CD automation.

### 13.1 Comparison Matrix

| Dimension | Personal Access Token (PAT) | Fine-Grained PAT | GitHub App (Recommended for Production) |
| :--- | :--- | :--- | :--- |
| **Commit & PR Attribution** | Attributed to your personal user account (`@xNok`). | Attributed to your personal user account (`@xNok`). | Attributed to dedicated bot identity (`palette-agent[bot]`) with verified bot badge. |
| **Audit & Blame Clarity** | **Poor**: Human commits and autonomous bot commits are indistinguishable in git blame. | **Poor**: Same identity blending as classic PAT. | **Excellent**: Clear cryptographic separation between human team members and automated agent actions. |
| **Token Lifespan & Blast Radius** | Long-lived or non-expiring static secret. Leaked tokens remain valid until revoked. | Expirable (up to 365 days), but still a static token. | Short-lived installation access tokens (1 hour TTL) minted dynamically from private key. |
| **Repository Scoping** | **Broad / All-or-nothing**: Accesses all user/org repos matching scopes. | **Scoped**: Restricted to specific target repositories. | **Strictly Scoped**: Only accessible to repositories where the App is explicitly installed. |
| **CI / CD Pipeline Triggering** | Pull Requests opened by a PAT trigger standard `on: pull_request` GitHub Actions. | Same as classic PAT. | PRs opened by GitHub App trigger `on: pull_request` workflows cleanly without recursion blockers. |
| **API Rate Limits** | Shared with your personal CLI/IDE limit (5,000 req/hr). | Shared with personal user limit (5,000 req/hr). | Dedicated rate limit pool per installation (5,000 to 12,500+ req/hr, scales with org). |
| **Lifecycle Coupling** | Tied to employee/user account. Breaks on 2FA changes, password reset, or departure. | Tied to user account. | Organization/Repo owned asset. Fully independent of human member lifecycles. |

### 13.2 Recommended Evolution Path

1. **Phase 1 (Rapid Onboarding & Prototyping)**:
   - Use a **Fine-Grained Personal Access Token (PAT)**.
   - Scoped strictly to target repository `mekitmedia/cncf-landscape-a-to-z`.
   - Permissions: `Contents: Read and write`, `Pull requests: Read and write`.
   - Pass directly into namespace secret `github-token-creds`.
2. **Phase 2 (Production Sovereign Agent Platform)**:
   - Deploy a dedicated **GitHub App** (e.g., `Mekit AI Agents`).
   - Store the App ID and PEM Private Key in Kubernetes / External Secrets.
   - Use an automated token minter (or External Secrets Operator GitHub provider) to provide rotating 1-hour installation tokens to agent workloads.

### 13.3 1Password & External Secrets Operator (ESO) Implementation

For Phase 1, rather than distributing plaintext tokens or manual `kubectl` secret creation, credentials are fully managed declaratively using the existing `ClusterSecretStore/onepassword` (connected to vault `infra-bootstrap-tools`).

1. **1Password Reference**: `op://infra-bootstrap-tools/KUBEOPENCODE_GITHUB_PAT/password`
2. **ExternalSecret Manifest (`kubernetes/fleet/k3s/apps/palette-agent/1-instance/external-secret-github.yaml`)**:
   ```yaml
   apiVersion: external-secrets.io/v1
   kind: ExternalSecret
   metadata:
     name: github-token-creds
     namespace: agentic-workflows
   spec:
     refreshInterval: 1h
     secretStoreRef:
       kind: ClusterSecretStore
       name: onepassword
     target:
       name: github-token-creds
       creationPolicy: Owner
     data:
       - secretKey: GITHUB_TOKEN
         remoteRef:
           key: KUBEOPENCODE_GITHUB_PAT/password
   ```
3. **Automated Reconciliation**: Flux reconciles the `palette-agent-instance` Kustomization, which triggers ESO to retrieve the token from 1Password and populate the Secret `github-token-creds` in `agentic-workflows`.

---

## 14. Architecture Alignment: 4-Tier Layout Implementation

In accordance with Section 10.6, all shared application and platform definitions have been consolidated into `kubernetes/apps/`, completely decoupling cluster overlays in `kubernetes/fleet/` from base platform manifests.

```
kubernetes/
├── apps/                                           # TIER 3: SHARED CATALOGUE & APPS
│   ├── kustomization.yaml
│   ├── kubeopencode/                               # Platform Controller (Shared App)
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml                          # kubeopencode-system
│   │   ├── helm-repository.yaml                    # oci://ghcr.io/kubeopencode/helm-charts
│   │   └── helm-release.yaml                       # Controller + Server
│   │
│   └── kubeopencode-agents/                        # Reusable Agent Catalogue
│       └── palette-agent/
│           ├── kustomization.yaml
│           ├── namespace.yaml                      # agentic-workflows
│           ├── rbac.yaml                           # Scoped agent RBAC (read-only crontasks)
│           ├── agent-template.yaml                 # AgentTemplate CR
│           └── crontask.yaml                       # CronTask CR
│
└── fleet/
    └── k3s/
        └── apps/                                   # TIER 4: CLUSTER OPT-IN & OVERLAYS
            ├── 0-source.yaml                       # OCIRepository/apps source
            ├── kustomization.yaml                  # Coordinates app opt-ins
            ├── kubeopencode/                       # Opt-in to Platform Controller
            │   └── 0-controller.yaml               # Flux Kustomization -> sourceRef: apps, path: ./kubeopencode
            │
            └── palette-agent/                      # Opt-in to Workload Agent
                ├── 0-catalogue.yaml                # Flux Kustomization -> sourceRef: apps, path: ./kubeopencode-agents/palette-agent
                ├── 1-instance.yaml                 # Flux Kustomization -> cluster instance (dependsOn: catalogue)
                ├── 1-instance/                     # Agent CR (standby: 15m)
                └── external-secret-github.yaml     # Injects 1Password token into agentic-workflows
```

---

## 15. Packaging and OCI Publishing Pipelines

To ensure `kubernetes/apps` can be consumed across any fleet cluster via Flux `OCIRepository` sources, we integrated it with the monorepo's release and CI packaging pipelines:

1. **Package Workspace (`kubernetes/apps/package.json`)**:
   - Registered `"name": "kubernetes-apps"`, `"version": "0.1.0"` under npm workspaces (`"workspaces": ["kubernetes/*"]`).
   - Managed via Changesets (`.changeset/add-kubernetes-apps-catalogue.md`) for automated semantic versioning and release notes.

2. **Continuous OCI Publishing (`.github/workflows/flux-oci-publish.yml`)**:
   - Added `publish-apps` job running `./bin/ci/publish-flux-artifact.sh "${{ github.repository_owner }}" "./kubernetes/apps" "${{ github.event.repository.html_url }}" "apps"`.
   - On pushes and pull requests affecting `kubernetes/**`, publishes `oci://ghcr.io/xnok/manifests/kubernetes/apps` tagged with commit SHA and `:latest`.

3. **Versioned Release Workflow (`.github/workflows/release.yml`)**:
   - Added `publish-kubernetes-apps` triggered on git tags matching `kubernetes-apps@*`.
   - Calls `./bin/ci/release-kubernetes.sh`, dynamically parsing the tag and publishing immutable release artifacts tagged with the SemVer version (e.g. `:0.1.0`) and `:latest`.

---

## 16. Resolving Agent Standby / Server Initialization and Task Execution

### 16.1 Root Cause Analysis: Missing LLM Credential Contract
During post-merge cluster verification, while `0-catalogue` and `1-instance` Kustomizations reconciled, the `palette-agent` remained in `Starting` phase (`READY: false`) and queued tasks (e.g. `task.kubeopencode.io/qwe`) were not picked up.

Inspecting the cluster state revealed:
1. `AgentTemplate/palette-agent-template` specifies two credential contracts under `spec.credentials`:
   - `github-token-creds` (injected via ESO from `KUBEOPENCODE_GITHUB_PAT/password`)
   - `llm-api-creds` (expected secret for LLM API keys)
2. The agent pod `palette-agent-server-dbfd5f8f6-49j29` failed with `CreateContainerConfigError`:
   ```text
   Error: secret "llm-api-creds" not found
   ```
3. Controller loop logs indicated:
   ```text
   agent server not ready, remaining queued
   ```
   KubeOpenCode gates task dispatching on `agent.status.ready == true`, which requires the background server pod to be `2/2 Running` with passing HTTP readiness probes on `:4096/session/status`.

### 16.2 Resolution via 1Password & External Secrets Operator
1. **1Password Secret Provisioning**:
   - Item `KUBEOPENCODE_OPENCODE_GO` was created in 1Password vault `infra-bootstrap-tools`.
   - Contains OpenCode API Key (`oc_sk_...`) under the `password` field.
2. **GitOps ExternalSecret Configuration (`external-secret-llm.yaml`)**:
   ```yaml
   apiVersion: external-secrets.io/v1
   kind: ExternalSecret
   metadata:
     name: llm-token-creds
     namespace: agentic-workflows
   spec:
     refreshInterval: 1h
     secretStoreRef:
       kind: ClusterSecretStore
       name: onepassword
     target:
       name: llm-api-creds
       creationPolicy: Owner
     data:
       - secretKey: OPENCODE_API_KEY
         remoteRef:
           key: KUBEOPENCODE_OPENCODE_GO/password
       - secretKey: ANTHROPIC_API_KEY
         remoteRef:
           key: KUBEOPENCODE_OPENCODE_GO/password
   ```
3. **Execution & Verification**:
   - Replaced failing pod; new pod `palette-agent-server` immediately reached `2/2 Running`.
   - `Agent/palette-agent` transitioned to `READY: true`.
   - `Task/qwe` automatically transitioned from `Queued` -> `Running` (`qwe-pod` executing database migrations and task steps) -> `Completed`.







