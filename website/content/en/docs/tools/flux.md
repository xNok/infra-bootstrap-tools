---
title: "FluxCD: Gitless GitOps via OCI Artifacts"
slug: flux
description: "How FluxCD is used in infra-bootstrap-tools for declarative GitOps, OCI artifact reconciliation, and automated Kubernetes fleet management."
tags:
  - gitops
  - kubernetes
  - fluxcd
  - oci
  - devops
---

## What is FluxCD?

[FluxCD](https://fluxcd.io/) is a set of continuous and progressive delivery solutions for Kubernetes that are open and extensible. In `infra-bootstrap-tools`, Flux acts as the GitOps engine that automatically synchronizes the state of our K3s and Kind clusters with declarative definitions stored in our repository.

---

## Why "Gitless" GitOps with OCI Artifacts?

Traditional GitOps workflows bind clusters directly to Git repositories. When managing multiple clusters or monorepos, this creates several challenges:
- **Credential Sprawl**: Every cluster requires a Git deploy key or personal access token with broad read permissions.
- **Excessive Re-Reconciliation**: A commit touching unrelated docs or playbooks triggers reconciliation attempts across all connected clusters.
- **Promotion Hurdles**: Promoting configuration between environments often involves complicated branch-merging workflows.

In this project, we implement **Enterprise Flux D2**, delivering configurations as **Open Container Initiative (OCI) artifacts** stored in GitHub Container Registry (`ghcr.io`):

![Flux D2 Enterprise GitOps Pipeline](/images/diagrams/flux-d2-gitops-pipeline.png)

1. Pushing to `main` triggers a GitHub Actions workflow that packages `kubernetes/fleet/<cluster>` and `kubernetes/infra-addons` as distinct OCI artifacts.
2. The cluster's `OCIRepository` source controller polls GHCR for new artifact digests.
3. The Kustomize and Helm controllers apply the manifests, ensuring the cluster continuously converges on the desired state.

---

## Key Flux Resources in This Project

### 1. `FluxInstance`
Managed by the ControlPlane Flux Operator, this custom resource defines the lifecycle and version of the Flux controllers running in the cluster.

### 2. `OCIRepository`
Replaces traditional `GitRepository` objects. Points to an OCI artifact URL (e.g. `oci://ghcr.io/xnok/infra-bootstrap-tools/manifests/fleet/k3s:latest`).

### 3. `Kustomization`
Defines a set of Kubernetes manifests to apply from an `OCIRepository` source. In our architecture, Kustomizations enforce a strict dependency chain:
- `flux-system` (Cluster bootstrap)
- `infra-addons-values` (Override ConfigMaps)
- `infra-addons` (Platform components)

### 4. `HelmRelease`
Declaratively configures Helm charts (such as `cert-manager` and `openziti`). All HelmReleases live in the `flux-system` namespace and consume values strictly via `valuesFrom` ConfigMaps.

---

## Common Flux CLI Commands

When connected to a cluster, you can inspect Flux state using the `flux` CLI:

```bash
# Check status of all Flux controllers and sources
flux get all -A

# View active OCI repository sources
flux get sources oci -A

# View Kustomization reconciliation status
flux get kustomizations -A

# View HelmRelease status and revision numbers
flux get helmreleases -A

# Force an immediate manual reconciliation
flux reconcile source oci flux-system -n flux-system
flux reconcile kustomization infra-addons -n flux-system
```

---

## Further Reading

- [Enterprise Flux D2 GitOps Guide]({{< relref "../kubernetes/k4.flux_d2_gitops.md" >}}): Deep dive into our dual OCI artifact architecture and values layering rules.
- [Local Cluster Testing with Kind]({{< relref "../kubernetes/k7.local_testing_kind.md" >}}): How to test Flux OCI delivery locally with `make test-flux-d2`.
