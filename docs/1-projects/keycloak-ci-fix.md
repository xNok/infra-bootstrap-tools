# Keycloak CI Integration Fix

## Goal
Debug and resolve the `helmrelease/keycloak` installation timeout and the `ziti-ext-jwt-config` job failure in the local integration testing environment.

## Status
- [x] Confirmed the current CI failure comes from the Kind test path and the old Bitnami Keycloak HelmRelease approach.
- [x] Confirmed `k3s` already excludes the Keycloak component while `kind` still includes it.
- [ ] Replace the HelmRelease with a local Keycloak manifest tailored for Kind CI.
- [ ] Update the OpenZiti external JWT setup to prefer Auth0 in production and Keycloak in Kind.
- [ ] Re-run the Kind integration test after the manifest switch.

## Current approach
- Kind/CI should run a local Keycloak instance only for OpenZiti OIDC validation.
- K3s/production should not depend on the local Keycloak install path and should use Auth0 when `auth0-config` is provided.
