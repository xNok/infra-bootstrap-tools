# Kubernetes Flux D2 Architecture

Researching ControlPlane's Enterprise Flux D2 Architecture reference.

Key takeaways:
- **Gitless GitOps:** Uses OCI artifacts instead of direct git branches for environments.
- **Repositories structure:**
  - `d2-fleet`: Utilized by the Platform team. Reconciles Flux Operator and a new FluxInstance with multi-tenancy restrictions on fleet clusters. It also configures the delivery of platform components (defined in `d2-infra`) and applications (defined in `d2-apps`).
  - `d2-infra`: Managed by the Platform team. Defines cluster add-ons (monitoring, logging, etc.), cluster-wide definitions (Namespace, IngressClass, StorageClass), Pod security standards, and network policies.
  - `d2-apps`: Used by Application teams. Hosts application components such as `HelmRepository`, `HelmRelease`, and per-environment Kustomize overlays. It does not contain cluster-wide definitions.

- **Environments by tag:** Single `main` branch pushes OCI artifacts tagged for environments (e.g. `latest` for staging, `latest-stable` for production).
- **Dynamic/Static Inputs:** Used via ResourceSet to substitute values (like `tenant` or `environment`) during reconciliation.
- **Keyless signing:** OCI artifacts are signed via GitHub Actions id-token and cosign.

## Concrete Implementation Decision

We don't want or use multiple repositories, thus we are adapting the D2 recommendation as a mono-repo.

- **Monorepo Mapping:**
  - `kubernetes/fleet`: Acts as `d2-fleet`. Reconciles our cluster delivery components. Each cluster has its own folder here (e.g., `kubernetes/fleet/k3s-openziti`), which contains the `FluxInstance` resource specifying its bootstrap source.
  - `kubernetes/infra`: Acts as `d2-infra`. Contains our base infrastructure addons (cert-manager, openziti, etc). These are usually referenced by the clusters inside `fleet/`.
  - `kubernetes/apps`: Acts as `d2-apps`. Will hold our applications deployed to the clusters.

- **Experimentation First:**
  As `infra-bootstrap-tools` is first and foremost about experiments, we assume that different clusters can represent different experiments, but some elements (like `infra`) can and should be shared.
  - By organizing our folders cleanly into `fleet`, `infra`, and `apps`, we can easily push the whole `kubernetes` directory as a single OCI artifact.
  - For example, a cluster named `k3s-openziti` will initialize itself by applying `kubernetes/fleet/k3s-openziti/flux-instance.yaml`. The Flux Operator then takes over, pulls the `kubernetes` artifact, and deploys the cluster-specific `infrastructure.yaml` which seamlessly references resources under `infra/`.

We have also established a GitHub Actions workflow (`.github/workflows/flux-d2-test.yml`) to test this pipeline automatically via a local Kind cluster and Docker registry. It uses the `flux-operator` Helm chart and bootstraps the cluster from the local `kubernetes/fleet/k3s-openziti/flux-instance.yaml` definition.
