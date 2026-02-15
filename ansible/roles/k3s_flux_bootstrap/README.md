# Flux Bootstrap Role

This role sets up FluxCD on a K3s cluster using the ControlPlane Flux Operator. It configures a `FluxInstance` that points to a GitHub repository, authenticated via a GitHub App.

## Prerequisites: 1Password Secrets

This role uses the `community.general.onepassword` lookup plugin to retrieve GitHub App credentials. You must have the [1Password CLI (`op`)](https://developer.1password.com/docs/cli/get-started/) installed and signed in on the machine running Ansible.

The secrets are expected to be in a vault named `infra-bootstrap-tools`. The lookup logic uses this specific vault to keep roles clean and project-specific.

You can automatically create the required secret placeholders using the provided script:

```bash
./bin/bash/setup-secrets.sh
```

Then update the values in 1Password. See [docs/SECRETS.md](../../../docs/SECRETS.md) for more details.

### 1. GitHub App Credentials (`GitHub_Flux_App`)
- Item Name: `GitHub_Flux_App`
- Vault: `infra-bootstrap-tools`
- Field `username`: Your GitHub App ID.
- Field `password`: Your GitHub App Installation ID.

### 2. GitHub App Private Key (`GitHub_Flux_App_Private_Key`)
- Item Name: `GitHub_Flux_App_Private_Key`
- Vault: `infra-bootstrap-tools`
- Field `notesPlain`: The contents of your GitHub App's private key (`.pem` file).

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `k3s_flux_bootstrap_github_user` | `xnok` | GitHub username or organization content. |
| `k3s_flux_bootstrap_github_repo` | `infra-bootstrap-tools` | Repository name to reconcile. |
| `k3s_flux_bootstrap_cluster_name` | `k3s-openziti` | Folder in the repo to sync (`kubernetes/clusters/<name>`). |
| `k3s_flux_bootstrap_github_app_id` | *(lookup)* | GitHub App ID (from `GitHub_Flux_App`). |
| `k3s_flux_bootstrap_github_app_installation_id` | *(lookup)* | GitHub App Installation ID (from `GitHub_Flux_App`). |
