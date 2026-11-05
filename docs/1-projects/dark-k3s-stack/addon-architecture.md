---
type: project
status: active
description: Decoupling Kubernetes generic addon controllers from fleet configuration (AWS Addon Model)
related_projects:
  - dark-k3s-stack
related_resources:
  - openziti
related_areas:
  - networking
  - infra-orchestration
---

# Addon Architecture: Decoupling Controllers from Fleet Configuration

This document outlines the architectural standard for managing Kubernetes addons in this repository, establishing a strict separation between **generic addon controllers** and **cluster-specific configuration** (analogous to AWS EKS Addons).

---

## 1. The "AWS Addon" Mental Model

| Layer | Repository Path | Responsibility | GitOps Representation |
| :--- | :--- | :--- | :--- |
| **Addon Layer** (Controller) | `kubernetes/infra-addons/` | Reusable, generic, versioned components (`cert-manager`, `openziti`, `trust-manager`). Contains HelmRepositories, HelmReleases, RBAC, Services, and Lifecycle Jobs. | Packaged as an immutable OCI artifact (`oci://ghcr.io/xnok/manifests/kubernetes/infra-addons`). |
| **Fleet Layer** (Configuration) | `kubernetes/fleet/<cluster>/infra-addons/` | Cluster-specific configuration inputs (`values.yaml`), data files, and secrets references. | Reconciled via `Kustomization/infra-addons` pointing to the OCI source. |

### Golden Rules
1. **Zero Leaky Patches in Fleet**: The fleet `1-kustomize.yaml` manifest must **never** contain RFC 6902 JSON patches (`patches:`) against internal controller resources or certificates. Fleet configuration is supplied **strictly via values** (`values/*.values.yaml`).
2. **Encapsulation**: If an upstream Helm chart requires special rendering logic or manifest fixes, that logic belongs **inside the addon** (`kubernetes/infra-addons/`), not in the consuming fleet.
3. **Fleet Parity**: `fleet/k3s` and `fleet/kind` must follow identical structural patterns.

---

## 2. Root Cause Analysis: Why Patches Leaked into Fleet

In earlier revisions, 59 lines of inline RFC 6902 patches were introduced into `kubernetes/fleet/k3s/infra-addons/1-kustomize.yaml`. Two technical issues caused this leakage:

### Issue A: Upstream OpenZiti Chart Lacks `ipAddresses` Field
* **Symptom**: Go’s `crypto/tls` verifies IP addresses against `Certificate.spec.ipAddresses`. The upstream `openziti/ziti-controller` Helm chart only exposes `dnsNames` in its values schema.
* **Failure**: When dialing the controller via raw IP (`147.135.212.219:1280`), TLS verification panicked with `identity is not valid for provided host: [147.135.212.219]`.
* **The Leaky Workaround**: A Kustomize `postRenderer` was patched into `HelmRelease/ziti-controller` directly inside `fleet/k3s/infra-addons/1-kustomize.yaml` to inject `/spec/ipAddresses` into `openziti-ziti-controller-web-identity-cert`.

### Issue B: Dynamic IP Substitution Failed in ConfigMaps
* **Symptom**: Values files had `${ROUTER_ADVERTISED_HOST}`.
* **Failure**: `fleet/k3s/infra-addons/kustomization.yaml` generated ConfigMaps via `configMapGenerator`. But `fleet/k3s` was synced by the root `Kustomization/flux-system`, which lacked `postBuild.substituteFrom`. As a result, `${ROUTER_ADVERTISED_HOST}` remained an un-substituted literal string.
* **The Leaky Workaround**: To force substitution, the values were inlined directly into `HelmRelease` patches in `1-kustomize.yaml` where `infra-addons` postBuild was active.

---

## 3. The Resolution: Moving to DNS Hostnames

Instead of fighting raw IP SAN validation with Kustomize patches:
1. **Assign a Real DNS Hostname**:
   * Directed `ziti.nokwebspace.ovh` $\rightarrow$ `147.135.212.219`.
2. **Natively Satisfies Cert-Manager & Upstream Charts**:
   * Because `ziti.nokwebspace.ovh` is a DNS hostname, it populates `Certificate.spec.dnsNames` natively.
   * Go x509 validation passes without requiring any IP SANs.
   * **Result**: All `postRenderers` and all 59 lines of patches in `1-kustomize.yaml` are completely deleted.

---

## 4. Standard File Structure

### Fleet Configuration (`kubernetes/fleet/k3s/infra-addons/`)

```text
kubernetes/fleet/k3s/infra-addons/
├── 0-source.yaml              # Points to OCIRepository/infra-addons
├── 1-kustomize.yaml           # Instantiates Kustomization/infra-addons (0 patches!)
├── kustomization.yaml         # Generates ConfigMaps from values files
└── values/
    ├── cert-manager.values.yaml
    ├── trust-manager.values.yaml
    ├── ziti-controller.values.yaml
    └── ziti-router.values.yaml
```

#### Clean `1-kustomize.yaml`
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: infra-addons
  namespace: flux-system
spec:
  interval: 1h
  prune: true
  sourceRef:
    kind: OCIRepository
    name: infra-addons
  path: "./base"
  components:
    - ../components/cert-manager
    - ../components/openziti
  postBuild:
    substituteFrom:
      - kind: ConfigMap
        name: flux-runtime-info
```

#### Pure Values: `values/ziti-controller.values.yaml`
```yaml
clientApi:
  advertisedHost: "ziti.nokwebspace.ovh"
  advertisedPort: 1280
  service:
    type: LoadBalancer
```

#### Pure Values: `values/ziti-router.values.yaml`
```yaml
edge:
  advertisedHost: "ziti.nokwebspace.ovh"
  advertisedPort: 8442
  service:
    type: LoadBalancer
ctrl:
  endpoint: "openziti-ziti-controller-client.openziti.svc.cluster.local:1280"
enrollmentJwtFromSecret: true
enrollmentJwtSecretName: "ziti-router-enrollment"
```
