# OpenZiti OIDC Identity Providers Integration

## Goal
Restore the working local Keycloak deployment and configuration, ensure Keycloak integration is working locally and in CI, and make sure Auth0 integration is ready for testing on a live cluster.

## Discoveries & Thoughts
1. **Reversion in CI**: We noticed that a previous commit `e39bee4` reverted the direct Keycloak deployment (Deployment and Service) back to a `HelmRelease` using a legacy Bitnami helm chart repository (`charts.bitnami.com`), which has been shut down and causes integration tests to fail.
2. **Local Deployment**: Commit `3499453` successfully switched Keycloak to a local Kubernetes Deployment and Service resource using `quay.io/keycloak/keycloak:25.0.6` and imported the `ziti` realm using `--import-realm` and a mounted ConfigMap generated from `ziti-realm.json`. Under this commit, the CI tests actually succeeded!
3. **Plan**:
   - Restore the local Keycloak Deployment and Service resources from commit `3499453`.
   - Update `bin/tests/flux-d2/test.sh` to wait for the local Keycloak Deployment (`deployment/keycloak` in `keycloak` namespace) instead of the defunct `helmrelease/keycloak`.
   - Add `ttlSecondsAfterFinished: 600` to the `ziti-ext-jwt-config` Job to allow Flux to clean it up and recreate/re-run it cleanly on subsequent reconciliations.
   - Configure the integration test script to fail if `ziti-ext-jwt-config` job fails, rather than ignoring errors.
   - Clean up untracked/unused keycloak operator files (`crds.yaml`, `operator.yaml`, `postgres.yaml`, `realm-import.yaml`).

## Next Steps
- Write implementation plan and get user approval.
- Execute changes.
- Verify locally using `./bin/tests/flux-d2/test.sh`.
