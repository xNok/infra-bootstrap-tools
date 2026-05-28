# OpenZiti External IdP Setup: Auth0 & Keycloak

## Overview
OpenZiti is actively evolving its SSO/OIDC integration (historically known as `External JWT Signers`). To support using external Identity Providers (IdPs) like Auth0 (for production in `k3s`) or Keycloak (for testing in `kind`), we must configure an external JWT signer and an authentication policy through the Ziti API or CLI.

This project introduces an automated Kubernetes Job `ziti-ext-jwt-configurer` that waits for the Ziti Controller to be reachable, logs in as an admin, and uses the `ziti edge create ext-jwt-signer` and `ziti edge create auth-policy` commands to set up the identity providers dynamically.

## Keycloak (Kind Cluster Testing)

Keycloak serves as an excellent local testing mechanism for OpenZiti's OIDC functionality.

### Configuration
We created a configuration script `configure-ext-jwt.sh` mounted into an execution Job. For Keycloak, the script executes:
```sh
ziti edge create ext-jwt-signer "keycloak" "https://keycloak.openziti.svc.cluster.local/realms/ziti" "https://keycloak.openziti.svc.cluster.local/realms/ziti/protocol/openid-connect/certs" --audience "account" --claims-property "email"

ziti edge create auth-policy "keycloak-auth" --primary-ext-jwt-allowed --primary-ext-jwt-allowed-signers "keycloak"
```

*   **Issuer**: `https://keycloak.openziti.svc.cluster.local/realms/ziti`
*   **JWKS Endpoint**: `https://keycloak.openziti.svc.cluster.local/realms/ziti/protocol/openid-connect/certs`
*   **Audience**: `account` (or a specific OpenZiti client ID configured in Keycloak).
*   **Claims**: `email` (default field to map identity).

### Verification
The CI tests and local kind environments deploy a Keycloak server that should have the `ziti` realm provisioned beforehand. The `ziti-ext-jwt-configurer` job then successfully links Keycloak into OpenZiti.

---

## Auth0 (Production K3s)

For live K3s environments, we replace the local Keycloak integration with Auth0.

### Configuration
Auth0 parameters are injected into the configuration job via a `ConfigMap` or `Secret` (`auth0-config`):
*   `AUTH0_ISSUER`: `https://YOUR_DOMAIN.us.auth0.com/` (Make sure the trailing slash is included if required by the OIDC discovery).
*   `AUTH0_JWKS_ENDPOINT`: `https://YOUR_DOMAIN.us.auth0.com/.well-known/jwks.json`
*   `AUTH0_AUDIENCE`: The API audience defined in Auth0.

The script executes the equivalent CLI commands using these variables:
```sh
ziti edge create ext-jwt-signer "auth0" "$AUTH0_ISSUER" "$AUTH0_JWKS_ENDPOINT" --audience "$AUTH0_AUDIENCE" --claims-property "email"

ziti edge create auth-policy "auth0-auth" --primary-ext-jwt-allowed --primary-ext-jwt-allowed-signers "auth0"
```

## Deployment Notes
1. **Kubernetes Resources**: A `ServiceAccount`, `Role`, `RoleBinding`, and `Job` are deployed in `kubernetes/infra-addons/components/openziti/ext-jwt-signer-job.yaml`.
2. **Kustomize Integration**: The job and script have been added to the local `kustomization.yaml` using a `configMapGenerator`.
3. **Execution**: The job is triggered once the `ziti-controller` deployment is stable. It is idempotent due to pre-existing resource checks.

## Future Upgrades
The OpenZiti controller natively accepts `edge-oidc` bindings on the client API. Future controller versions may expose explicit OIDC IdP configuration via native Helm Chart `additionalConfigs` YAML blocks (this is being tracked in OpenZiti's backlog for SAML/OIDC architectural enhancements). Until then, the CLI/API execution job serves as the primary implementation strategy.
