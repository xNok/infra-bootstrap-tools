---
"kubernetes-infra-addons": minor
---

Add Kyverno and Kyverno Policies as cluster addons:
- Added `components/kyverno` providing Kyverno (v3.9.2) and Kyverno Policies (v3.9.2) HelmReleases.
- Configured default values and per-cluster overrides with Flux watch annotations.
- Integrated Kyverno addon into `kind` and `k3s` fleet configurations.
- Added verification for Kyverno and Kyverno Policies in `bin/tests/flux-d2/test.sh`.
