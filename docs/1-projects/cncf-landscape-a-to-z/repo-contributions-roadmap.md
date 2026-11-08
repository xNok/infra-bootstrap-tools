# Our CNCF Contributions & Article Publishing Roadmap

This roadmap defines the concrete articles we are writing and publishing to the **[CNCF Landscape A-to-Z Medium publication](https://medium.com/cncf-landscape-a-to-z)**. Every article is drawn directly from working architectures, automation scripts, and operational lessons in **`infra-bootstrap-tools`**, with the explicit objective of **driving visibility, authority, and traffic to [cncf-landscape-a-to-z.com](https://cncf-landscape-a-to-z.com/)**.

---

## Verified Tool Matrix: Proof of CNCF Landscape Listing

Every tool proposed below is **verified to be listed in the CNCF Landscape** and has an active, live profile page on **[cncf-landscape-a-to-z.com](https://cncf-landscape-a-to-z.com/)**:

| Tool | CNCF Landscape Status | In-Repo Implementation | Verified Live Proof Page on `cncf-landscape-a-to-z.com` |
| :--- | :--- | :--- | :--- |
| **Flux CD** | Graduated (Continuous Delivery) | [`kubernetes/fleet/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/kubernetes/fleet), [`bin/ci/publish-flux-artifact.sh`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/bin/ci/publish-flux-artifact.sh) | 🔗 [https://cncf-landscape-a-to-z.com/tools/flux/](https://cncf-landscape-a-to-z.com/tools/flux/) |
| **Helm** | Graduated (Application Definition) | [`kubernetes/infra-addons/base/helm-repos.yaml`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/kubernetes/infra-addons/base/helm-repos.yaml), [`fleet/k3s/infra-addons/values/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/kubernetes/fleet/k3s/infra-addons/values) | 🔗 [https://cncf-landscape-a-to-z.com/tools/helm/](https://cncf-landscape-a-to-z.com/tools/helm/) |
| **Open Policy Agent (OPA)** | Graduated (Security & Compliance) | [`policies/ci/inline_scripts.rego`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/policies/ci/inline_scripts.rego), [`policies/ci/no_inline_scripts.rego`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/policies/ci/no_inline_scripts.rego) | 🔗 [https://cncf-landscape-a-to-z.com/tools/open_policy_agent_opa/](https://cncf-landscape-a-to-z.com/tools/open_policy_agent_opa/) |
| **OPA Gatekeeper** | Graduated via OPA (Policy Enforcement) | [`policies/ci/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/policies/ci/) | 🔗 [https://cncf-landscape-a-to-z.com/tools/opa_gatekeeper/](https://cncf-landscape-a-to-z.com/tools/opa_gatekeeper/) |
| **Kubernetes** | Graduated (Scheduling & Orchestration) | [`kubernetes/fleet/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/kubernetes/fleet), [`bin/k8s/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/bin/k8s), [`ansible/roles/k3s_server/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/ansible/roles/k3s_server) | 🔗 [https://cncf-landscape-a-to-z.com/tools/kubernetes/](https://cncf-landscape-a-to-z.com/tools/kubernetes/) |
| **Keycloak** | CNCF Incubating (Security & Identity) | [`bin/tests/flux-d2/test.sh:L180-194`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/bin/tests/flux-d2/test.sh#L180-L194) (`verify_keycloak_stack`) | 🔗 [https://cncf-landscape-a-to-z.com/tools/keycloak/](https://cncf-landscape-a-to-z.com/tools/keycloak/) |
| **Docker Swarm** | Landscape Member (Orchestration) | [`ansible/roles/docker_swarm_*`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/ansible/roles/docker_swarm_controller), [`Makefile`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/Makefile#L27-L36) | 🔗 [https://cncf-landscape-a-to-z.com/tools/docker_swarm/](https://cncf-landscape-a-to-z.com/tools/docker_swarm/) |
| **Docker Compose** | Landscape Member (App Definition) | [`stacks/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/stacks) | 🔗 [https://cncf-landscape-a-to-z.com/tools/docker_compose/](https://cncf-landscape-a-to-z.com/tools/docker_compose/) |
| **Caddy** | Landscape Member (Service Proxy / Web) | [`test_caddy.sh`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/test_caddy.sh), [`ansible/roles/docker_swarm_app_caddy/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/ansible/roles/docker_swarm_app_caddy) | 🔗 [https://cncf-landscape-a-to-z.com/tools/caddy/](https://cncf-landscape-a-to-z.com/tools/caddy/) |
| **Portainer** | Landscape Member (Management UI) | [`ansible/roles/docker_swarm_app_portainer/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/ansible/roles/docker_swarm_app_portainer), [`docs/3-resources/portainer.md`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/docs/3-resources/portainer.md) | 🔗 [https://cncf-landscape-a-to-z.com/tools/portainer/](https://cncf-landscape-a-to-z.com/tools/portainer/) |
| **Ansible** | Landscape Member (Automation & Config) | [`ansible/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/ansible), [`Makefile`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/Makefile), [`requirements.yml`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/requirements.yml) | 🔗 [https://cncf-landscape-a-to-z.com/tools/ansible/](https://cncf-landscape-a-to-z.com/tools/ansible/) |
| **Terraform** | Landscape Member (Provisioning) | [`terraform/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/terraform) | 🔗 [https://cncf-landscape-a-to-z.com/tools/terraform/](https://cncf-landscape-a-to-z.com/tools/terraform/) |
| **Prefect** | Landscape Member (Workflow Orchestration) | [`stacks/prefect/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/stacks/prefect), [`agentic/workflows/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/agentic/workflows) | 🔗 [https://cncf-landscape-a-to-z.com/tools/prefect/](https://cncf-landscape-a-to-z.com/tools/prefect/) |
| **Pydantic AI** | Landscape Member (AI / ML Engineering) | [`agentic/jules/agent.py`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/agentic/jules/agent.py), [`agentic/requirements.txt`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/agentic/requirements.txt) | 🔗 [https://cncf-landscape-a-to-z.com/tools/pydantic_ai/](https://cncf-landscape-a-to-z.com/tools/pydantic_ai/) |

---

## The Strategic Objective

We are not asking external writers to contribute—**we are the primary contributors**. 

By sharing production-grade code, real benchmarks, and hard-learned lessons from `infra-bootstrap-tools`, we position [cncf-landscape-a-to-z.com](https://cncf-landscape-a-to-z.com/) as the go-to, practitioner-backed authority on the cloud-native ecosystem. Each article serves as a technical magnet attracting platform engineers, DevOps practitioners, and SREs to the directory.

---

## Article Publishing Pipeline: Prioritized Batches

### Batch 1: Flagship Architectural Differentiators (High Impact)

#### 1. "Gitless GitOps" via Flux D2 and OCI Artifacts
* **Target CNCF Tool**: **Flux CD** (Graduated)
* **Proof Page Link**: 🔗 [https://cncf-landscape-a-to-z.com/tools/flux/](https://cncf-landscape-a-to-z.com/tools/flux/)
* **In-Repo Code**:
  * [`bin/ci/publish-flux-artifact.sh`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/bin/ci/publish-flux-artifact.sh)
  * [`kubernetes/fleet/k3s/flux-system/flux-instance.yaml`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/kubernetes/fleet/k3s/flux-system/flux-instance.yaml)
  * [`.github/workflows/flux-oci-publish.yml`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/.github/workflows/flux-oci-publish.yml)
  * [`docs/1-projects/kubernetes-flux-d2.md`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/docs/1-projects/kubernetes-flux-d2.md)
* **Article Title**:
  > *Why We Stopped Syncing Git Branches: Implementing Flux D2 "Gitless GitOps" with OCI Artifacts in a Monorepo*
* **The Technical Narrative**:
  Traditional GitOps binds clusters directly to Git branches, creating GitHub API rate-limit bottlenecks, token sprawl on cluster nodes, and messy monorepo sync triggers. We show how `infra-bootstrap-tools` implements the ControlPlane Flux D2 architecture: GitHub Actions packages `./kubernetes/fleet/<cluster>` and `./kubernetes/infra-addons` into signed OCI artifacts on GHCR (`flux push artifact`). Clusters reconcile against immutable OCI digests with zero Git tokens required on worker nodes.
* **Website Funnel**: Featured on [cncf-landscape-a-to-z.com/tools/flux/](https://cncf-landscape-a-to-z.com/tools/flux/) and the "F" letter page.

---

#### 2. The GitOps Helm Trap: Values Layering Done Right
* **Target CNCF Tool**: **Helm** (Graduated)
* **Proof Page Link**: 🔗 [https://cncf-landscape-a-to-z.com/tools/helm/](https://cncf-landscape-a-to-z.com/tools/helm/)
* **In-Repo Code**:
  * [`kubernetes/fleet/k3s/infra-addons/values/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/kubernetes/fleet/k3s/infra-addons/values)
  * [`kubernetes/infra-addons/base/helm-repos.yaml`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/kubernetes/infra-addons/base/helm-repos.yaml)
  * Architectural rule in [`docs/1-projects/kubernetes-flux-d2.md:L90-100`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/docs/1-projects/kubernetes-flux-d2.md#L90-L100)
* **Article Title**:
  > *The GitOps Trap: Why You Should Never Use `spec.values` in Flux HelmReleases (And What to Use Instead)*
* **The Technical Narrative**:
  In Flux Helm Controller, values declared in `spec.values` override anything supplied via `valuesFrom` ConfigMaps. Hardcoding values in base HelmReleases breaks multi-cluster customization. We explain our **two-tier ConfigMap values pattern**: base components supply defaults via `default-<addon>-values` ConfigMaps, while fleet clusters apply override ConfigMaps without touching the HelmRelease definition.
* **Website Funnel**: Featured on [cncf-landscape-a-to-z.com/tools/helm/](https://cncf-landscape-a-to-z.com/tools/helm/) and the "H" letter page.

---

#### 3. Policy-as-Code for CI: Enforcing Workflow Hygiene with OPA
* **Target CNCF Tool**: **Open Policy Agent (OPA)** (Graduated)
* **Proof Page Link**: 🔗 [https://cncf-landscape-a-to-z.com/tools/open_policy_agent_opa/](https://cncf-landscape-a-to-z.com/tools/open_policy_agent_opa/)
* **In-Repo Code**:
  * [`policies/ci/inline_scripts.rego`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/policies/ci/inline_scripts.rego)
  * [`policies/ci/no_inline_scripts.rego`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/policies/ci/no_inline_scripts.rego)
* **Article Title**:
  > *Stop Writing Spaghetti Bash in CI: Enforcing Clean Pipelines with Open Policy Agent (OPA) and Rego*
* **The Technical Narrative**:
  GitHub Actions workflows regularly rot into unmaintainable, 60-line inline shell scripts in `run:` blocks. We explain how we use Open Policy Agent (`conftest`) to inspect workflow ASTs and automatically fail PRs if any step contains multiline inline bash, enforcing that scripts are extracted into testable, lintable executables in `bin/ci/`.
* **Website Funnel**: Featured on [cncf-landscape-a-to-z.com/tools/open_policy_agent_opa/](https://cncf-landscape-a-to-z.com/tools/open_policy_agent_opa/) and [cncf-landscape-a-to-z.com/tools/opa_gatekeeper/](https://cncf-landscape-a-to-z.com/tools/opa_gatekeeper/).

---

### Batch 2: Kubernetes Fleet & Identity Architecture

#### 4. The "Dark Kubernetes" Architecture: Zero Public Inbound Ports
* **Target CNCF Tool**: **Kubernetes** (Graduated)
* **Proof Page Link**: 🔗 [https://cncf-landscape-a-to-z.com/tools/kubernetes/](https://cncf-landscape-a-to-z.com/tools/kubernetes/)
* **In-Repo Code**:
  * [`docs/1-projects/dark-k3s-stack.md`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/docs/1-projects/dark-k3s-stack.md)
  * [`ansible/roles/k3s_server/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/ansible/roles/k3s_server)
  * [`ansible/roles/k3s_os_hardening/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/ansible/roles/k3s_os_hardening)
* **Article Title**:
  > *The "Dark Kubernetes" Stack: Running a Production Cluster with Zero Public Inbound Ports*
* **The Technical Narrative**:
  Exposing port 6443 to the internet invites constant port-scanning and automated exploit attempts. In this repository, we bind the cluster API server strictly to `127.0.0.1` and drop incoming 6443 traffic at the host firewall. Remote `kubectl` access is routed exclusively through an in-cluster zero-trust overlay. The article covers automated OS firewall hardening and Ansible bootstrapping with 1Password secret injection.
* **Website Funnel**: Featured on [cncf-landscape-a-to-z.com/tools/kubernetes/](https://cncf-landscape-a-to-z.com/tools/kubernetes/).

---

#### 5. Cloud-Native Identity at the Edge: Keycloak in GitOps
* **Target CNCF Tool**: **Keycloak** (Incubating)
* **Proof Page Link**: 🔗 [https://cncf-landscape-a-to-z.com/tools/keycloak/](https://cncf-landscape-a-to-z.com/tools/keycloak/)
* **In-Repo Code**:
  * [`bin/tests/flux-d2/test.sh:L180-194`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/bin/tests/flux-d2/test.sh#L180-L194) (`verify_keycloak_stack` and `ziti-ext-jwt-config`)
* **Article Title**:
  > *Automating Cloud-Native Identity: Deploying and Testing Keycloak OIDC in GitOps Pipelines*
* **The Technical Narrative**:
  Integrating centralized identity into edge and homelab Kubernetes clusters requires declarative configuration and automated validation. We show how Keycloak is deployed via GitOps, configure external JWT token validation, and automate readiness assertion in continuous integration.
* **Website Funnel**: Featured on [cncf-landscape-a-to-z.com/tools/keycloak/](https://cncf-landscape-a-to-z.com/tools/keycloak/).

---

### Batch 3: Lightweight Container Infrastructure & Orchestration

#### 6. Docker Swarm: The Pragmatic Alternative to Kubernetes for Edge & Homelabs
* **Target CNCF Tool**: **Docker Swarm** (Landscape Member)
* **Proof Page Link**: 🔗 [https://cncf-landscape-a-to-z.com/tools/docker_swarm/](https://cncf-landscape-a-to-z.com/tools/docker_swarm/)
* **In-Repo Code**:
  * [`ansible/roles/docker_swarm_controller/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/ansible/roles/docker_swarm_controller)
  * [`ansible/roles/docker_swarm_manager/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/ansible/roles/docker_swarm_manager)
  * [`Makefile:L27-36`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/Makefile#L27-L36) (`make swarm`, `make swarm-portainer-caddy`)
* **Article Title**:
  > *Why Docker Swarm is Still the Underrated Secret Weapon for Edge Infrastructure and Homelabs*
* **The Technical Narrative**:
  Kubernetes is often excessive overhead for single-node or lightweight clusters. We break down how `infra-bootstrap-tools` automates a production-grade Docker Swarm cluster with Caddy automatic SSL and Portainer management in under 5 minutes using modular Ansible playbooks.
* **Website Funnel**: Featured on [cncf-landscape-a-to-z.com/tools/docker_swarm/](https://cncf-landscape-a-to-z.com/tools/docker_swarm/) and [cncf-landscape-a-to-z.com/tools/docker_compose/](https://cncf-landscape-a-to-z.com/tools/docker_compose/).

---

#### 7. Caddy: Zero-Touch Automated SSL for Cloud-Native Edge Gateways
* **Target CNCF Tool**: **Caddy** (Landscape Member)
* **Proof Page Link**: 🔗 [https://cncf-landscape-a-to-z.com/tools/caddy/](https://cncf-landscape-a-to-z.com/tools/caddy/)
* **In-Repo Code**:
  * [`test_caddy.sh`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/test_caddy.sh)
  * [`test_xcaddy.sh`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/test_xcaddy.sh)
  * [`ansible/roles/docker_swarm_app_caddy/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/ansible/roles/docker_swarm_app_caddy)
* **Article Title**:
  > *Zero-Touch Automatic SSL: Running Caddy as a Modern Edge Reverse Proxy in Production*
* **The Technical Narrative**:
  Managing TLS certificates and renewals with traditional web servers requires complex cron scripts and certbot configurations. We demonstrate how Caddy automates ACME certificate issuance, custom plugin compilation with `xcaddy`, and zero-downtime reloads.
* **Website Funnel**: Featured on [cncf-landscape-a-to-z.com/tools/caddy/](https://cncf-landscape-a-to-z.com/tools/caddy/).

---

#### 8. AI Agent Workflows: Cloud-Native Orchestration with Prefect & Pydantic AI
* **Target CNCF Tools**: **Prefect** & **Pydantic AI** (Landscape Members)
* **Proof Page Links**:
  * 🔗 [https://cncf-landscape-a-to-z.com/tools/prefect/](https://cncf-landscape-a-to-z.com/tools/prefect/)
  * 🔗 [https://cncf-landscape-a-to-z.com/tools/pydantic_ai/](https://cncf-landscape-a-to-z.com/tools/pydantic_ai/)
* **In-Repo Code**:
  * [`stacks/prefect/`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/stacks/prefect)
  * [`agentic/workflows/jules_workflow.py`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/agentic/workflows/jules_workflow.py)
  * [`agentic/jules/agent.py`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/cncf_content_plan_medium/agentic/jules/agent.py)
* **Article Title**:
  > *Orchestrating Autonomous AI Agents in Cloud-Native Stacks with Prefect and Pydantic AI*
* **The Technical Narrative**:
  Moving AI agents from quick scripts into dependable production workflows requires retries, telemetry, and containerized orchestration. We walk through how `infra-bootstrap-tools-agentic` pairs Pydantic AI with Prefect workflows and Model Context Protocol (MCP) servers.
* **Website Funnel**: Featured on both [cncf-landscape-a-to-z.com/tools/prefect/](https://cncf-landscape-a-to-z.com/tools/prefect/) and [cncf-landscape-a-to-z.com/tools/pydantic_ai/](https://cncf-landscape-a-to-z.com/tools/pydantic_ai/).

---

## Action Plan: Writing & Publishing Sequence

1. **Draft Article #1 (Flux D2 OCI GitOps)**:
   * Write draft in Medium using our [`in-repo-article-template.md`](in-repo-article-template.md).
   * Embed code links to `xNok/infra-bootstrap-tools` GitHub repository.
   * Add dedicated CTA banner pointing readers to verified page: [https://cncf-landscape-a-to-z.com/tools/flux/](https://cncf-landscape-a-to-z.com/tools/flux/).
2. **Publish on Medium & Crosslink**:
   * Publish under `medium.com/cncf-landscape-a-to-z`.
   * Update `cncf-landscape-a-to-z.com` tool entry for Flux with the new article link.
3. **Syndicate & Promote**:
   * Execute social distribution blueprint from [`visibility-flywheel.md`](visibility-flywheel.md).
   * Proceed to Draft #2 (The GitOps Helm Trap).
