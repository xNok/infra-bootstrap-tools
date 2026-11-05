# Secrets Management

This repository uses 1Password for managing secrets required by Ansible playbooks and other tools.

## Required Secrets

The following items are expected to exist in the `infra-bootstrap-tools` vault.

| Item Title | Field | Description | Used By |
| --- | --- | --- | --- |
| `GitHub_Flux_Token` | `password` | GitHub Personal Access Token | `roles/k3s_flux_bootstrap` |
| `EXTERNAL_SECRETS_ONEPASSWORD_SERVICE_ACCOUNT` | `credential` | 1Password Service Account Token for External Secrets Operator | `roles/k3s_flux_bootstrap` |
| `EXTERNAL_DNS_DIGITALOCEAN_API_TOKEN` | `credential` | DigitalOcean API Token for ExternalDNS DNS sync | `fleet/k3s/infra-addons` (via ESO) |
| `CADDY_GITHUB_APP` | `username` | GitHub OAuth Client ID | `roles/docker_swarm_app_caddy` |
| `CADDY_GITHUB_APP` | `credential` | GitHub OAuth Client Secret | `roles/docker_swarm_app_caddy` |
| `CADDY_JWT_SHARED_KEY` | `password` | JWT Shared Key | `roles/docker_swarm_app_caddy` |
| `CADDY_DIGITALOCEAN_API_TOKEN` | `credential` | DigitalOcean API Token | `roles/docker_swarm_app_caddy` |
| `RCLONE_DIGITALOCEAN` | `username` | Rclone Access Key ID | `group_vars/all.yml` |
| `RCLONE_DIGITALOCEAN` | `password` | Rclone Secret Access Key | `group_vars/all.yml` |
| `DIGITALOCEAN_ACCESS_TOKEN` | `credential` | DigitalOcean API Token | `host_vars/localhost.yml`, `terraform.yml` |
| `TF_S3_BACKEND` | `username` | S3 Backend Access Key | `host_vars/localhost.yml`, `terraform.yml` |
| `TF_S3_BACKEND` | `password` | S3 Backend Secret Key | `host_vars/localhost.yml`, `terraform.yml` |
| `Ansible SSH Key` | `private_key` | SSH Private Key | `host_vars/localhost.yml` |
| `Ansible SSH Key` | `public_key` | SSH Public Key | `host_vars/localhost.yml` |

## Naming Convention

Secret items follow the structured naming convention:
`{consumer}_{resource server}_{what}`

Examples:
- `EXTERNAL_SECRETS_ONEPASSWORD_SERVICE_ACCOUNT`: Used by External Secrets Operator to authenticate with 1Password.
- `EXTERNAL_DNS_DIGITALOCEAN_API_TOKEN`: Used by ExternalDNS to synchronize DNS records with DigitalOcean.
- `CADDY_DIGITALOCEAN_API_TOKEN`: Used by Caddy to manage ACME DNS challenges with DigitalOcean.

## Setup Script

A helper script is available to create the Flux-related secrets with placeholder values:

```bash
./bin/bash/setup-secrets.sh
```

After running this script, you must manually update the items in 1Password with the actual values.
