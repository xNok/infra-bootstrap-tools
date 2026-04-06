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

## 2026-04-06 Final Architecture — Implemented Design

### Two OCI artifacts

The monorepo publishes two separate OCI artifacts on every push:

| Artifact | Path | Content |
|---|---|---|
| `oci://.../manifests/kubernetes/fleet/<cluster>` | `kubernetes/fleet/<cluster>/` | Cluster-specific: `FluxInstance`, `OCIRepository` sources, `Kustomization` objects, per-cluster values |
| `oci://.../manifests/kubernetes/infra-addons` | `kubernetes/infra-addons/` | Shared: Kustomize Components for addons, base HelmRepositories, default values |

### Directory layout

```
kubernetes/
  fleet/
    kind/                        # one folder per cluster
      flux-system/
        flux-instance.yaml       # FluxInstance — bootstraps the cluster
      kustomization.yaml         # root kustomization: flux-system, oci-sources, values, infra-addons
      oci-sources.yaml           # OCIRepository/infra-addons (cluster-specific URL/tag)
      infra-addons-values.yaml   # Flux Kustomization managing cluster-specific override ConfigMaps
      infra-addons.yaml          # Flux Kustomization for shared addons
      infra-addons-values/       # per-cluster override ConfigMaps
        kustomization.yaml       # configMapGenerator for all override files
        cert-manager.values.yaml
        trust-manager.values.yaml
        ziti-controller.values.yaml
        ziti-router.values.yaml
  infra-addons/
    base/
      kustomization.yaml         # always-applied resources: HelmRepositories
      helm-repos.yaml            # shared HelmRepositories (jetstack, openziti)
    components/
      cert-manager/              # Kustomize Component (kind: Component)
        kustomization.yaml       # configMapGenerator for default-cert-manager-values
        default-cert-manager.values.yaml
        default-trust-manager.values.yaml
        cert-manager.yaml
        trust-manager.yaml
        namespace.yaml
      openziti/                  # Kustomize Component (kind: Component)
        kustomization.yaml       # configMapGenerator for default-ziti-*-values
        default-ziti-controller.values.yaml
        default-ziti-router.values.yaml
        controller.yaml
        ziti-host.yaml
        namespace.yaml
```

### Flux Kustomization dependency chain

```
flux-system (OCIRepository: fleet/kind)
  └─ infra-addons-values   (applies per-cluster ConfigMaps from ./infra-addons-values)
       └─ infra-addons      (applies shared addons from OCIRepository: infra-addons)
```

### Values layering strategy (most important design rule)

**Never use `spec.values` in HelmRelease.** It cannot be overridden by `valuesFrom` — values in `spec.values` always win.

Instead, use exclusively `valuesFrom` with two layers:

```yaml
valuesFrom:
  - kind: ConfigMap
    name: default-<addon>-values          # component default — always present, ships with infra-addons
  - kind: ConfigMap
    name: ${CLUSTER_NAME}-<addon>-values  # cluster override — optional, ships with fleet/<cluster>
    optional: true
```

- **Default ConfigMaps** (`default-<addon>-values`) live in each component and are generated by `configMapGenerator` in the component's `kustomization.yaml`. They define opinionated defaults that work for most clusters.
- **Cluster override ConfigMaps** (`${CLUSTER_NAME}-<addon>-values`) live in `fleet/<cluster>/infra-addons-values/` and are generated by `configMapGenerator` there. They are `optional: true` — missing means "use defaults".
- `${CLUSTER_NAME}` is resolved via `postBuild.substituteFrom: flux-runtime-info` on the `infra-addons` Kustomization.

### All HelmReleases in `flux-system` namespace

```yaml
metadata:
  namespace: flux-system   # Flux manages it here
spec:
  targetNamespace: <app>   # chart installs resources here
```

This ensures `valuesFrom` ConfigMaps are always co-located in `flux-system` regardless of which namespace the chart targets.

### Kustomize Components for opt-in addon selection

Each addon is `kind: Component` (not `kind: Kustomization`). The `infra-addons.yaml` Flux Kustomization selects which components to activate:

```yaml
spec:
  path: "./base"
  components:
    - ../components/cert-manager
    - ../components/openziti
```

To add a cluster without openziti, simply omit `../components/openziti` from that cluster's `infra-addons.yaml`.

### trust-manager: trust namespace = addon namespace

trust-manager reads Bundle sources from its `--trust-namespace`. The ziti-controller chart creates the `edge-signer-secret` in `openziti`, so trust-manager must be configured with `app.trust.namespace: openziti` for clusters running OpenZiti.

The component default (`default-trust-manager.values.yaml`) ships `app.trust.namespace: cert-manager` (safe baseline). Clusters running OpenZiti override this with `trust-manager.values.yaml` in their fleet values folder.

### Key lessons learned

