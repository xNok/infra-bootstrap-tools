---
"kubernetes-infra-addons": patch
---

Standardize OpenZiti ingress and package kubeztl:
- Standardize OpenZiti controller and router on DNS hostname (`ziti.nokwebspace.ovh`) via ExternalDNS and cert-manager, eliminating fleet-level Kustomize patches.
- Remove un-substituted k3s-ziti-*-values ConfigMap generators from root kustomization.
- Package kubeztl (zitified kubectl) derivation in Nix with OpenZiti SDK session caching patch and smart defaults.
