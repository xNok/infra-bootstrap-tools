---
"ansible-role-k3s-flux-bootstrap": minor
"kubernetes-infra-addons": minor
---

feat(addons): introduce External Secrets Operator (1Password SDK) and ExternalDNS (DigitalOcean)

- kubernetes-infra-addons:
  - Add generic `components/external-secrets` addon tracking upstream `external-secrets` chart with `ClusterSecretStore` powered by native `onepasswordSDK`.
  - Add generic `components/external-dns` addon tracking upstream `kubernetes-sigs/external-dns` chart with `ExternalSecret` integration for DigitalOcean DNS token.
  - Configure `fleet/k3s` with pure values for DigitalOcean provider and hostname annotation on `openziti-ziti-router` LoadBalancer service.
  - Maintain 0 Kustomize patches and 0 postRenderers across fleet and addon definitions.
- ansible-role-k3s-flux-bootstrap:
  - Replace direct DigitalOcean REST API record creation with in-cluster secret management.
  - Ensure `external-secrets` namespace and inject `Secret/onepassword-service-account` from 1Password service account token.
  - Enrich `cluster-env` ConfigMap with `ONEPASSWORD_VAULT` for dynamic postBuild substitution.
