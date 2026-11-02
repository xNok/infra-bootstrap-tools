---
"ansible-collection-infra-bootstrap-tools": minor
"ansible-role-k3s-flux-bootstrap": minor
"ansible-role-k3s-os-hardening": minor
"ansible-role-k3s-server": patch
"kubernetes-infra-addons": minor
---

feat(openziti): configure dynamic external ingress, zero-trust k3s access, and secure-by-default infra-addons architecture

- kubernetes-infra-addons:
  - Decouple workloads and cluster configuration without Kustomize overlays.
  - Set controller client API and router edge listeners to secure-by-default `ClusterIP`.
  - Fix Flux watch labels (`reconcile.fluxcd.io/watch=Enabled`) in `generatorOptions`.
  - Remove hardcoded credentials from Keycloak manifests, switching to `secretKeyRef`.
  - Clean mock test realm and dummy users from component manifests, moving test fixtures into Kind fleet.
  - Structure component assets into dedicated `scripts/`, `values/`, and `data/` directories.
- ansible-role-k3s-flux-bootstrap:
  - Add `cluster-env` ConfigMap generation with `ROUTER_ADVERTISED_HOST` for dynamic GitOps postBuild substitution.
- ansible-role-k3s-os-hardening:
  - Configure UFW rule for OpenZiti client API port (1280/tcp) while ensuring direct K3s API port (6443) remains unexposed.
- ansible-role-k3s-server:
  - Update default `k3s_server_openziti_bind_address` to `127.0.0.1` when dark mode is enabled.
