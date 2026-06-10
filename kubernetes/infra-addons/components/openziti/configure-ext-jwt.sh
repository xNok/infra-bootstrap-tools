#!/bin/sh
set -e

# Wait for controller API to be reachable
echo "Waiting for OpenZiti controller API to be reachable..."
RETRY_INTERVAL_SECONDS=5
MAX_WAIT_SECONDS=300
elapsed_seconds=0
until curl -sk https://openziti-ziti-controller-client.openziti.svc.cluster.local:1280/edge/client/v1/version > /dev/null 2>&1; do
    if [ "$elapsed_seconds" -ge "$MAX_WAIT_SECONDS" ]; then
        echo "Timed out after ${MAX_WAIT_SECONDS} seconds waiting for OpenZiti controller API to become reachable."
        exit 1
    fi
    echo "Controller not ready. Retrying in ${RETRY_INTERVAL_SECONDS} seconds..."
    sleep "$RETRY_INTERVAL_SECONDS"
    elapsed_seconds=$((elapsed_seconds + RETRY_INTERVAL_SECONDS))
done
echo "Controller is ready."

echo "Logging into Ziti Controller..."
ziti edge login openziti-ziti-controller-client.openziti.svc.cluster.local:1280 -u admin -p "$ZITI_PWD" -y

# Configure Keycloak (used for local testing in Kind)
if ! ziti edge list ext-jwt-signers 'name="keycloak"' | grep -q "keycloak"; then
    echo "Creating Keycloak Ext JWT Signer..."
    # Based on docs the creation is: ziti edge create ext-jwt-signer <name> <issuer> <jwksEndpoint> --audience <audience> --claims-property <claims-property>
    ziti edge create ext-jwt-signer "keycloak" "http://keycloak.keycloak.svc.cluster.local:80/realms/ziti" "http://keycloak.keycloak.svc.cluster.local:80/realms/ziti/protocol/openid-connect/certs" --audience "account" --claims-property "email"
else
    echo "Keycloak Ext JWT Signer already exists."
fi

if ! ziti edge list auth-policies 'name="keycloak-auth"' | grep -q "keycloak-auth"; then
    echo "Creating Keycloak Auth Policy..."
    ziti edge create auth-policy "keycloak-auth" --primary-ext-jwt-allowed --primary-ext-jwt-allowed-signers "keycloak"
else
    echo "Keycloak Auth Policy already exists."
fi


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
    echo "Skipping Auth0 configuration as required environment variables are not set."
fi

echo "Successfully configured external IdPs."
