---
"ansible-role-k3s-flux-bootstrap": minor
"kubernetes-infra-addons": minor
---

feat(addons): introduce External Secrets Operator (1Password SDK) and ExternalDNS (DigitalOcean)

- kubernetes-infra-addons:
  - Add generic `components/external-secrets` addon tracking upstream `external-secrets` chart with pure operator definitions.
  - Add generic `components/external-dns` addon tracking upstream `kubernetes-sigs/external-dns` chart.
  - Configure `fleet/k3s` with `ClusterSecretStore/onepassword` (onepasswordSDK), `ExternalSecret/digitalocean-dns`, and pure values for DigitalOcean provider.
  - Maintain 0 Kustomize patches and 0 postRenderers across fleet and addon definitions.
  - Add OPA Conftest policy (`policies/kubernetes/allowed_addon_resources.rego`) and `policy-exceptions.yaml` to strictly enforce controller-only resources in infra-addons.
- ansible-role-k3s-flux-bootstrap:
  - Replace direct DigitalOcean REST API record creation with in-cluster secret management.
  - Ensure `external-secrets` namespace and inject `Secret/onepassword-service-account` from 1Password service account token.
  - Enrich `cluster-env` ConfigMap with `ONEPASSWORD_VAULT` for dynamic postBuild substitution.
