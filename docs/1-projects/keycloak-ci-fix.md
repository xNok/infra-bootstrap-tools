# Keycloak CI Integration Fix

## Goal
Debug and resolve the `helmrelease/keycloak` installation timeout and the `ziti-ext-jwt-config` job failure in the local integration testing environment.

## Status
- [x] Upgraded Keycloak HelmRelease chart version from `22.0.0` to `25.2.0` to pull a newer version.
- [x] Attempted using `bitnamilegacy` repository overrides to bypass Bitnami registry restrictions.
- [ ] Pivoting to the official Keycloak Operator to avoid Bitnami registry and Helm chart issues entirely.
- [x] Implemented a health check loop in `configure-ext-jwt.sh` to wait for Keycloak OIDC before running OpenZiti commands.
- [ ] Deploying the official Keycloak Operator, a standalone PostgreSQL instance, and importing the realm via `KeycloakRealmImport` CRD.
- [ ] Verifying local integration test suite via `make test-flux-d2`.
