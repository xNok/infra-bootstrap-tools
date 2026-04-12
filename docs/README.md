# Staging PARA Workflow

This directory serves as the **Staging Area** for our "Docs as Code" workflow, organized using a hybrid PARA (Projects, Areas, Resources, Archives) method.

## Workflow Overview

We separate "Work in Progress" (Staging) from "Published Docs" (Website). This folder (`docs/_staging_para`) is where knowledge is captured and refined before publication.

### 1. The Capture Phase (Drafting)
During a Pull Request (PR) or active development:
- **Drop raw notes, logs, or diagrams** directly into the relevant folder.
    - `1-projects`: For active tasks (e.g., `agentic-workflow.md`).
    - `3-resources`: For tools and reference material (e.g., `caddy.md`, `portainer.md`).
- **Do not worry about formatting.** Speed and capture are the priorities here.
- Use `2-areas` for broader categories like `infra`, `dev`, or `sec` if a specific project or resource doesn't fit.

### 2. The Refine Phase (Publishing)
Periodically, or when a feature is complete:
- Review the content in Staging.
- **Migrate finished content** to the public documentation site at `website/docs`.
- Ensure the migrated content is properly formatted and integrated into the site's structure.

### 3. The Archive Phase (Cleanup)
Once content has been successfully migrated to the website:
- **Move the original raw notes** from `1-projects`, `2-areas`, or `3-resources` to `4-archives`.
- This keeps the active folders clean while preserving the history of our thought process and raw data.

## Folder Structure

- **1-projects/**: Active initiatives with a beginning and an end.
- **2-areas/**: Ongoing responsibilities (`infra`, `dev`, `sec`).
- **3-resources/**: Topics or themes of ongoing interest (`caddy`, `portainer`).
- **4-archives/**: Completed projects and migrated notes.

---

## PARA System Comprehensive Index

### Analysis Summary
- **[ANALYSIS_SUMMARY.md](./ANALYSIS_SUMMARY.md)** - Complete repository analysis (Jan 2025)

### 📁 Projects (1-projects/)

**Active Development:**
- [agentic-framework.md](./1-projects/agentic-framework.md) - Python AI workflows
- [n8n-workflows.md](./1-projects/n8n-workflows.md) - No-code AI automation
- [openziti-mesh.md](./1-projects/openziti-mesh.md) - Zero-trust networking
- [docker-swarm-env.md](./1-projects/docker-swarm-env.md) - Production orchestration
- [ibt-nix-refactor.md](./1-projects/ibt-nix-refactor.md) - CLI and environment tools
- [changeset-release-mgmt.md](./1-projects/changeset-release-mgmt.md) - Release automation

**Planning:**
- [k3s-migration.md](./1-projects/k3s-migration.md) - Kubernetes exploration

### 🎯 Areas (2-areas/)

- [ai-workflow-automation.md](./2-areas/ai-workflow-automation.md)
- [infra-orchestration.md](./2-areas/infra-orchestration.md)
- [developer-experience.md](./2-areas/developer-experience.md)
- [security-identity.md](./2-areas/security-identity.md)

### 📚 Resources (3-resources/)

- [caddy.md](./3-resources/caddy.md) - Reverse proxy
- [portainer.md](./3-resources/portainer.md) - Container management
- [nix.md](./3-resources/nix.md) - Reproducible environments

### Repository Statistics

- **Projects**: 7 documented (6 active, 1 planning)
- **Areas**: 4 major responsibility domains
- **Resources**: 3+ tools documented (expanding)
- **Total Documents**: 15+ comprehensive documents created

### Document Status Legend

- **active** - Currently under development
- **planning** - In design/research phase  
- **production** - Deployed and operational
- **investigating** - Early exploration
- **archived** - Completed or discontinued

---

**PARA System Established**: January 25, 2025
**Last Major Update**: January 25, 2025
**System Status**: Active and Growing
