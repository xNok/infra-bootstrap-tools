#!/usr/bin/env bash
set -e

# Vault name
VAULT="infra-bootstrap-tools"

echo "Ensuring vault '${VAULT}' exists..."
if ! op vault get "${VAULT}" >/dev/null 2>&1; then
    op vault create "${VAULT}"
fi

create_item_if_missing() {
    local title="$1"
    local category="$2"
    local vault="$3"
    shift 3
    
    echo "Checking item '${title}' in vault '${vault}'..."
    if ! op item get "${title}" --vault "${vault}" >/dev/null 2>&1; then
        echo "Creating item '${title}'..."
        op item create --category="${category}" --title="${title}" --vault="${vault}" "$@"
    else
        echo "Item '${title}' already exists."
    fi
}

echo "Creating 'GitHub_Flux_Token' secret placeholder..."
if ! op item get "GitHub_Flux_Token" --vault "${VAULT}" >/dev/null 2>&1; then
    op item create --category="Login" --title="GitHub_Flux_Token" --vault="${VAULT}" \
        "password=GITHUB_PAT_PLACEHOLDER"
else
    echo "Item 'GitHub_Flux_Token' already exists."
fi

echo "Creating 'GitHub_Flux_App_Private_Key' secrets..."
create_item_if_missing "GitHub_Flux_App_Private_Key" "Secure Note" "${VAULT}" \
    "notesPlain=PRIVATE_KEY_PEM_CONTENT"

echo "Creating 'CADDY_GITHUB_APP' secrets..."
create_item_if_missing "CADDY_GITHUB_APP" "Login" "${VAULT}" \
    "username=CLIENT_ID_PLACEHOLDER" \
    "credential=CLIENT_SECRET_PLACEHOLDER" \
    "url=https://github.com/settings/applications/new"

echo "Creating 'CADDY_JWT_SHARED_KEY' secrets..."
create_item_if_missing "CADDY_JWT_SHARED_KEY" "Password" "${VAULT}" \
    "password=$(openssl rand -base64 32)"

echo "Creating 'CADDY_DIGITALOCEAN_API_TOKEN' secrets..."
create_item_if_missing "CADDY_DIGITALOCEAN_API_TOKEN" "Login" "${VAULT}" \
    "credential=TOKEN_PLACEHOLDER"

echo "Creating 'RCLONE_DIGITALOCEAN' secrets..."
create_item_if_missing "RCLONE_DIGITALOCEAN" "Login" "${VAULT}" \
    "username=ACCESS_KEY_ID_PLACEHOLDER" \
    "password=SECRET_ACCESS_KEY_PLACEHOLDER"

echo "Creating 'DIGITALOCEAN_ACCESS_TOKEN' secrets..."
create_item_if_missing "DIGITALOCEAN_ACCESS_TOKEN" "Login" "${VAULT}" \
    "credential=DO_TOKEN_PLACEHOLDER"

echo "Creating 'TF_S3_BACKEND' secrets..."
create_item_if_missing "TF_S3_BACKEND" "Login" "${VAULT}" \
    "username=ACCESS_KEY_PLACEHOLDER" \
    "password=SECRET_KEY_PLACEHOLDER"

echo "Creating 'Ansible SSH Key' secrets..."
create_item_if_missing "Ansible SSH Key" "SSH Key" "${VAULT}" \
    "private_key=Generate new SSH Key"

echo "Done. Please update the placeholder values in 1Password."
