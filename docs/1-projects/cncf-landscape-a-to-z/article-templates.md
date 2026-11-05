# CNCF Landscape A-to-Z: Article Templates & Blueprints

These templates provide standardized, battle-tested outlines for articles published in the [CNCF Landscape A-to-Z](https://medium.com/cncf-landscape-a-to-z) publication. Writers can copy and adapt these templates to write engaging, practitioner-focused content.

---

## Template 1: The 10-Minute Deep Dive (Architecture & Internals)

**Target Length**: 1,200 – 2,000 words  
**Ideal For**: Graduated & Incubating projects, core architectural concepts, internal mechanics.

```markdown
# [Tool Name] Under the Hood: [Compelling Subtitle Explaining What You Will Reveal]

*A deep dive into how [Tool Name] solves [Core Problem] in cloud-native infrastructure, its internal architecture, and real-world operational trade-offs.*

![Cover Image: Tool Logo or Architecture Diagram](image-url)

## Introduction: Why [Tool Name] Exists
- Describe the historical problem or pain point before this tool existed.
- What specific cloud-native gap does [Tool Name] fill?
- Where does it sit in the CNCF Landscape (Category, Maturity Level: Graduated / Incubating / Sandbox)?

## The Core Architecture
- High-level architecture diagram (Mermaid / Excalidraw).
- Explanation of key components:
  - Control Plane / Management Layer
  - Data Plane / Node Agents
  - Storage / State Backends
  - Custom Resource Definitions (CRDs) or APIs

## How It Works: The Lifecycle of a [Request / Event / Packet]
- Step-by-step trace of how data flows through the system.
- What happens when a user runs `kubectl apply` or an event triggers?
- Code/Config snippet illustrating internal mechanics.

## Production Considerations & Trade-Offs
- Resource consumption (CPU/Memory overhead per node).
- Scalability limits and known bottlenecks.
- Where [Tool Name] excels vs. when you should look elsewhere.

## Summary & Next Steps
- Key takeaways in bullet points.
- Official documentation and repository links.
```

---

## Template 2: Hands-On Quickstart / 101 (Zero-to-Hero Lab)

**Target Length**: 800 – 1,500 words  
**Ideal For**: Practical tutorials, getting started guides, setting up a working proof-of-concept.

```markdown
# Getting Started with [Tool Name]: A Step-by-Step Practical Guide

*Learn how to install, configure, and verify [Tool Name] on your Kubernetes cluster in under 15 minutes.*

![Cover Image: Terminal / Cluster Diagram](image-url)

## What You'll Build
- Brief overview of the working scenario (e.g., "In this tutorial, we will deploy [Tool Name] on a local k3d/minikube cluster to accomplish X").

## Prerequisites
- A running Kubernetes cluster (v1.28+) or local cluster (Minikube, Kind, K3s).
- `kubectl` and Helm 3 installed.
- Any tool-specific CLI requirements.

## Step 1: Installing [Tool Name]
- Provide clean, verified installation commands (Helm chart, manifest, or CLI).
```bash
helm repo add [repo-name] [repo-url]
helm repo update
helm install [release-name] [chart-name] --namespace [ns] --create-namespace
```
- Verify deployment status:
```bash
kubectl get pods -n [namespace]
```

## Step 2: Configuring Your First [Resource / Policy / Pipeline]
- Provide an annotated YAML manifest.
- Walk through what each field does without overwhelming the reader.

## Step 3: Testing and Verification
- Run an action that triggers the tool.
- Show the expected output from `kubectl logs` or the tool CLI.

## Step 4: Common Pitfalls & Troubleshooting
- 2–3 common errors beginners encounter and how to resolve them.

## Teardown & Resources
- How to clean up resources:
```bash
helm uninstall [release-name] -n [namespace]
```
- Links to GitHub repo, Helm charts, and community Slack.
```

---

## Template 3: Tool Showdown / Comparison (Side-by-Side Matrix)

**Target Length**: 1,500 – 2,500 words  
**Ideal For**: Competing tools in the same category (e.g., Argo CD vs. Flux, Cilium vs. Calico, Kyverno vs. Gatekeeper).

```markdown
# [Tool A] vs. [Tool B]: Which Cloud-Native [Category] Tool Should You Choose?

*An objective, in-depth comparison of [Tool A] and [Tool B], analyzing architecture, developer experience, scalability, and operational overhead.*

![Cover Image: Side-by-side Logos](image-url)

## The Cloud-Native Dilemma
- Contextualize the category (e.g., GitOps, eBPF CNI, Policy Enforcement).
- Introduce both contenders:
  - **[Tool A]**: CNCF Status, creator, design philosophy.
  - **[Tool B]**: CNCF Status, creator, design philosophy.

## Comparison Matrix at a Glance
| Feature / Criteria | [Tool A] | [Tool B] | Winner / Notes |
| :--- | :--- | :--- | :--- |
| **CNCF Maturity** | Graduated | Incubating | - |
| **Architecture** | Centralized UI & Server | Decoupled Controllers | Depends on use case |
| **Resource Overhead** | Moderate | Very Low | [Tool B] |
| **Multi-Tenancy** | Built-in RBAC & Projects | Relies on K8s RBAC | [Tool A] |
| **Learning Curve** | Gentle (Web UI) | Steep (Pure Declarative) | [Tool A] |

## Deep Dive Comparison
### 1. Architectural Philosophy
- How each tool approaches state, reconciliation, and cluster dependencies.

### 2. Developer & Operator Experience
- Day 1 onboarding experience vs. Day 2 maintenance.
- CLI vs. Web UI capabilities.

### 3. Scalability & Performance at Scale
- How each tool behaves with 100+ clusters or 10,000+ objects.

### 4. Community, Ecosystem & Security
- Contributor activity, CVE response time, commercial backing.

## The Verdict: When to Choose Which
- **Choose [Tool A] if:** (Bullet points of ideal scenarios).
- **Choose [Tool B] if:** (Bullet points of ideal scenarios).

## Conclusion & Discussion
- Open-ended question inviting reader comments on what they use in production.
```

---

## Template 4: Production War Story / Post-Mortem

**Target Length**: 1,200 – 2,000 words  
**Ideal For**: SRE stories, outage retrospectives, solving scaling hurdles with CNCF tools.

```markdown
# How We Solved [Critical Infrastructure Outage/Bottleneck] Using [CNCF Tool]

*A real-world production post-mortem on handling [incident/issue] at scale and how [Tool Name] saved our infrastructure.*

![Cover Image: Observability Graph / Alert](image-url)

## The Setup: Our Architecture at Scale
- High-level scale metrics: Number of clusters, pods, QPS, data volume.
- Baseline infrastructure setup.

## The Incident: What Broke and Why
- Timestamped incident narrative or description of degradation.
- Why standard tools (basic metrics, logs) failed to pinpoint the issue.
- Impact on customer traffic and business operations.

## The Investigation: Pinpointing the Root Cause
- How the team diagnosed the underlying problem (e.g., socket buffer starvation, DNS throttling, etcd compaction locks).
- Graphs or log evidence illustrating the bottleneck.

## The Solution: Deploying [CNCF Tool]
- Why we selected [CNCF Tool] to address this problem.
- Implementation details: Configuration changes, custom operators, or tuning applied.
- Verification metrics showing recovery and performance delta.

## Lessons Learned & Best Practices
- What we changed in our Day 2 operational runbooks.
- Guardrails implemented to prevent recurrence.
- Recommendations for other platform engineers facing the same hurdle.
```

---

## Template 5: Bi-Weekly Letter Roundup & Editorial Digest

**Target Length**: 1,000 – 1,500 words  
**Ideal For**: Publication editors and curators summarizing the 2-week letter cycle.

```markdown
# CNCF Landscape A-to-Z: The Letter "[X]" Roundup

*A 2-week journey exploring [Number] projects under Letter "[X]"—from [Flagship Tool] to emerging sandbox innovators.*

![Cover Image: Letter Graphic](image-url)

## Letter "[X]" at a Glance
- Total tools covered in the CNCF registry for this letter.
- Primary landscape categories represented.
- The state of cloud-native innovation in this sector.

## Featured Tool Highlights
### 1. [Flagship Tool Name] (Graduated)
- Brief recap of the tool's significance.
- Link to our publication's Deep Dive.

### 2. [Tool Name] (Incubating)
- Why platform teams are adopting it.
- Key features and use cases.

### 3. [Tool Name] (Sandbox / Hidden Gem)
- The emerging newcomer solving a novel problem.

## Community Articles & Stories Published This Sprint
- Spotlight on articles submitted by community writers:
  - 📖 **"[Article Title 1]"** by @author - *1-sentence summary*.
  - 📖 **"[Article Title 2]"** by @author - *1-sentence summary*.

## Tool Directory Updates
- New tool cards added or updated on [cncf-landscape-a-to-z.com/letters/[x]/](https://cncf-landscape-a-to-z.com/).

## What's Next: Unlocking Letter "[Next Letter]"!
- Teaser for the upcoming letter, marquee tools to anticipate, and an invitation for community writers to submit drafts.
```
