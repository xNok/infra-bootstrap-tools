---
type: project
status: active
description: Content contribution strategy, initial research completion, and editorial articles for cncf-landscape-a-to-z.com.
related_projects:
  - kubernetes-flux-d2
  - dark-k3s-stack
related_areas:
  - developer-experience
  - infra-orchestration
  - security-identity
---

# Project: CNCF Landscape A-to-Z (Content Planning & Research)

## Executive Summary

The **[CNCF Landscape](https://landscape.cncf.io/)** features over 1,000 projects. **[cncf-landscape-a-to-z.com](https://cncf-landscape-a-to-z.com/)** navigates this vast ecosystem one letter at a time across a 52-week calendar (2 weeks per letter).

This project captures:
1. **Unpublishing premature posts**: Setting `cruising-through-the-cs.md` to draft mode so content follows proper chronological order.
2. **Completing initial research for Letter A**: Ensuring all 71 tools in Letter A have full grounded research YAML files and generated tool pages.
3. **Drafting 2027 Letter A Editorial Articles**: Following the benchmark format established in Letter C (narrative overview + top standout selection + smart themed listicle), split into two weekly installments:
   - **Week 1 (Part 1)**: Cloud Platforms, Orchestration, Edge, Infrastructure & Security (36 tools)
   - **Week 2 (Part 2)**: GenAI & Agentic Systems, Streaming Big Data, Serverless & Frameworks (35 tools)

---

## Strategic Objectives

1. **Drive Visibility & Backlinks to `cncf-landscape-a-to-z.com`**:
   - Deliver high-value, non-hallucinated practitioner overviews.
   - Cross-link each listed project directly to its dedicated tool profile (`/tools/<slug>/`).
2. **Deterministic & Grounded Research**:
   - Maintain grounded factual research for all 71 tools in Letter A.
   - Keep tracker state synchronized across all tasks (`research`, `content`, `blog_post`).

---

## Letter A Structure (71 Projects)

### Week 1: Cloud Platforms, Orchestration, Edge & Security (36 projects)
- **Top Picks**: Argo, Atlantis, Antrea, Authelia
- **Categories**:
  - GitOps & Infrastructure Automation (Argo, Atlantis, Ansible, Agola, Architect)
  - Cloud & Edge Kubernetes Orchestration (Amazon EKS Anywhere, Amazon EKS-D, Application Platform for LKE, Azure Service Fabric, Apache Mesos, Armada, Airship)
  - Specialized Compute & Edge Frameworks (Agones, Akri, AppScale, Ambient)
  - Cloud-Native Networking & Service Mesh (Antrea, Aeraki Mesh)
  - API Gateways & Protocol Management (APISIX, APIOAK, APIClarity, Apache bRPC, Azure API Management)
  - Zero-Trust Security, Identity & Policy (Authelia, Authing, Aserto, Athenz)
  - Package Registries & Hubs (Artifact Hub, Apicurio Registry)

### Week 2: AI Agents, Streaming Big Data & Serverless (35 projects)
- **Top Picks**: AIBrix, AutoGen / Agno, AutoMQ, Apache Flink / Spark
- **Categories**:
  - GenAI, LLM Infrastructure & Agentic Systems (AIBrix, Agno, AutoGen, Agent Development Kit, Agent Evaluation, Agent Substrate, Agent2agent, Agentgateway, Astron Agent, Axolotl)
  - Streaming, Message Queuing & Event Routers (AutoMQ, Apache RocketMQ, Apache NiFi, Apache StreamPipes, Apache Storm, Avro)
  - Distributed Big Data & Analytics Engines (Apache Flink, Apache Spark, Apache Pinot, Apache Druid, Apache TVM, Apache Zeppelin)
  - Databases & Distributed Storage (Alluxio, ArangoDB, Apache AGE, Apache HBase, Apache Hadoop, Apache Ignite, Apache CarbonData)
  - Serverless & Cloud Function Frameworks (AWS SAM, Azure Functions, Apache OpenWhisk, Apache OpenServerless, ArkFlow, Arks)
  - Distributed Application Runtimes & Tooling (Akka, Apache Thrift, Apache Zookeeper, Apollo, Asyncify)
