# Add Kyverno as Cluster Addon

Project documentation for adding Kyverno and Kyverno Policies as cluster addons in `infra-bootstrap-tools`.

## Overview & Objectives

Kyverno provides Kubernetes-native policy management, validation, mutation, and generation.
This project integrates Kyverno as a standard shared cluster addon within the repository's Flux D2 GitOps architecture (`kubernetes/infra-addons`).

### Deliverables
1. **Component Package (`kubernetes/infra-addons/components/kyverno`)**:
   - `namespace.yaml`: Defines `kyverno` namespace.
   - `helm-repo.yaml`: Defines `kyverno` HelmRepository (`https://kyverno.github.io/kyverno/`).
   - `kyverno.yaml`: `HelmRelease` for core Kyverno chart (`kyverno/kyverno`, v3.9.2).
   - `default-kyverno.values.yaml`: Baseline component defaults (1 replica per controller, self-managed certificates).
   - `kyverno-policies.yaml`: `HelmRelease` for standard policies chart (`kyverno/kyverno-policies`, v3.9.2) with `dependsOn: kyverno`.
   - `default-kyverno-policies.values.yaml`: Baseline component defaults (`validationFailureAction: Audit` to ensure safe rollout without blocking existing workloads).
   - `kustomization.yaml`: Kustomize `kind: Component` exposing resources and generating default ConfigMaps with `reconcile.fluxcd.io/watch: Enabled`.

2. **Root Validation Entrypoint**:
   - Included `components/kyverno` in `kubernetes/infra-addons/kustomization.yaml` for local Kustomize build validation.

3. **Fleet Integration**:
   - Added `components/kyverno` to `kubernetes/fleet/kind/infra-addons/1-kustomize.yaml` and `kubernetes/fleet/k3s/infra-addons/1-kustomize.yaml`.
   - Added cluster-level override ConfigMap generators and values files (`values/kyverno.values.yaml`, `values/kyverno-policies.values.yaml`) for both `kind` and `k3s`.

4. **Automated Verification**:
   - Added `verify_kyverno_stack` to `bin/tests/flux-d2/test.sh` ensuring `helmrelease/kyverno`, `helmrelease/kyverno-policies`, and Kyverno controller pods reach ready status.

5. **Release Management**:
   - Created `.changeset/add-kyverno-cluster-addon.md` documenting a minor version update for `kubernetes-infra-addons`.

## Architecture Details & Design Decisions

### Values Layering Strategy
Per Flux D2 conventions, `spec.values` is omitted in favor of dual-layer `valuesFrom`:
```yaml
valuesFrom:
  - kind: ConfigMap
    name: default-kyverno-values          # Component baseline
  - kind: ConfigMap
    name: ${CLUSTER_NAME}-kyverno-values  # Optional cluster override
    optional: true
```
This allows each cluster (e.g., `kind`, `k3s`, or future clusters) to customize replicas, resource limits, or specific features without modifying the shared addon definition.

### Safe Policy Rollout Mode
`kyverno-policies` installs baseline Pod Security Standards. By setting:
```yaml
validationFailureAction: Audit
```
policies validate and report non-compliance in Kyverno policy reports without rejecting admission requests, preventing unexpected failures for development clusters or legacy workloads.

### Self-Contained HelmRepository
Following the repository convention:
> "Keep a repo inside the component's own helm-repo.yaml when only that component uses it."

The Kyverno repository is placed directly in `components/kyverno/helm-repo.yaml` so clusters that do not include the Kyverno component will not create unused HelmRepository resources.