1. **`spec.values` vs `valuesFrom` priority**: `spec.values` in a HelmRelease always wins over `valuesFrom`. Never put defaults in `spec.values` if you intend per-cluster overrides.
2. **trust-manager trust namespace**: trust-manager can only read Bundle secrets from one namespace (`--trust-namespace`). Plan which namespace holds your CA secrets and configure accordingly — it is not `cert-manager` by default for every use case.
3. **cert-manager CRDs**: use `installCRDs: true` (or `install.crds: CreateReplace`) in values — do not rely on a separate CRD install step in GitOps.
4. **Webhook timing**: trust-manager's validating webhook causes `connection refused` on install if the pod isn't fully ready. Remedy: `dependsOn: trust-manager` on any HelmRelease using `Bundle` resources, or accept one reconcile retry.
5. **OCI artifact per concern**: keeping fleet (cluster-specific) and infra-addons (shared) as separate OCI artifacts means the shared layer can be promoted independently without re-pushing all cluster configurations.

## 2026-04-06 Runtime Debugging — OpenZiti Enrollment & Flux ConfigMap Watch

### ConfigMap watch annotation required for immediate HelmRelease reconciliation

Without the annotation `reconcile.fluxcd.io/watch: Enabled` on `valuesFrom` ConfigMaps, a HelmRelease only reconciles on its `interval` timer — it does **not** react to ConfigMap changes immediately. This means updating a default values file will silently wait up to `interval` before taking effect.

**Fix**: add the annotation to every ConfigMap used as a `valuesFrom` source. Use `generatorOptions` at the kustomization level to apply it globally:

```yaml
# kustomization.yaml (Component or Kustomization)
generatorOptions:
  disableNameSuffixHash: true
  annotations:
    reconcile.fluxcd.io/watch: Enabled
configMapGenerator:
  - name: default-cert-manager-values
    namespace: flux-system
    files:
      - values.yaml=default-cert-manager.values.yaml
```

Apply this pattern in:
- `components/cert-manager/kustomization.yaml`
- `components/openziti/kustomization.yaml`
- `fleet/kind/infra-addons-values/kustomization.yaml`

Reference: https://github.com/fluxcd/flux2/issues/5446

### Flux `postBuild` substitution consumes shell variables in ConfigMap-mounted scripts

When a shell script is stored as a ConfigMap via `configMapGenerator` and the Kustomization has `postBuild.substituteFrom`, Flux **substitutes all `${VAR}` patterns** in every resource it applies — including ConfigMap data values. Shell variables like `${SA_TOKEN}`, `${APISERVER}`, etc. are replaced with empty strings if they are not defined in the substitution source.

**Fix**: escape shell variables with `$$` in the source file. Kustomize/Flux outputs `$$VAR` as `${VAR}` in the final ConfigMap, preserving shell semantics:

```sh
# In enroll-router.sh — use $$ for shell variables, not $
SA_TOKEN=$$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
JWT_B64=$$(echo -n "$${JWT}" | base64 -w 0)
```

### Python version in container images

The `openziti/ziti-controller` image ships `python3.11` but not `python3`. Scripts that call `python3` will fail with `not found`. Use the explicit binary:

```sh
python3.11 -c "import sys, json; ..."
```

### advertisedHost must match the actual Kubernetes service name

The `clientApi.advertisedHost` value in the ziti-controller chart becomes the `iss` (issuer) field embedded in enrollment JWTs. The router validates this URL when consuming a JWT. If the hostname in the JWT does not resolve in-cluster, enrollment fails with:

```
failed to parse JWT: could not contact remote server [https://<hostname>:<port>]
```

The chart generates the client service as `<release>-ziti-controller-client` (with ALPN, ctrl-plane shares this same service by default). Set:

```yaml
# default-ziti-controller.values.yaml
clientApi:
  advertisedHost: "openziti-ziti-controller-client.openziti.svc.cluster.local"
  advertisedPort: 1280
ctrlPlane:
  advertisedHost: "openziti-ziti-controller-client.openziti.svc.cluster.local"
  advertisedPort: 1280   # ctrl-plane shares client port via ALPN (ctrlPlane.service.enabled: false by default)
```

And the router:

```yaml
# default-ziti-router.values.yaml
ctrl:
  endpoint: "openziti-ziti-controller-client.openziti.svc.cluster.local:1280"
```

### Helm upgrade does not restart pods when only ConfigMap data changes

If the controller pod was already running before the ConfigMap was corrected, a `flux reconcile helmrelease` / Helm upgrade will not restart the pod because the Deployment spec hash hasn't changed. The controller config (mounted as a ConfigMap) will remain stale until the pod is restarted.

**Remedy**: `kubectl rollout restart deployment <name> -n <namespace>` after updating a values ConfigMap that affects config files mounted into the controller.

### ziti-controller ctrlPlane service is disabled by default

`ctrlPlane.service.enabled: false` is the chart default — the ctrl-plane listener shares the same port as `clientApi` via ALPN. There is no separate `openziti-ziti-controller-ctrl` service unless explicitly enabled. Do not reference a `*-ctrl` service hostname in router configs.

### Edge router enrollment idempotency

The enrollment Job must handle the case where:
1. The router was created in a previous run but the enrollment JWT was consumed (router shows `enrollmentJwt: null`).
2. Deleting and immediately recreating the router fails with `name must be unique` because the API is eventually consistent.

**Pattern**: delete the stale router, poll until `list edge-routers` returns empty, then create fresh.

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
