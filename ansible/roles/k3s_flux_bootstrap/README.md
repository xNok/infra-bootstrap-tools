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

### 1. GitHub Personal Access Token (`GitHub_Flux_Token`)
- Item Name: `GitHub_Flux_Token`
- Vault: `infra-bootstrap-tools`
- Field `password`: Your GitHub Personal Access Token with required scopes: `read:packages` (to pull OCI artifacts from GHCR).

### 2. External Secrets 1Password Service Account Token (`EXTERNAL_SECRETS_ONEPASSWORD_SERVICE_ACCOUNT`)
- Item Name: `EXTERNAL_SECRETS_ONEPASSWORD_SERVICE_ACCOUNT`
- Vault: `infra-bootstrap-tools`
- Field `credential`: 1Password Service Account Auth Token (starts with `ops_...`) for the cluster's External Secrets Operator.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `k3s_flux_bootstrap_github_user` | `xnok` | GitHub username or organization. |
| `k3s_flux_bootstrap_github_repo` | `infra-bootstrap-tools` | Repository name to reconcile. |
| `k3s_flux_bootstrap_cluster_name` | `openziti` | Folder in the repo to sync (`kubernetes/fleet/<name>`). |
| `k3s_flux_bootstrap_github_token` | *(lookup)* | GitHub Personal Access Token (from `GitHub_Flux_Token`). |
| `k3s_flux_bootstrap_1password_service_account_token` | *(lookup)* | 1Password Service Account token (from `OP_SERVICE_ACCOUNT_TOKEN` or `EXTERNAL_SECRETS_ONEPASSWORD_SERVICE_ACCOUNT`). |
