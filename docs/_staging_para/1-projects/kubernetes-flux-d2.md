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

## Concrete Implementation Decision

We don't want or use multiple repositories, thus we are adapting the D2 recommendation as a mono-repo.

- **Monorepo Mapping:**
  - `kubernetes/fleet`: Acts as `d2-fleet`. Reconciles our cluster delivery components.
  - `kubernetes/infra`: Acts as `d2-infra`. Contains our base infrastructure addons (cert-manager, openziti, etc).
  - `kubernetes/apps`: Acts as `d2-apps`. Will hold our applications deployed to the clusters.

- **Experimentation First:**
  As `infra-bootstrap-tools` is first and foremost about experiments, we assume that different clusters can represent different experiments, but some elements (like `infra`) can and should be shared.
  - By organizing our folders cleanly into `fleet`, `infra`, and `apps`, we can easily push specific folders as OCI artifacts.
  - For example, `infra` can be packaged as `oci://ghcr.io/.../infra` and consumed by multiple experiment clusters defined in `fleet`.

We have also established a GitHub Actions workflow (`.github/workflows/flux-d2-test.yml`) to test this pipeline automatically via a local Kind cluster and Docker registry.
