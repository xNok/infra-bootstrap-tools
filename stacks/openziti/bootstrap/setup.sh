#!/bin/bash
set -e  # Exit immediately if any command fails
set -o pipefail  # Exit if any command in a pipeline fails

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# --- Configuration ---
ZITI_CTRL_ADDRESS="${ZITI_CTRL_ADVERTISED_ADDRESS:-ziti-controller}"
ZITI_CTRL_PORT="${ZITI_CTRL_ADVERTISED_PORT:-6262}"
SPIRE_SERVER="${SPIRE_SERVER_ADDRESS:-spire-server:8081}"
KEYCLOAK_BASE_URL="${KEYCLOAK_URL:-https://keycloak.example.com}"
KEYCLOAK_REALM="${KEYCLOAK_REALM:-openziti}"
TRUST_DOMAIN="${TRUST_DOMAIN:-openziti.local}"

# Read secrets
if [ -f "/run/secrets/ziti_admin_user" ]; then
    ZITI_ADMIN_USER=$(cat /run/secrets/ziti_admin_user)
else
    ZITI_ADMIN_USER="${ZITI_USER:-admin}"
fi

if [ -f "/run/secrets/ziti_admin_password" ]; then
    ZITI_ADMIN_PASS=$(cat /run/secrets/ziti_admin_password)
else
    log_error "Ziti admin password secret not found"
    exit 1
fi

# --- 1. Wait for Services ---
log_info "Waiting for Ziti Controller at ${ZITI_CTRL_ADDRESS}:1280..."
MAX_RETRIES=30
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -k -f -s "https://${ZITI_CTRL_ADDRESS}:1280/.well-known/health-check" > /dev/null 2>&1; then
        log_info "Ziti Controller is ready"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        log_error "Timeout waiting for Ziti Controller"
        exit 1
    fi
    sleep 10
done

log_info "Waiting for SPIRE Server at ${SPIRE_SERVER}..."
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f -s "http://${SPIRE_SERVER}/health/ready" > /dev/null 2>&1; then
        log_info "SPIRE Server is ready"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        log_error "Timeout waiting for SPIRE Server"
        exit 1
    fi
    sleep 10
done

# --- 2. Log in to Ziti ---
log_info "Logging in to Ziti Controller..."
export ZITI_CTRL_MGMT_API="https://${ZITI_CTRL_ADDRESS}:1280"

if ! ziti edge login "${ZITI_CTRL_ADDRESS}:1280" -u "${ZITI_ADMIN_USER}" -p "${ZITI_ADMIN_PASS}" -y; then
    log_error "Failed to login to Ziti Controller"
    exit 1
fi

log_info "Successfully logged in to Ziti Controller"

# --- 3. Configure SPIRE ---
log_info "Configuring SPIRE for Ziti router workload..."

# Check if SPIRE entry already exists
SPIRE_ENTRY_EXISTS=$(spire-server entry show -spiffeID "spiffe://${TRUST_DOMAIN}/ziti-router" 2>&1 | grep -c "spiffe://${TRUST_DOMAIN}/ziti-router" || true)

if [ "$SPIRE_ENTRY_EXISTS" -eq "0" ]; then
    log_info "Creating SPIRE entry for Ziti router..."
    
    # Create registration entry for Ziti router
    # Note: The parent ID needs to be obtained from the SPIRE agent
    # For now, we use a selector-based approach
    if spire-server entry create \
        -spiffeID "spiffe://${TRUST_DOMAIN}/ziti-router" \
        -selector "docker:label:app:ziti-router" \
        -ttl 3600; then
        log_info "SPIRE entry created successfully"
    else
        log_warn "Failed to create SPIRE entry (might already exist)"
    fi
else
    log_info "SPIRE entry already exists for Ziti router"
fi

# --- 4. Configure Ziti with Keycloak OIDC ---
log_info "Configuring Keycloak OIDC in Ziti..."

KEYCLOAK_ISSUER="${KEYCLOAK_BASE_URL}/realms/${KEYCLOAK_REALM}"
KEYCLOAK_JWKS="${KEYCLOAK_ISSUER}/protocol/openid-connect/certs"

# Check if external JWT signer already exists
if ziti edge list ext-jwt-signers | grep -q "keycloak-signer"; then
    log_info "Keycloak JWT signer already exists"
else
    log_info "Creating Keycloak external JWT signer..."
    if ziti edge create ext-jwt-signer "keycloak-signer" \
        "${KEYCLOAK_ISSUER}" \
        --jwks-endpoint "${KEYCLOAK_JWKS}" \
        --audience "openziti-client" \
        --claims-property "email"; then
        log_info "Keycloak JWT signer created successfully"
    else
        log_warn "Failed to create Keycloak JWT signer (might already exist)"
    fi
fi

# Create auth policy for Keycloak users
if ziti edge list auth-policies | grep -q "keycloak-auth-policy"; then
    log_info "Keycloak auth policy already exists"
else
    log_info "Creating Keycloak auth policy..."
    if ziti edge create auth-policy "keycloak-auth-policy" \
        --primary-ext-jwt-allowed \
        --primary-ext-jwt-allowed-signers "keycloak-signer"; then
        log_info "Keycloak auth policy created successfully"
    else
        log_warn "Failed to create Keycloak auth policy (might already exist)"
    fi
fi

# --- 5. Bind SPIRE CA to Ziti ---
log_info "Binding SPIRE CA to Ziti..."

# Get SPIRE trust bundle
if spire-server bundle show > /tmp/spire-trust-bundle.pem 2>&1; then
    log_info "Retrieved SPIRE trust bundle"
    
    # Check if CA already exists
    if ziti edge list cas | grep -q "spire-ca"; then
        log_info "SPIRE CA already exists in Ziti"
    else
        log_info "Creating SPIRE CA in Ziti..."
        if ziti edge create ca "spire-ca" \
            -c /tmp/spire-trust-bundle.pem \
            --auto-ca-enrollment \
            --identity-roles "#spire-routers" \
            --identity-name-format "[caName]-auto-[commonName]"; then
            log_info "SPIRE CA created successfully"
        else
            log_warn "Failed to create SPIRE CA (might already exist)"
        fi
    fi
    
    # Clean up
    rm -f /tmp/spire-trust-bundle.pem
else
    log_error "Failed to retrieve SPIRE trust bundle"
fi

# --- 6. Auto-Verify the CA ---
log_info "Note: CA auto-verification requires manual steps or pre-generated CA keys"
log_info "See documentation for CA verification process"

# --- 7. Create default service policies ---
log_info "Creating default service policies..."

# Create a default edge router policy if it doesn't exist
if ! ziti edge list edge-router-policies | grep -q "all-routers-policy"; then
    log_info "Creating default edge router policy..."
    if ziti edge create edge-router-policy "all-routers-policy" \
        --edge-router-roles "#all" \
        --identity-roles "#all"; then
        log_info "Default edge router policy created"
    fi
fi

# Create a default service edge router policy
if ! ziti edge list service-edge-router-policies | grep -q "all-services-policy"; then
    log_info "Creating default service edge router policy..."
    if ziti edge create service-edge-router-policy "all-services-policy" \
        --edge-router-roles "#all" \
        --service-roles "#all"; then
        log_info "Default service edge router policy created"
    fi
fi

log_info "=========================================="
log_info "Bootstrap complete!"
log_info "=========================================="
log_info "Next steps:"
log_info "1. Configure Keycloak realm and clients"
log_info "2. Verify SPIRE CA in Ziti controller"
log_info "3. Deploy and enroll edge routers"
log_info "=========================================="

exit 0
