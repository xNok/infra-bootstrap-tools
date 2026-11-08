# Our CNCF Contributions & Article Publishing Roadmap

This roadmap defines the concrete articles we are writing and publishing to the **[CNCF Landscape A-to-Z Medium publication](https://medium.com/cncf-landscape-a-to-z)**. Every article is drawn directly from working architectures, automation scripts, and operational lessons in **`infra-bootstrap-tools`**, with the explicit objective of **driving visibility, authority, and traffic to [cncf-landscape-a-to-z.com](https://cncf-landscape-a-to-z.com/)**.

---

## The Strategic Objective

We are not asking external writers to contribute—**we are the primary contributors**. 

By sharing production-grade code, real benchmarks, and hard-learned lessons from `infra-bootstrap-tools`, we position [cncf-landscape-a-to-z.com](https://cncf-landscape-a-to-z.com/) as the go-to, practitioner-backed authority on the cloud-native ecosystem. Each article serves as a technical magnet attracting platform engineers, DevOps practitioners, and SREs to the directory.

---

## Article Publishing Pipeline: Prioritized Batches

### Batch 1: Flagship Architectural Differentiators (High Impact)

These three stories address complex, uncommon production patterns already working in this repository.

#### 1. "Gitless GitOps" via Flux D2 and OCI Artifacts
* **Letter Alignment**: **F** (Flux CD) or **O** (OCI Artifacts)
* **CNCF Category**: Continuous Delivery
* **In-Repo Code**:
  * [`bin/ci/publish-flux-artifact.sh`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/bin/ci/publish-flux-artifact.sh)
  * [`kubernetes/fleet/k3s/flux-system/flux-instance.yaml`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/kubernetes/fleet/k3s/flux-system/flux-instance.yaml)
  * [`.github/workflows/flux-oci-publish.yml`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/.github/workflows/flux-oci-publish.yml)
  * [`docs/1-projects/kubernetes-flux-d2.md`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/docs/1-projects/kubernetes-flux-d2.md)
* **Article Title**:
  > *Why We Stopped Syncing Git Branches: Implementing Flux D2 "Gitless GitOps" with OCI Artifacts in a Monorepo*
* **The Technical Narrative**:
  Traditional GitOps binds clusters directly to Git branches, creating GitHub API rate-limit bottlenecks, token sprawl on cluster nodes, and messy monorepo sync triggers. We show how `infra-bootstrap-tools` implements the ControlPlane Flux D2 architecture: GitHub Actions packages `./kubernetes/fleet/<cluster>` and `./kubernetes/infra-addons` into signed OCI artifacts on GHCR (`flux push artifact`). Clusters reconcile against immutable OCI digests with zero Git tokens required on worker nodes.
* **Website Funnel**: Links to the Flux CD directory profile on `cncf-landscape-a-to-z.com/tools/flux/` and the "F" letter page.

---

#### 2. The "Dark K3s Stack": Zero Public Inbound Ports with Zero-Trust
* **Letter Alignment**: **K** (K3s / Kubernetes) or **Z** (Zero-Trust)
* **CNCF Category**: Orchestration & Security
* **In-Repo Code**:
  * [`docs/1-projects/dark-k3s-stack.md`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/docs/1-projects/dark-k3s-stack.md)
  * [`ansible/roles/k3s_server/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/ansible/roles/k3s_server)
  * [`ansible/roles/k3s_os_hardening/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/ansible/roles/k3s_os_hardening)
* **Article Title**:
  > *The "Dark K3s Stack": Running a Production Kubernetes Cluster with Zero Public Inbound Ports*
* **The Technical Narrative**:
  Exposing port 6443 to the internet invites constant port-scanning and automated exploit attempts. In this repository, we bind the K3s API server strictly to `127.0.0.1` (`--bind-address 127.0.0.1 --disable traefik`) and drop incoming 6443 traffic at the UFW firewall. Remote `kubectl` access is routed exclusively through an in-cluster OpenZiti zero-trust overlay. The article covers automated OS firewall hardening and Ansible bootstrapping with 1Password secret injection.
* **Website Funnel**: Links to K3s profile on `cncf-landscape-a-to-z.com/tools/k3s/` and highlights the security/networking landscape category.

---

#### 3. The GitOps Helm Trap: Values Layering Done Right
* **Letter Alignment**: **H** (Helm)
* **CNCF Category**: Application Definition
* **In-Repo Code**:
  * [`kubernetes/fleet/k3s/infra-addons/values/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/kubernetes/fleet/k3s/infra-addons/values)
  * [`kubernetes/infra-addons/base/helm-repos.yaml`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/kubernetes/infra-addons/base/helm-repos.yaml)
  * Architectural rule in [`docs/1-projects/kubernetes-flux-d2.md:L90-100`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/docs/1-projects/kubernetes-flux-d2.md#L90-L100)
* **Article Title**:
  > *The GitOps Trap: Why You Should Never Use `spec.values` in Flux HelmReleases (And What to Use Instead)*
* **The Technical Narrative**:
  In Flux Helm Controller, values declared in `spec.values` override anything supplied via `valuesFrom` ConfigMaps. Hardcoding values in base HelmReleases breaks multi-cluster customization. We explain our **two-tier ConfigMap values pattern**: base components supply defaults via `default-<addon>-values` ConfigMaps, while fleet clusters apply override ConfigMaps without touching the HelmRelease definition.
* **Website Funnel**: Links to the Helm profile on `cncf-landscape-a-to-z.com/tools/helm/`.

---

### Batch 2: DevOps, Developer Velocity & CI Governance

Practical operational tooling that solves common pipeline and testbed frustrations.

#### 4. KinD & containerd: Ephemeral GitOps CI in Under 3 Minutes
* **Letter Alignment**: **K** (KinD) or **C** (containerd)
* **CNCF Category**: Development Tooling & Runtime
* **In-Repo Code**:
  * [`bin/k8s/setup-kind-local-registry.sh`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/bin/k8s/setup-kind-local-registry.sh)
  * [`bin/kind/config/cluster-with-registry.yaml.tpl`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/bin/kind/config/cluster-with-registry.yaml.tpl)
  * [`bin/tests/flux-d2/test.sh`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/bin/tests/flux-d2/test.sh)
  * [`Makefile:L42-47`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/Makefile#L42-L47)
* **Article Title**:
  > *Testing Complex Flux GitOps Pipelines Locally in Under 3 Minutes with KinD and Local Registry Mirrors*
* **The Technical Narrative**:
  Waiting for cloud staging clusters to test GitOps reconciliation is slow and expensive. We show how `infra-bootstrap-tools` spins up a local KinD cluster connected to a local Docker registry on port 5001, patches `containerd` CRI registry mirrors inside the node, pushes OCI manifests, and validates controller readiness in 180 seconds via `make test-flux-d2`.
* **Website Funnel**: Links to the KinD and containerd directory pages on `cncf-landscape-a-to-z.com`.

---

#### 5. Open Policy Agent: Policy-as-Code to Ban Spaghetti Bash in CI
* **Letter Alignment**: **O** (Open Policy Agent) or **P** (Policy-as-Code)
* **CNCF Category**: Security & Compliance / Policy
* **In-Repo Code**:
  * [`policies/ci/inline_scripts.rego`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/policies/ci/inline_scripts.rego)
  * [`policies/ci/no_inline_scripts.rego`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/policies/ci/no_inline_scripts.rego)
* **Article Title**:
  > *Stop Writing Spaghetti Bash in CI: Enforcing Clean Pipelines with Open Policy Agent (OPA) and Rego*
* **The Technical Narrative**:
  GitHub Actions workflows regularly rot into unmaintainable, 60-line inline shell scripts in `run:` blocks. We explain how we use Open Policy Agent (`conftest`) to inspect workflow ASTs and automatically fail PRs if any step contains multiline inline bash, enforcing that scripts are extracted into testable, lintable executables in `bin/ci/`.
* **Website Funnel**: Links to OPA on `cncf-landscape-a-to-z.com/tools/open-policy-agent/`.

---

#### 6. Cosign (Sigstore): Keyless Container Signing in Monorepo CI
* **Letter Alignment**: **C** (Cosign) or **S** (Sigstore)
* **CNCF Category**: Supply Chain Security
* **In-Repo Code**:
  * [`bin/ci/sign-docker-image.sh`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/bin/ci/sign-docker-image.sh)
  * [`.github/workflows/release-docker.yml`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/.github/workflows/release-docker.yml)
* **Article Title**:
  > *Securing the Monorepo Supply Chain: Signing Container Image Digests with Cosign in GitHub Actions*
* **The Technical Narrative**:
  A practical guide to keyless container signing in CI. Rather than managing long-lived signing keys, we sign container digests with `cosign sign --yes {}@${DIGEST}` using GitHub OIDC tokens and output verification badges directly to GitHub Step Summaries.
* **Website Funnel**: Links to Cosign on `cncf-landscape-a-to-z.com/tools/cosign/`.

---

### Batch 3: Architecture & Extensibility Patterns

Advanced Kubernetes modularization and certificate infrastructure.

#### 7. cert-manager & trust-manager: Cluster-Wide Internal CA Trust Bundles
* **Letter Alignment**: **C** (cert-manager) or **T** (trust-manager)
* **CNCF Category**: Security & Identity
* **In-Repo Code**:
  * [`kubernetes/infra-addons/components/cert-manager/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/kubernetes/infra-addons/components/cert-manager)
  * [`kubernetes/fleet/k3s/infra-addons/values/cert-manager.values.yaml`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/kubernetes/fleet/k3s/infra-addons/values/cert-manager.values.yaml)
* **Article Title**:
  > *Beyond Ingress TLS: Managing Internal CA Trust Bundles with cert-manager and trust-manager*
* **The Technical Narrative**:
  Most articles only cover cert-manager for public Let's Encrypt ingress. In zero-trust internal topologies, you need internal private CAs and automatic distribution of CA bundles across all namespaces. We showcase how trust-manager synchronizes root certificates cluster-wide without custom cron jobs or manual secret replication.
* **Website Funnel**: Links to cert-manager on `cncf-landscape-a-to-z.com/tools/cert-manager/`.

---

#### 8. Kustomize Components: Composing Modular Cluster Addons
* **Letter Alignment**: **K** (Kustomize)
* **CNCF Category**: Application Definition
* **In-Repo Code**:
  * [`kubernetes/infra-addons/components/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/kubernetes/infra-addons/components)
  * [`kubernetes/infra-addons/kustomization.yaml`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/kubernetes/infra-addons/kustomization.yaml)
* **Article Title**:
  > *Stop Duplicating Overlays: Composing Modular Cluster Addons with Kustomize Components (`kind: Component`)*
* **The Technical Narrative**:
  Managing cluster variants across environments usually leads to duplicated overlay directories. We explore Kustomize's underutilized `kind: Component` feature, showing how cluster definitions can selectively opt into standalone infrastructure addons (like cert-manager or openziti) with single-line declarations.
* **Website Funnel**: Links to Kustomize on `cncf-landscape-a-to-z.com/tools/kustomize/`.

---

## Action Plan: Writing & Publishing Sequence

1. **Draft Article #1 (Flux D2 OCI GitOps)**:
   * Write draft in Medium using our [`in-repo-article-template.md`](in-repo-article-template.md).
   * Embed code links to `xNok/infra-bootstrap-tools` GitHub repository.
   * Add dedicated CTA banner pointing readers to `cncf-landscape-a-to-z.com/tools/flux/`.
2. **Publish on Medium & Crosslink**:
   * Publish under `medium.com/cncf-landscape-a-to-z`.
   * Update `cncf-landscape-a-to-z.com` tool entry for Flux with the new article link.
3. **Syndicate & Promote**:
   * Execute social distribution blueprint from [`visibility-flywheel.md`](visibility-flywheel.md).
   * Proceed to Draft #2 (The Dark K3s Stack).
