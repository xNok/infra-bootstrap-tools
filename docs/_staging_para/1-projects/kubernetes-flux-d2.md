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
  - `kubernetes/fleet`: Acts as `d2-fleet`. Reconciles our cluster delivery components. Each cluster has its own folder here (e.g., `kubernetes/fleet/kind`), which contains the `FluxInstance` resource specifying its bootstrap source.
  - `kubernetes/infra`: Acts as `d2-infra`. Contains our base infrastructure addons (cert-manager, openziti, etc). These are usually referenced by the clusters inside `fleet/`.
  - `kubernetes/apps`: Acts as `d2-apps`. Will hold our applications deployed to the clusters.

- **Experimentation First:**
  As `infra-bootstrap-tools` is first and foremost about experiments, we assume that different clusters can represent different experiments, but some elements (like `infra`) can and should be shared.
  - By organizing our folders cleanly into `fleet`, `infra`, and `apps`, we can easily push the whole `kubernetes` directory as a single OCI artifact.
  - For example, the local Kind test cluster initializes itself by applying `kubernetes/fleet/kind/flux-system/flux-instance.yaml`. The Flux Operator then takes over, pulls the `kubernetes` artifact, and deploys the cluster-specific `infrastructure.yaml` which seamlessly references resources under `infra/`.

We have also established a GitHub Actions workflow (`.github/workflows/flux-d2-test.yml`) to test this pipeline automatically via a local Kind cluster and Docker registry. It uses the `flux-operator` Helm chart and bootstraps the cluster from the local `kubernetes/fleet/kind/flux-system/flux-instance.yaml` definition.

## 2026-04-05 50-Cluster Fleet Architecture — Adoption Analysis

### Key principles from the external reference architecture

1. **OCI-Driven, Gitless GitOps**: CI packages addons as OCI artifacts; clusters poll OCI not Git.
2. **Kustomize Components for opt-in addon selection**: each addon has `kind: Component`; clusters opt-in via `components:` list.
3. **`valuesFrom` with optional ConfigMaps**: HelmReleases use `${CLUSTER_NAME}-<addon>-values` ConfigMaps (optional: true) so they are stateless; cluster-specific ConfigMaps live in `fleet/<cluster>/values/`.
4. **All HelmReleases in `flux-system`**: so `valuesFrom` ConfigMaps share a single namespace; charts install to their correct namespace via `targetNamespace`.
5. **`postBuild.substituteFrom`** on every Flux Kustomization so `${CLUSTER_NAME}` is resolved in all applied manifests, including `valuesFrom.name` in HelmRelease specs.

### Monorepo adaptation decisions

- Structure stays (`fleet/`, `infra/`, `apps/`) — no restructure to `addons/`, `tenants/`, `clusters/`.
- OCI push of the whole `kubernetes/` directory is kept (single artifact, not split addons/tenants).
- Kustomize Component conversion is **deferred**: the ResourceSet in `infrastructure.yaml` already provides per-cluster opt-in via `inputs:` — that's sufficient for now.
- **Implemented changes**:
  - All `HelmRelease` objects moved to `namespace: flux-system` with `targetNamespace` for chart installation.
  - `valuesFrom` with `${CLUSTER_NAME}-<addon>-values` optional ConfigMaps added to every HelmRelease.
  - `postBuild.substituteFrom: flux-runtime-info` added to `infra-sources` and `infra-cert-manager` Kustomizations.
  - `fleet/kind/values/` directory created with cluster-specific ConfigMaps for cert-manager, trust-manager, ziti-controller, and ziti-router.

## 2026-04-05 Kind Rename + Codespaces Enablement

Goal of this pass: finish the fleet test-cluster rename to `kind`, make the integration script default to the renamed fleet, and document a reliable GitHub Codespaces path for running the same test locally in a browser-hosted dev environment.

Observed gaps:
- The repo only contains `kubernetes/fleet/kind`, but the Flux D2 test still defaulted to `CLUSTER_NAME=flux-d2-test` and `FLEET_NAME=openziti`.
- The renamed fleet manifest still bootstrapped Flux from `./fleet/openziti`, which would break a default test run.
- The runtime info config map still labeled the cluster as `openziti`.
- The current branch has removed the `kubernetes/infra/update-policies` layer, but the test script and root `kubernetes/infra/kustomization.yaml` still referenced it.
- There was no checked-in Codespaces/devcontainer setup that matched the preferred Nix-shell workflow while still ensuring Docker access and the required CLIs (`kind`, `kubectl`, `helm`, `flux`) were present.

Completed:
- Updated the local Flux D2 test script and Kind helper to default to `kind`.
- Added fast-fail dependency checks and a clearer Docker/Codespaces error path to `bin/tests/flux-d2/test.sh`.
- Updated the Flux D2 CI workflow to create and target the `kind` cluster and fleet.
- Fixed the renamed fleet manifest to bootstrap from `./fleet/kind` and updated runtime metadata to `CLUSTER_NAME=kind`.
- Removed stale `update-policies` validation from the test and the root `kubernetes/infra/kustomization.yaml` entry so the current manifest tree builds again.
- Added the Flux D2 test CLIs to the shared Nix shell so local development and Codespaces use the same toolchain.
- Updated `.devcontainer/devcontainer.json` to install Nix and Docker support, then warm the flake shell instead of relying on `setup.sh`.

