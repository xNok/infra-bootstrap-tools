# Ansible Role: docker-swarm-app-caddy

Deploy [Caddy v2](https://caddyserver.com/) to your Docker Swarm cluster, configured as a powerful reverse proxy and authentication gateway.

This role sets up Caddy using a custom Docker image with the required plugins and ultimatly provides features like automatic HTTPS, dynamic DNS, service discovery via Docker labels, and GitHub OAuth-based authentication/authorization.

## Features

*   **Automatic HTTPS:** Provisions and renews TLS certificates automatically using Let's Encrypt via the DigitalOcean DNS challenge.
*   **Dynamic DNS:** Automatically updates DNS records for your domain using the DigitalOcean provider.
*   **Docker Proxy / Service Discovery:** Uses `caddy-docker-proxy` to automatically discover and configure reverse proxy routes for Docker Swarm services based on labels.
*   **Authentication:** Implements an authentication portal (`auth.{$DOMAIN}`) using `caddy-security` with GitHub OAuth as the identity provider.
*   **Authorization:** Provides an authorization policy (`admins_policy`) that grants access based on GitHub organization membership and JWT validation. Allows injecting user claims into headers for backend services.
*   **Custom Caddy Build:** Uses a pre-built custom Caddy image (`ghcr.io/xnok/infra-bootstrap-tools-caddy:main`) containing essential plugins.

## Custom Caddy Image

The configuration deploys a custom image based on `caddy:<version>-alpine`. This image includes the following Caddy modules:

*   github.com/lucaslorentz/caddy-docker-proxy/v2 - For Docker service discovery.
*   github.com/greenpau/caddy-security - For authentication and authorization features.
*   github.com/mholt/caddy-dynamicdns - For dynamic DNS updates.

The image is available at `ghcr.io/xnok/infra-bootstrap-tools-caddy:main`.

## Requirements

*   A DigitalOcean API Token with DNS read/write permissions.
*   A GitHub OAuth Application configured with:
    *   Homepage URL: `https://auth.YOUR_DOMAIN`
    *   Authorization callback URL: `https://auth.YOUR_DOMAIN/oauth2/github/callback`
*   The following **environment variables** must be set on the **Ansible control node** where the playbook is run:
    *   `CADDY_GITHUB_CLIENT_ID`: Your GitHub OAuth App Client ID.
    *   `CADDY_GITHUB_CLIENT_SECRET`: Your GitHub OAuth App Client Secret.
    *   `CADDY_JWT_SHARED_KEY`: A strong secret key for signing/verifying JWTs. Generate one using `openssl rand -base64 32`.
    *   `CADDY_DIGITALOCEAN_API_TOKEN`: Your DigitalOcean API Token for automatic dns

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yaml`):

| Variable                       | Default                     | Description                                                                                                |
| :----------------------------- | :-------------------------- | :--------------------------------------------------------------------------------------------------------- |
| `caddy_dir`                    | `/var/data/caddy`           | The directory on the target host where Caddy configuration and stack files will be stored.                 |
| `email`                        | `nokwebspace@gmail.com`     | The email address used for Let's Encrypt registration and notifications.                                   |
| `domain`                       | `nokwebspace.ovh`           | The primary domain Caddy will manage (for HTTPS, Dynamic DNS, Auth Portal).                                |
| `github_org`                   | `xNok`                      | The GitHub organization whose members will be granted the `authp/admin` role upon successful authentication. |
| `caddy_github_client_id`     | `lookup('env', ...)`        | **Required.** GitHub OAuth Client ID (read from `CADDY_GITHUB_CLIENT_ID` env var).                          |
| `caddy_github_client_secret` | `lookup('env', ...)`        | **Required.** GitHub OAuth Client Secret (read from `CADDY_GITHUB_CLIENT_SECRET` env var).                   |
| `caddy_jwt_shared_key`       | `lookup('env', ...)`        | **Required.** Shared secret for JWT signing/verification (read from `CADDY_JWT_SHARED_KEY` env var).         |
| `caddy_digitalocean_api_token` | `lookup('env', ...)`        | **Required.** DigitalOcean API Token (read from `CADDY_DIGITALOCEAN_API_TOKEN` env var).                   |

**Note on Secrets:** The role uses Ansible's `lookup('env', ...)` to read sensitive values. These values are then securely stored as Docker Swarm secrets. The Caddy container uses the provided `docker-entrypoint.sh` script to read these secrets from files (e.g., `/run/secrets/caddy_github_client_id`) into the environment variables expected by Caddy and its plugins (e.g., `GITHUB_CLIENT_ID`).

## Dependencies

This role internally uses `include_role` for the following roles, which must be available in your Ansible environment:

*   `utils-rotate-docker-configs`: To manage Docker Swarm configs (like the main `Caddyfile`).
*   `utils-rotate-docker-secrets`: To manage Docker Swarm secrets (API tokens, client secrets, JWT key).

## Example Playbook

```yaml
- hosts: swarm_managers
  become: yes
  roles:
    - role: docker-swarm-app-caddy # Adjust path/name as needed
      vars:
        # Override defaults if necessary
        domain: my-awesome-app.com
        email: admin@my-awesome-app.com
        github_org: MyGitHubOrg
        # Ensure required ENV variables are set on the machine running this playbook:
        # CADDY_GITHUB_CLIENT_ID, CADDY_GITHUB_CLIENT_SECRET,
        # CADDY_JWT_SHARED_KEY, CADDY_DIGITALOCEAN_API_TOKEN
