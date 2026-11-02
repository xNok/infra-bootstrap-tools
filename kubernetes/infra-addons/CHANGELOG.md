# kubernetes-infra-addons

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
