---
"kubernetes-infra-addons": patch
---

Fix K3s fleet postBuild substitutions and IP SAN persistence for OpenZiti:
- Migrate controller clientApi advertisedHost and router edge advertisedHost overrides into Kustomization/infra-addons patches with HelmRelease values and postRenderers.
- Remove un-substituted k3s-ziti-*-values ConfigMap generators from root kustomization.
- Add kubeztl (zitified kubectl) derivation with OpenZiti SDK session caching patch and smart defaults.
