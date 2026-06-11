#!/bin/sh
set -eu

# Wait for controller API to be reachable
echo "Waiting for OpenZiti controller API to be reachable..."
until curl -sk https://openziti-ziti-controller-client.openziti.svc.cluster.local:1280/edge/client/v1/version > /dev/null 2>&1; do
    echo "Controller not ready. Retrying in 5 seconds..."
    sleep 5
done
echo "Controller is ready."

echo "Logging into Ziti Controller..."
ziti edge login openziti-ziti-controller-client.openziti.svc.cluster.local:1280 -u admin -p "$ZITI_PWD" -y

KEYCLOAK_ISSUER="${KEYCLOAK_ISSUER:-http://keycloak.keycloak.svc.cluster.local/realms/ziti}"
KEYCLOAK_JWKS_ENDPOINT="${KEYCLOAK_JWKS_ENDPOINT:-http://keycloak.keycloak.svc.cluster.local/realms/ziti/protocol/openid-connect/certs}"
KEYCLOAK_DISCOVERY_URL="${KEYCLOAK_DISCOVERY_URL:-${KEYCLOAK_ISSUER}/.well-known/openid-configuration}"
AUTH0_ISSUER="${AUTH0_ISSUER:-}"
AUTH0_JWKS_ENDPOINT="${AUTH0_JWKS_ENDPOINT:-}"
AUTH0_AUDIENCE="${AUTH0_AUDIENCE:-}"

# Configure Auth0 (used for production in K3s)
if [ -n "$AUTH0_ISSUER" ] && [ -n "$AUTH0_JWKS_ENDPOINT" ] && [ -n "$AUTH0_AUDIENCE" ]; then
    if ! ziti edge list ext-jwt-signers 'name="auth0"' | grep -q "auth0"; then
        echo "Creating Auth0 Ext JWT Signer..."
        ziti edge create ext-jwt-signer "auth0" "$AUTH0_ISSUER" "$AUTH0_JWKS_ENDPOINT" --audience "$AUTH0_AUDIENCE" --claims-property "email"
    else
        echo "Auth0 Ext JWT Signer already exists."
    fi

    if ! ziti edge list auth-policies 'name="auth0-auth"' | grep -q "auth0-auth"; then
        echo "Creating Auth0 Auth Policy..."
        ziti edge create auth-policy "auth0-auth" --primary-ext-jwt-allowed --primary-ext-jwt-allowed-signers "auth0"
    else
        echo "Auth0 Auth Policy already exists."
    fi
else
    echo "No Auth0 configuration detected. Falling back to local Keycloak for Kind testing..."

    attempt=0
    until curl -sf "$KEYCLOAK_DISCOVERY_URL" > /dev/null 2>&1; do
        attempt=$((attempt + 1))
        if [ "$attempt" -ge 60 ]; then
            echo "Keycloak realm 'ziti' did not become ready and Auth0 is not configured." >&2
            exit 1
        fi
        echo "Keycloak realm 'ziti' not ready yet. Retrying in 5 seconds..."
        sleep 5
    done
    echo "Keycloak realm 'ziti' is ready."

    if ! ziti edge list ext-jwt-signers 'name="keycloak"' | grep -q "keycloak"; then
        echo "Creating Keycloak Ext JWT Signer..."
        ziti edge create ext-jwt-signer "keycloak" "$KEYCLOAK_ISSUER" "$KEYCLOAK_JWKS_ENDPOINT" --audience "account" --claims-property "email"
    else
        echo "Keycloak Ext JWT Signer already exists."
    fi

    if ! ziti edge list auth-policies 'name="keycloak-auth"' | grep -q "keycloak-auth"; then
        echo "Creating Keycloak Auth Policy..."
        ziti edge create auth-policy "keycloak-auth" --primary-ext-jwt-allowed --primary-ext-jwt-allowed-signers "keycloak"
    else
        echo "Keycloak Auth Policy already exists."
    fi
fi

echo "Successfully configured external IdPs."
