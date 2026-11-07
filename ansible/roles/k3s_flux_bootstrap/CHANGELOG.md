# k3s_flux_bootstrap

## 0.4.1

### Patch Changes

- e8002f1: Fix ESO 1Password SDK memory limits, pin ExternalDNS to v0.20.0 for EndpointSlices and in-tree DigitalOcean provider, and update secret naming convention to `{consumer}_{resource server}_{what}`.

## 0.4.0

### Minor Changes

- a9c417c: feat(addons): introduce External Secrets Operator (1Password SDK) and ExternalDNS (DigitalOcean)

  - kubernetes-infra-addons:
    - Add generic `components/external-secrets` addon tracking upstream `external-secrets` chart with pure operator definitions.
    - Add generic `components/external-dns` addon tracking upstream `kubernetes-sigs/external-dns` chart.
    - Configure `fleet/k3s` with `ClusterSecretStore/onepassword` (onepasswordSDK), `ExternalSecret/digitalocean-dns`, and pure values for DigitalOcean provider.
    - Maintain 0 Kustomize patches and 0 postRenderers across fleet and addon definitions.
    - Add OPA Conftest policy (`policies/kubernetes/allowed_addon_resources.rego`) and `policy-exceptions.yaml` to strictly enforce controller-only resources in infra-addons.
    - Sized baseline resource requests and limits for small clusters/CI across all generic addon defaults, and brought `fleet/kind` and the Kind integration test suite to full parity.
    - Expand Kind integration test suite with functional ESO secret synchronization and ExternalDNS service discovery verification, and add BATS test coverage for the Nix kubeztl derivation.
  - ansible-role-k3s-flux-bootstrap:
    - Replace direct DigitalOcean REST API record creation with in-cluster secret management.
    - Ensure `external-secrets` namespace and inject `Secret/onepassword-service-account` from 1Password service account token.
    - Enrich `cluster-env` ConfigMap with `ONEPASSWORD_VAULT` for dynamic postBuild substitution.

## 0.3.0

### Minor Changes

- 3be8bf2: feat(openziti): configure dynamic external ingress, zero-trust k3s access, and secure-by-default infra-addons architecture

  - kubernetes-infra-addons:
    - Decouple workloads and cluster configuration without Kustomize overlays.
    - Set controller client API and router edge listeners to secure-by-default `ClusterIP`.
    - Fix Flux watch labels (`reconcile.fluxcd.io/watch=Enabled`) in `generatorOptions`.
    - Remove hardcoded credentials from Keycloak manifests, switching to `secretKeyRef`.
    - Clean mock test realm and dummy users from component manifests, moving test fixtures into Kind fleet.
    - Structure component assets into dedicated `scripts/`, `values/`, and `data/` directories.
    - Mount Keycloak realm import directory directly instead of subPath for resilient optional imports.
  - ansible-role-k3s-flux-bootstrap:
    - Add `cluster-env` ConfigMap generation with `ROUTER_ADVERTISED_HOST` for dynamic GitOps postBuild substitution.
  - ansible-role-k3s-os-hardening:
    - Configure UFW rule for OpenZiti client API port (1280/tcp) while ensuring direct K3s API port (6443) remains unexposed.
  - ansible-role-k3s-server:
    - Document and maintain `k3s_server_openziti_bind_address` default at `0.0.0.0` for multi-node agent joins, supporting `127.0.0.1` override for single-node loopback.

## 0.2.0

### Minor Changes

- af6e8d6: Improve K3s / Flux Bootstrap support: add Flux CLI installation task, update OCI sync URL to the new fleet path format (`oci://…/kubernetes/fleet/<cluster>`), change `k3s_flux_bootstrap_cluster_name` default to `k3s`, and update `k3s_server_kubeconfig_mode` default to `644`. Add initial Kubernetes infra-addons fleet configuration with cert-manager, trust-manager, OpenZiti controller and router.

## 1.0.1

### Patch Changes

- c6087dd: Updated OpenZiti and K3s "Dark" Setup:
  - **k3s_server**: Migrated from command-line arguments to `/etc/rancher/k3s/config.yaml` for configuration. Added support for binding API only to local interfaces (dark mode).
  - **k3s_flux_bootstrap**: Fixed `FluxInstance` spec to use `kind: OCIRepository` and added `path: "."` for OCI-based bootstrap.
  - **k3s_os_hardening**: Added UFW rules to restrict K3s API access to a specific CIDR and ensure secure defaults.
  - **ansible-collection**: General updates to coordinate the new roles and configuration.
