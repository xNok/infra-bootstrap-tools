# Kubernetes Flux D2 Architecture

Researching ControlPlane's Enterprise Flux D2 Architecture reference.

Key takeaways:
- **Gitless GitOps:** Uses OCI artifacts instead of direct git branches for environments.
- **Repositories structure:**
  - `d2-fleet`: Reconciles Flux Operator and FluxInstances, plus delivery of platform/apps components.
  - `d2-infra`: Infrastructure components (addons, network policies, security).
  - `d2-apps`: Applications deployed to the fleet.
- **Environments by tag:** Single `main` branch pushes OCI artifacts tagged for environments (e.g. `latest` for staging, `latest-stable` for production).
- **Dynamic/Static Inputs:** Used via ResourceSet to substitute values (like `tenant` or `environment`) during reconciliation.
- **Keyless signing:** OCI artifacts are signed via GitHub Actions id-token and cosign.

In our repo, we currently have:
- `kubernetes/clusters/k3s-openziti/infrastructure.yaml` (which references `OCIRepository` named `flux-system` but our current setup seems to be a mix of git and generic setup).
- Base infra is at `kubernetes/infra-base`.

We need to start adopting a similar structure. First step could be to test an OCI-based Flux bootstrap with a local Kind cluster.
