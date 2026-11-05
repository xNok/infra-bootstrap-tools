# CNCF Landscape A-to-Z: 52-Week Editorial Calendar

This calendar charts the complete 52-week publishing roadmap for the [CNCF Landscape A-to-Z](https://medium.com/cncf-landscape-a-to-z) Medium publication. Each letter of the alphabet spans **two weeks**, balancing in-depth architectural coverage with hands-on labs, tool comparisons, and community spotlights.

---

## The Bi-Weekly Letter Cadence

Every letter follows a structured two-week rhythm:

| Cadence Day | Content Deliverable | Purpose |
| :--- | :--- | :--- |
| **Week 1 - Monday** | **The Letter Launchpad** | Editorial intro highlighting the letter's landscape overview, total projects, and themes. |
| **Week 1 - Thursday** | **Flagship Deep Dive** | Architectural exploration of a graduated/incubating anchor project. |
| **Week 2 - Tuesday** | **Hands-On Lab or Tool Showdown** | Step-by-step tutorial or direct head-to-head comparison (e.g., Tool A vs. Tool B). |
| **Week 2 - Thursday** | **Community / Sandbox Spotlight** | Featuring emerging sandbox projects and community writer submissions. |
| **Week 2 - Sunday** | **The Bi-Weekly Roundup & Digest** | Recap of all articles, stats, key takeaways, and preview of the upcoming letter. |

---

## 52-Week Master Schedule (Letters A to Z)

### Weeks 1–2: Letter "A"
* **Theme**: Continuous Delivery, Edge Runtimes & API Gateways
* **Landscape Categories**: App Definition & Development, Orchestration & Management
* **Marquee Projects**:
  * **Argo** (Graduated) - Argo Workflows, Argo CD, Argo Rollouts, Argo Events
  * **Artifact Hub** (Graduated) - Centralized cloud-native package discovery
  * **Antrea** (Graduated / Network) - Kubernetes networking via Open vSwitch
* **Sandbox & Ecosystem**: **Akri** (Edge device discovery), **APISIX** (Cloud-native API gateway)
* **Editorial Anchors**:
  * *Week 1*: Deep Dive: Understanding the Argo Ecosystem (CD vs. Rollouts vs. Workflows)
  * *Week 2*: Hands-on: Building Zero-Downtime Canary Deployments with Argo Rollouts

---

### Weeks 3–4: Letter "B"
* **Theme**: Developer Portals, Container Builds & Gateways
* **Landscape Categories**: Application Definition, Orchestration & Management
* **Marquee Projects**:
  * **Backstage** (Incubating) - Open platform for building developer portals
  * **Buildpacks** (Incubating) - Transform application source code into OCI container images
* **Sandbox & Ecosystem**: **BFE** (Layer 7 routing engine), **Brigade** (Event-driven scripting for Kubernetes)
* **Editorial Anchors**:
  * *Week 3*: Deep Dive: Why Internal Developer Platforms (IDPs) Standardize on Backstage
  * *Week 4*: Hands-on: Zero-Docker Image Builds with Cloud Native Buildpacks (pack CLI)

---

### Weeks 5–6: Letter "C"
* **Theme**: The Engine Room of Cloud Native (eBPF, Runtimes & Certs)
* **Landscape Categories**: Runtime, Networking, Security
* **Marquee Projects**:
  * **Cilium** (Graduated) - eBPF-powered networking, observability, and security
  * **containerd** (Graduated) - Industry-standard container runtime
  * **CoreDNS** (Graduated) - Fast and flexible DNS server for Kubernetes
  * **Cert-Manager** (Graduated) - Automated TLS certificate management
  * **CRI-O** (Graduated) - Lightweight container runtime for Kubernetes
* **Sandbox & Ecosystem**: **Crossplane** (Cloud control planes), **Chaos Mesh** (Chaos engineering platform)
* **Editorial Anchors**:
  * *Week 5*: Deep Dive: The eBPF Revolution: How Cilium Redefined K8s Networking & Security
  * *Week 6*: Comparison: containerd vs. CRI-O: Choosing the Right Production Runtime

---

### Weeks 7–8: Letter "D"
* **Theme**: Distributed Runtimes, P2P Image Distribution & Identity
* **Landscape Categories**: Application Frameworks, Provisioning, Security
* **Marquee Projects**:
  * **Dapr** (Incubating) - Distributed Application Runtime for microservice building blocks
  * **Dragonfly** (Incubating) - P2P file and container image distribution system
* **Sandbox & Ecosystem**: **Dex** (OpenID Connect identity provider), **Devfile** (Portable developer environments)
* **Editorial Anchors**:
  * *Week 7*: Deep Dive: Multi-Cloud Microservices Made Resilient with Dapr State & Pub/Sub
  * *Week 8*: Hands-on: Accelerating Gigantic Image Pulls across 500 Nodes with Dragonfly P2P

---

### Weeks 9–10: Letter "E"
* **Theme**: Service Proxies, Distributed State & Edge Infrastructure
* **Landscape Categories**: Service Mesh, Database/Coordination, Edge
* **Marquee Projects**:
  * **Envoy** (Graduated) - High-performance cloud-native edge/service proxy
  * **etcd** (Graduated) - Distributed reliable key-value store powering Kubernetes
* **Sandbox & Ecosystem**: **Emissary-Ingress** (Ambassador API gateway), **EdgeX Foundry** (Edge IoT framework), **EventMesh** (Dynamic event fabric)
* **Editorial Anchors**:
  * *Week 9*: Deep Dive: The Lifecycle of a Packet Through Envoy: Filters, Listeners & Clusters
  * *Week 10*: Production War Story: Surviving etcd Quorum Loss and Database Compaction Pitfalls

---

### Weeks 11–12: Letter "F"
* **Theme**: GitOps Pipelines, Telemetry Collectors & Runtime Security
* **Landscape Categories**: Continuous Delivery, Observability, Security
* **Marquee Projects**:
  * **Flux** (Graduated) - GitOps family of Kubernetes delivery controllers
  * **Falco** (Graduated) - Cloud-native runtime security and anomaly detection
  * **Fluentd** (Graduated) - Unified data collector and logging layer
* **Sandbox & Ecosystem**: **Fluent Bit** (Graduated / Lightweight telemetry agent), **Flagger** (Progressive delivery operator)
* **Editorial Anchors**:
  * *Week 11*: Tool Showdown: Flux vs. Argo CD: Architectural Philosophy and Production Realities
  * *Week 12*: Hands-on: Detecting Real-Time Container Escapes with Falco and eBPF Probes

---

### Weeks 13–14: Letter "G"
* **Theme**: RPC Frameworks, Policy Enforcement & Package Distribution
* **Landscape Categories**: Application Definition, Security & Compliance
* **Marquee Projects**:
  * **gRPC** (Graduated) - High-performance, language-agnostic RPC framework
  * **Gatekeeper** (Graduated via OPA) - Policy Controller for Kubernetes Admission
* **Sandbox & Ecosystem**: **Glasskube** (Next-gen package manager for K8s), **Gru** (Config validation)
* **Editorial Anchors**:
  * *Week 13*: Deep Dive: Designing Ultra-Low Latency Microservices with gRPC and Protocol Buffers
  * *Week 14*: Hands-on: Enforcing Organizational Guardrails with Gatekeeper Constraints

---

### Weeks 15–16: Letter "H"
* **Theme**: Package Management, Secure Registries & Cluster UIs
* **Landscape Categories**: App Definition, Provisioning, Orchestration
* **Marquee Projects**:
  * **Helm** (Graduated) - The Kubernetes package manager
  * **Harbor** (Graduated) - Enterprise-class cloud-native artifact registry
* **Sandbox & Ecosystem**: **Headlamp** (Extensible Kubernetes Web UI), **HwameiStor** (Local storage system)
* **Editorial Anchors**:
  * *Week 15*: Deep Dive: Advanced Helm 3: Library Charts, OCI Artifact Registries, and Hooks
  * *Week 16*: Hands-on: Setting Up Harbor with Automated CVE Vulnerability Scanning & Cosign Signing

---

### Weeks 17–18: Letter "I"
* **Theme**: Service Mesh, Software Supply Chain & Ingress
* **Landscape Categories**: Orchestration & Management, Security & Compliance
* **Marquee Projects**:
  * **Istio** (Graduated) - Service mesh for connect, secure, and monitor microservices
  * **in-toto** (Graduated) - Framework to secure software supply chain integrity
* **Sandbox & Ecosystem**: **Ingress-NGINX** (Ingress controller), **Inspektor Gadget** (eBPF debugging gadgets)
* **Editorial Anchors**:
  * *Week 17*: Deep Dive: Istio Ambient Mesh vs. Traditional Sidecars: Performance & Resource Footprint
  * *Week 18*: Hands-on: Securing CI/CD Pipelines Against Supply Chain Tampering with in-toto

---

### Weeks 19–20: Letter "J"
* **Theme**: Distributed Tracing & High-Performance Event Steaming
* **Landscape Categories**: Observability & Analysis, Messaging
* **Marquee Projects**:
  * **Jaeger** (Graduated) - End-to-end distributed tracing platform
* **Sandbox & Ecosystem**: **Jikkou** (Declarative CLI for Apache Kafka), **Jaime**
* **Editorial Anchors**:
  * *Week 19*: Deep Dive: Root-Cause Debugging Across 50 Microservices Using Jaeger Distributed Traces
  * *Week 20*: Hands-on: Instrumenting Go and Node.js Services with Jaeger and OpenTelemetry

---

### Weeks 21–22: Letter "K"
* **Theme**: The Core of the Cloud: Kubernetes & Its Native Ecosystem
* **Landscape Categories**: Orchestration & Scheduling, Scaling, Policy
* **Marquee Projects**:
  * **Kubernetes** (Graduated) - Automated container orchestration engine
  * **KEDA** (Graduated) - Kubernetes Event-driven Autoscaling
  * **Kyverno** (Incubating) - Cloud-native Kubernetes policy engine
  * **KubeVirt** (Incubating) - Virtual machine management inside Kubernetes
  * **Knative** (Incubating) - Serverless workloads on Kubernetes
* **Sandbox & Ecosystem**: **K3s** (Lightweight K8s), **Karmada** (Multi-cloud orchestration), **KubeEdge** (Edge computing), **KubeArmor** (LSM runtime security)
* **Editorial Anchors**:
  * *Week 21*: Deep Dive: KEDA Beyond CPU: Autoscaling Pods on Kafka Lag, RabbitMQ & Redis Queues
  * *Week 22*: Tool Showdown: Kyverno vs. Gatekeeper/OPA: Declarative YAML vs. Rego Logic

---

### Weeks 23–24: Letter "L"
* **Theme**: Ultra-Lightweight Meshes, Persistent Block Storage & Chaos Testing
* **Landscape Categories**: Service Mesh, Cloud Native Storage, Reliability
* **Marquee Projects**:
  * **Linkerd** (Graduated) - Ultralight, security-first service mesh for Kubernetes
* **Sandbox & Ecosystem**: **Longhorn** (Incubating / Distributed block storage), **LitmusChaos** (Incubating / Chaos engineering), **Lima** (Linux virtual machines on macOS)
* **Editorial Anchors**:
  * *Week 23*: Deep Dive: Zero-Config mTLS: Why Linkerd is the Favorite Mesh for Small Teams
  * *Week 24*: Hands-on: Building Resilient Stateful Storage in K8s with Longhorn Replicated Disks

---

### Weeks 25–26: Letter "M"
* **Theme**: Multi-Mesh Orchestration, Bare-Metal Provisioning & Mocking
* **Landscape Categories**: Cloud Native Management, Bare Metal, Developer Testing
* **Marquee Projects**:
  * **Meshery** (Incubating) - Cloud native management plane & service mesh orchestrator
* **Sandbox & Ecosystem**: **Metal3-io** (Bare-metal host management via Kubernetes API), **Microcks** (API mocking & contract testing for REST/gRPC/GraphQL)
* **Editorial Anchors**:
  * *Week 25*: Deep Dive: Designing API First Architecture with Microcks Contract Testing
  * *Week 26*: Hands-on: Provisioning Physical Hardware Declaratively Using Metal3 and Ironic

---

### Weeks 27–28: Letter "N"
* **Theme**: Cloud-Native Messaging, Signatures & Edge Networking
* **Landscape Categories**: Messaging, Security & Supply Chain, Container Tools
* **Marquee Projects**:
  * **NATS** (Incubating) - Connective fabric for distributed systems and IoT
  * **Notary / Notary v2** (Incubating) - Cryptographic signing for container images
* **Sandbox & Ecosystem**: **Network Service Mesh (NSM)** (Hybrid multi-cloud connectivity), **NeuVector** (Zero-trust container security), **nerdctl** (Docker-compatible CLI for containerd)
* **Editorial Anchors**:
  * *Week 27*: Deep Dive: NATS JetStream vs. Apache Kafka: Simplicity vs. Raw Partition Throughput
  * *Week 28*: Hands-on: Signing and Verifying Container Images with Notary v2 and Cosign

---

### Weeks 29–30: Letter "O"
* **Theme**: Telemetry Unification, Policy Enforcement & Cost Transparency
* **Landscape Categories**: Observability, Security & Policy, FinOps
* **Marquee Projects**:
  * **OpenTelemetry** (Graduated / Incubating core) - Universal metrics, logs, and trace collection
  * **Open Policy Agent (OPA)** (Graduated) - Unified policy enforcement across the cloud-native stack
* **Sandbox & Ecosystem**: **OpenCost** (Incubating / Real-time K8s cost monitoring), **OpenKruise** (Automated workload management), **OpenFeature** (Feature flagging standard), **OpenEBS** (Container attached storage)
* **Editorial Anchors**:
  * *Week 29*: Deep Dive: OpenTelemetry in 2026: Tracing, Metrics, and Logs Under One Collector
  * *Week 30*: Hands-on: Cutting Cloud Waste: Instrumenting Real-Time Cluster Costs with OpenCost

---

### Weeks 31–32: Letter "P"
* **Theme**: Metric Monitoring, eBPF Observability & Multi-Tenancy
* **Landscape Categories**: Observability, Multi-Cluster Management, Deployment
* **Marquee Projects**:
  * **Prometheus** (Graduated) - The foundation of cloud-native metrics and alerting
* **Sandbox & Ecosystem**: **Pixie** (Incubating / Instant eBPF-based K8s debugging), **Paralus** (Access management for K8s clusters), **PipeCD** (GitOps for K8s/Serverless/Terraform), **Porter** (Cloud-native application bundles)
* **Editorial Anchors**:
  * *Week 31*: Deep Dive: High-Performance PromQL and Prometheus TSDB Compaction at Scale
  * *Week 32*: Hands-on: 30-Second Cluster Troubleshooting with Pixie eBPF Auto-Telemetry

---

### Weeks 33–34: Letter "Q"
* **Special Thematic Pairing**: **Quality, Search & Cloud-Native AI (Q)**
* **Landscape Categories**: Search, Vector Databases, Testing & Observability
* **Projects & Solutions**:
  * **Quickwit** (Cloud-Native Search & Log Analytics)
  * **Qdrant** (Vector Database for Cloud-Native GenAI workloads)
  * **Quarkus Cloud-Native Integrations** (Supersonic subatomic containerized Java)
* **Editorial Strategy**: Highlight tools starting with Q while framing the bi-weekly theme around *Quality Engineering & AI Search in Kubernetes*.
* **Editorial Anchors**:
  * *Week 33*: Deep Dive: Cloud-Native Vector Search: Deploying Qdrant on Kubernetes for RAG
  * *Week 34*: Architecture: Cost-Effective Petabyte-Scale Log Search with Quickwit and S3 Storage

---

### Weeks 35–36: Letter "R"
* **Theme**: Cloud-Native Storage, Application Platforms & Network Observability
* **Landscape Categories**: Cloud Native Storage, Application Platforms, Networking
* **Marquee Projects**:
  * **Rook** (Graduated) - Cloud-native storage orchestrator for Ceph
* **Sandbox & Ecosystem**: **Radius** (Cloud-native application platform from Microsoft OSS), **Retina** (eBPF network observability platform), **Redfish / BMC Tools**
* **Editorial Anchors**:
  * *Week 35*: Deep Dive: Running Production Ceph on Kubernetes with Rook: Architecture & Performance
  * *Week 36*: Hands-on: Capturing Deep Packet Metrics Without Sidecars Using Retina eBPF

---

### Weeks 37–38: Letter "S"
* **Theme**: Workload Identity, Kafka on K8s & Cloud Storage
* **Landscape Categories**: Security & Identity, Streaming, Serverless
* **Marquee Projects**:
  * **SPIFFE / SPIRE** (Graduated) - Universal cryptographic workload identity standard
  * **Strimzi** (Incubating) - Running Apache Kafka on Kubernetes via Operators
* **Sandbox & Ecosystem**: **Submariner** (Cross-cluster networking), **Serverless Workflow** (Declarative DSL), **SchemaHero** (Declarative schema migrations)
* **Editorial Anchors**:
  * *Week 37*: Deep Dive: Zero-Trust Machine Identity: How SPIFFE/SPIRE Solves Secretless Auth
  * *Week 38*: Hands-on: Production Kafka on Kubernetes: High-Availability Setup with Strimzi

---

### Weeks 39–40: Letter "T"
* **Theme**: Distributed SQL, Metric Federation & Secure Updates
* **Landscape Categories**: Cloud Native Databases, Observability, Supply Chain
* **Marquee Projects**:
  * **TiKV** (Graduated) - Distributed transactional key-value database
  * **TUF (The Update Framework)** (Graduated) - Secure software update specification
  * **Thanos** (Incubating) - Highly available Prometheus with long-term storage
* **Sandbox & Ecosystem**: **Telepresence** (Fast local development against remote K8s), **Tremor** (Event processing system)
* **Editorial Anchors**:
  * *Week 39*: Deep Dive: Scaling Prometheus to Multi-Cloud Horizons with Thanos Query & Store
  * *Week 40*: Hands-on: Instant Local Debugging of Remote Kubernetes Pods with Telepresence

---

### Weeks 41–42: Letter "U"
* **Special Thematic Pairing**: **Universal Tooling, Utilities & Ubiquitous Computing (U)**
* **Landscape Categories**: Operating Systems, Developer Utilities, Workload Mobility
* **Projects & Solutions**:
  * **uSip / Universal Identity Connectors**
  * **Uranus / Universal Controller Runtimes**
  * **Ubiq Security / Universal Secret Utilities**
* **Editorial Strategy**: Spotlight universal cloud-native utilities, Linux kernel hooks, and foundational runtime tools.
* **Editorial Anchors**:
  * *Week 41*: Deep Dive: The Universal Cloud-Native Toolkit: 10 CLI Utilities Every SRE Needs
  * *Week 42*: Tutorial: Bridging Hybrid Workloads: Universal Networking and Security Patterns

---

### Weeks 43–44: Letter "V"
* **Theme**: Distributed RDBMS, Batch Scheduling & Cluster Disaster Recovery
* **Landscape Categories**: Database, Scheduling & Batch, Backup & Migration
* **Marquee Projects**:
  * **Vitess** (Graduated) - Horizontal scaling system for MySQL
* **Sandbox & Ecosystem**: **Volcano** (Incubating / Batch and HPC scheduling for AI/ML workloads), **Velero** (Community standard for K8s backup & DR), **Virtual Kubelet** (Pluggable node abstraction), **Vineyard** (Shared memory data manager)
* **Editorial Anchors**:
  * *Week 43*: Deep Dive: Scaling Relational Data to Millions of QPS: The Vitess Sharding Architecture
  * *Week 44*: Hands-on: Bulletproof Kubernetes Disaster Recovery: Cluster Backups & Restores with Velero

---

### Weeks 45–46: Letter "W"
* **Theme**: WebAssembly Runtimes & Next-Gen Cloud Workloads
* **Landscape Categories**: Serverless, Application Runtime, WebAssembly
* **Marquee Projects**:
  * **WasmEdge** (Incubating) - Lightweight, secure WebAssembly runtime
  * **wasmCloud** (Incubating) - Universal distributed WebAssembly application platform
* **Sandbox & Ecosystem**: **Woodpecker CI** (Lightweight CI engine), **Weaviate** (AI vector database), **Weight & Biases (wandb)** (ML experiment tracking)
* **Editorial Anchors**:
  * *Week 45*: Deep Dive: WebAssembly in Kubernetes: Is Wasm the Successor to Linux Containers?
  * *Week 46*: Hands-on: Building and Deploying Ultra-Fast Microservices with WasmEdge and Spin

---

### Weeks 47–48: Letter "X"
* **Special Thematic Pairing**: **eXtensibility, eBPF & Cross-Plane Tooling (X)**
* **Landscape Categories**: Cloud Control Planes, eBPF Data Paths, Protocol Extensions
* **Projects & Solutions**:
  * **Crossplane (X-Plane)** (Incubating) - Universal cloud control planes via Kubernetes CRDs
  * **XDP (eXpress Data Path)** - Kernel-level high-performance packet processing
  * **x-k8s Subprojects** (Cluster API, Kustomize, Gateway API extensions)
* **Editorial Strategy**: Group projects embodying cloud extensibility (Crossplane, XDP, X-k8s ecosystem extensions).
* **Editorial Anchors**:
  * *Week 47*: Deep Dive: Crossplane: Turning Kubernetes into a Universal Multi-Cloud API Engine
  * *Week 48*: Tutorial: Building Custom Cloud Resources with Compositions in Crossplane

---

### Weeks 49–50: Letter "Y"
* **Special Thematic Pairing**: **YuniKorn, YAML & Resource Optimization (Y)**
* **Landscape Categories**: Scheduling, Resource Optimization, AI/Big Data Orchestration
* **Projects & Solutions**:
  * **Apache YuniKorn** (Incubating) - Universal resource scheduler for mixed Big Data / ML workloads on K8s
  * **Yaegi** (Embedded Go interpreter used in cloud proxies like Traefik)
  * **Cloud-Native YAML Engineering**: Declarative configuration linters and validators (yamllint, kube-linter)
* **Editorial Anchors**:
  * *Week 49*: Deep Dive: Apache YuniKorn: Advanced Fair-Sharing & Gang Scheduling for AI/Spark on K8s
  * *Week 50*: Hands-on: Solving Cluster Resource Fragmentation with YuniKorn Workload Queues

---

### Weeks 51–52: Letter "Z"
* **Theme**: Zero-Trust Security, OCI Registries & Air-Gapped Deployments
* **Landscape Categories**: Container Registry, Zero-Trust Infrastructure, Air-Gapped Packaging
* **Marquee Projects**:
  * **Zot** (Sandbox) - Vendor-neutral, OCI-native container image registry
  * **Zarf** (Sandbox / Defense Unicorns) - Air-gapped software packaging and deployment
* **Sandbox & Ecosystem**: **Zed** (Data pipeline tools), **Zero-Trust Cloud Blueprints**
* **Editorial Anchors**:
  * *Week 51*: Deep Dive: Air-Gapped Kubernetes Deployments Made Simple with Zarf
  * *Week 52*: Grand Finale: The CNCF Landscape A-to-Z Year in Review: 52 Weeks, 26 Letters, What We Learned

---

## Conference & Event Alignments

To maximize organic viral spikes, the calendar aligns specific letter themes with major industry conferences:
* **KubeCon + CloudNativeCon Europe (Spring)**: Coordinate with active Spring letters (Letters E–H) for live maintainer interviews and booth coverage.
* **CloudNativeSecurityCon**: Feature Letters F (Falco), I (in-toto/Istio), and S (SPIFFE/SPIRE).
* **KubeCon + CloudNativeCon North America (Autumn)**: Align with Letters T, V, W, and X for on-site community contributor highlights.
