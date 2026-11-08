# Shared Application & Agent Catalogue (`kubernetes/apps`)

This directory houses the reusable application catalogues and sovereign agent templates (e.g. `AgentTemplate`, `CronTask`, `RBAC`) that can be deployed across clusters in the fleet.

## Catalogue Distribution & GitOps Synchronization

- **Platform Controllers**:
  - `kubernetes/apps/kubeopencode`: The shared, fleet-wide KubeOpenCode operator and API/UI server HelmRelease base.
- **Agent Catalogue**:
  - `kubernetes/apps/agents/palette-agent`: Reusable, cluster-agnostic blueprint for the Palette UX & Accessibility Agent (`AgentTemplate`, `CronTask`, scoped `RBAC`, `Namespace`).

## Fleet Opt-In

Clusters in `kubernetes/fleet/<cluster>/apps/` opt into these shared apps via Flux `Kustomization` CRs referencing the `apps` `OCIRepository` (`oci://ghcr.io/xnok/manifests/kubernetes/apps`).