## 2026-03-23 Migration/Validation Pass

Goal of this pass: finish the in-progress rename/migration to `kubernetes/fleet/openziti`, ensure the fleet folder is fully reconcilable with Kustomize entrypoints, and validate that CI + local Kind tests verify the infra layer.

Observed gaps:
- Fleet move is in-progress (`kubernetes/fleet/k3s-openziti/*` deleted, `kubernetes/fleet/openziti/*` added), but references still point to `k3s-openziti` in some files.
- No `kustomization.yaml` entrypoints currently exist under `kubernetes/fleet/openziti` or `kubernetes/infra/*`, which prevents straightforward Kustomize validation and weakens reconciliation guarantees.
- The local Flux D2 test script at the time still bootstrapped from `kubernetes/fleet/k3s-openziti/flux-instance.yaml` and only waited for generated `flux-system` objects, not explicit infra Kustomizations.
- `.github/workflows/flux-oci-publish.yml` still references legacy structure (`kubernetes/infra-base`, `kubernetes/clusters/<name>`) and `k3s-openziti` matrix value.

Planned fixes:
- Normalize all references to `openziti` under `kubernetes/fleet/openziti`.
- Add `kustomization.yaml` files for fleet and infra directories to support build-time validation and explicit reconciliation roots.
- Extend Kind validation script to wait for infra Kustomizations and verify reconciliation status.
- Update CI workflow path triggers and environment variables to match the new structure.
- Update Ansible bootstrap defaults/docs to point at the new fleet path convention.

Status update:
- Completed: reference normalization for fleet path (`k3s-openziti` -> `openziti`) in Flux instance, test script, CI test workflow, artifact publish workflow, and Ansible bootstrap defaults/template/docs.
- Completed: added `kustomization.yaml` entrypoints under `kubernetes/fleet/openziti`, `kubernetes/fleet/openziti/flux-system`, and `kubernetes/infra` subdirectories (`sources`, `cert-manager`, `openziti`).
- Completed: added D2-style infra `update-policies` layer with Flux `ImageRepository` and `ImagePolicy` resources for OpenZiti images and wired it through fleet as `infra-update-policies`.
- Completed: validation script now waits on `infra-sources`, `infra-cert-manager`, and `infra-openziti` readiness.
- Completed: validation script now also waits on `infra-update-policies` readiness.
- Completed: refactored OpenZiti infra delivery in fleet to a D2-style `ResourceSet` (`infra-components`) that templates the generated `infra-openziti` `Kustomization` from inputs.
- Validated locally (static): `bash -n bin/tests/flux-d2/test.sh`, `kubectl kustomize kubernetes/fleet/openziti`, and `kubectl kustomize kubernetes/infra`.
- Blocked in this container (runtime): full Kind+Flux integration run requires local `kind` and `flux` CLIs, which are not installed in the current dev container.

## Minimal D2 Example Added (How To Read It)

Where to look:
- `kubernetes/fleet/openziti/infrastructure.yaml`

What it demonstrates:
- `infra-sources` and `infra-cert-manager` stay explicit, preserving ordered bootstrap.
- `infra-components` (`ResourceSet`) introduces D2-style templating.
- The `inputs` section defines the component (`tenant: openziti`) and its path (`./infra/openziti`).
- The generated resource is `Kustomization` `infra-openziti`, built from templates (`<< inputs.* >>`).
- `postBuild.substituteFrom` reads `flux-runtime-info`, matching D2 runtime-substitution patterns.

Why this is useful:
- It keeps the current monorepo flow stable while introducing the D2 mechanism used for scaling to multiple infra components.
- To add another component later, add another item to `inputs` and provide the matching infra path, instead of writing another full `Kustomization` block.

## Validation Checklist (Local + CI)

Primary script:
- `bin/tests/flux-d2/test.sh`

Local bootstrap helper (reproduces Kind+registry setup used by CI):
- `bin/setup-kind-local-registry.sh`

What this script validates end-to-end:
- Local `kubernetes` artifact push to `oci://localhost:5000/flux-system:latest`.
- `FluxInstance` bootstrap from `kubernetes/fleet/kind/flux-system/flux-instance.yaml`.
- Generated source and root sync become ready (`OCIRepository/flux-system`, `Kustomization/flux-system`).
- D2-style fleet `ResourceSet` exists and is ready (`resourceset/infra-components`).
- Infra reconciliation chain becomes ready (`infra-sources`, `infra-cert-manager`, `infra-openziti`).

Expected key resources after success:
- `resourceset/infra-components` in `flux-system`.
- `kustomization/infra-openziti` in `flux-system` (generated from `ResourceSet` inputs).

CI entrypoint:
- `.github/workflows/flux-d2-test.yml` runs `bin/tests/flux-d2/test.sh` for pull requests touching Kubernetes/Flux D2 files.

Manual local usage:
```bash
# 1) Setup local Kind cluster + local registry wiring
CLUSTER_NAME=kind REGISTRY_PORT=5000 ./bin/setup-kind-local-registry.sh

# 2) Run full D2 validation
CLUSTER_NAME=kind FLEET_NAME=kind REGISTRY_PORT=5000 ./bin/tests/flux-d2/test.sh

# 3) In GitHub Codespaces, enter the Flux-focused flake environment
nix develop .#flux
```
