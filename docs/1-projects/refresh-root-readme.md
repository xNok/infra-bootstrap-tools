---
type: project
status: active
description: Refresh root README.md to emphasize deliverables, modern monorepo layout, and a progressive DevOps learning plan
related_projects:
  - plan-kubernetes-content-layout
  - dark-k3s-stack
  - kubernetes-flux-d2
  - docker-swarm-env
related_areas:
  - infra-orchestration
  - developer-experience
pull_request: https://github.com/xNok/infra-bootstrap-tools/pull/267
---

# Project: Root README.md Refresh & Modernization

## 1. Problem Statement & Motivation
The root \`README.md\` was significantly outdated:
1. It primarily highlighted 2021-era Docker Swarm and Vagrant playbooks, with zero mention of the Dark K3s, OpenZiti Zero-Trust, or Flux D2 GitOps work merged in PR #266.
2. It gave prominent visibility to the deprecated \`ibt\` shell dispatcher (\`ibt setup\`, \`ibt stacks\`), which has been superseded by Nix Flakes.
3. Its architecture diagram links (\`./diagrams/startup_infra_for_small_self_hosted_project.png\`) were broken/stale.
4. The "Articles and Tutorials" section was an unstructured list with multiple abandoned \`[ ] WIP\` items.

## 2. Key Objectives & Four Pillars
1. **Deliverables Front & Center**:
   - Official documentation website: \`https://xnok.github.io/infra-bootstrap-tools/\`
   - Published Ansible Galaxy collection: \`xnok.infra_bootstrap_tools\`
   - Published OCI GitOps fleet & infra-addons on \`ghcr.io\`
   - Pre-built Docker Compose stacks in \`stacks/\`
2. **Refreshed Architecture Diagrams**:
   - Embed the newly authored Excalidraw architectural parity diagram: \`website/static/images/diagrams/architectural-parity-swarm-k3s.png\`.
   - Visualizing the Dual-Orchestration Model (Docker Swarm vs Dark K3s).
3. **Monorepo Blueprint & Contribution Guide**:
   - Explicit directory breakdown (\`ansible/\`, \`kubernetes/\`, \`terraform/\`, \`stacks/\`, \`website/\`, \`docs/\`).
   - Hermetic developer environments using Nix Flakes (\`nix develop .#ansible\`, \`nix develop .#flux\`, \`nix develop .#docs\`).
   - Zero-cloud-cost local testing harness with Kind and local OCI registry (\`make test-flux-d2\`).
   - Automated monorepo release workflow with Changesets (\`npx changeset add\`).
   - Docs-as-Code & PARA knowledge management in \`docs/\`.
4. **DevOps Learning Plan (Curriculum Style)**:
   - Level 1: Foundations (Terraform, DigitalOcean VMs, dynamic inventory, GitHub Actions CI).
   - Level 2: Docker Swarm Track (Vagrant sandbox, multi-node clustering, zero-downtime secret rotation, Caddy reverse proxy, Portainer UI).
   - Level 3: Zero-Trust Kubernetes & Enterprise GitOps (Host OS hardening, Dark K3s + OpenZiti mesh, monorepo Flux D2 with dual OCI artifacts, safe CI with PR locking).
