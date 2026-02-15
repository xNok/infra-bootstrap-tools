# Secrets Management

This repository uses 1Password for managing secrets required by Ansible playbooks and other tools.

## Required Secrets

The following items are expected to exist in the `infra-bootstrap-tools` vault.

| Item Title | Field | Description | Used By |
| text | text | text | text |
| `GitHub_Flux_App` | `username` | GitHub App ID | `roles/k3s_flux_bootstrap` |
| `GitHub_Flux_App` | `password` | GitHub App Installation ID | `roles/k3s_flux_bootstrap` |
| `GitHub_Flux_App_Private_Key` | `notesPlain` | GitHub App Private Key (PEM) | `roles/k3s_flux_bootstrap` |
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

## Setup Script

A helper script is available to create the Flux-related secrets with placeholder values:

```bash
./bin/bash/setup-secrets.sh
```

After running this script, you must manually update the items in 1Password with the actual values.
