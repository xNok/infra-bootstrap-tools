# Shared Application & Agent Catalogue (`kubernetes/apps`)

This directory houses the reusable application catalogues and sovereign agent templates (e.g. `AgentTemplate`, `CronTask`, `RBAC`) that can be deployed across clusters in the fleet.

## Catalogue Distribution & GitOps Synchronization

- **Authoritative Blueprint**: `kubernetes/apps/agents/palette-agent` defines the reusable, cluster-agnostic blueprint for the Palette UX & Accessibility Agent.
- **In-Fleet Deployment Bridge**: Because GitHub Actions workflow publishing (`oci://ghcr.io/.../apps`) is staged pending GitHub token `workflow` scope approval in `.github/workflows/flux-oci-publish.yml`, clusters currently synchronize the catalogue through the in-tree fleet path:
  ```
  kubernetes/fleet/k3s/apps/palette-agent/catalogue/
  ```
- **Target Architecture**: Once the OCI publishing workflow is active, `kubernetes/apps` will be published as an independent OCI artifact and consumed natively via `OCIRepository` across all fleet clusters.
