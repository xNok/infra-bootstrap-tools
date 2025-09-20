# Docker Swarm App Caddy Ansible Role

## Description

Deploys Caddy as a Docker Swarm service.

This role sets up Caddy v2 using a custom Docker image. It provides features like automatic HTTPS via Let's Encrypt (DigitalOcean DNS challenge), dynamic DNS, service discovery for Docker Swarm services using labels (via `caddy-docker-proxy`), and GitHub OAuth-based authentication/authorization (via `caddy-security`). The Caddy configuration is templated using `caddy-stack.yml.j2` and `Caddyfile.j2`.

## Features

*   **Automatic HTTPS:** Provisions and renews TLS certificates automatically.
*   **Dynamic DNS:** Updates DNS records for your domain (DigitalOcean).
*   **Docker Proxy / Service Discovery:** Discovers and configures reverse proxy routes for Swarm services.
*   **Authentication & Authorization:** Implements an authentication portal with GitHub OAuth.
*   **Custom Caddy Build:** Uses `ghcr.io/xnok/infra-bootstrap-tools-caddy:main` which includes `caddy-docker-proxy`, `caddy-security`, and `caddy-dynamicdns`.

## Requirements

-   A DigitalOcean API Token with DNS read/write permissions.
-   A GitHub OAuth Application.
-   The following environment variables must be set on the Ansible control node:
    *   `CADDY_GITHUB_CLIENT_ID`
    *   `CADDY_GITHUB_CLIENT_SECRET`
    *   `CADDY_JWT_SHARED_KEY`
    *   `CADDY_DIGITALOCEAN_API_TOKEN`
-   Ansible version: 2.9

## Role Variables

Available variables are listed in `defaults/main.yaml`. Key variables include:

```yaml
# defaults/main.yaml
# docker_swarm_app_caddy_host_dir: /var/data/caddy
# docker_swarm_app_caddy_tls_email: "nokwebspace@gmail.com"
# docker_swarm_app_caddy_tls_domain: "nokwebspace.ovh"
# docker_swarm_app_caddy_github_org: "xNok"
# docker_swarm_app_caddy_github_client_id: "{{ lookup('env', 'CADDY_GITHUB_CLIENT_ID') }}"
# docker_swarm_app_caddy_github_client_secret: "{{ lookup('env', 'CADDY_GITHUB_CLIENT_SECRET') }}"
# docker_swarm_app_caddy_jwt_shared_key: "{{ lookup('env', 'CADDY_JWT_SHARED_KEY') | replace('\\n', '\\\\n') }}"
# docker_swarm_app_caddy_digitalocean_api_token: "{{ lookup('env', 'CADDY_DIGITALOCEAN_API_TOKEN') }}"
```

The role uses Ansible's `lookup('env', ...)` for sensitive values, which are then managed as Docker Swarm secrets. The Caddy container uses an entrypoint script to load these secrets.
The main Caddy configuration is managed via `templates/Caddyfile.j2` and the Docker stack via `templates/caddy-stack.yml.j2`.

## Dependencies

This role has no external Galaxy dependencies.
It internally uses `include_role` for `utils_rotate_docker_configs` and `utils_rotate_docker_secrets`.

## Example Playbook

```yaml
- hosts: swarm_managers
  become: yes
  roles:
    - role: xnok.infra_bootstrap_tools.docker_swarm_app_caddy
      vars:
        docker_swarm_app_caddy_tls_domain: my-awesome-app.com
        docker_swarm_app_caddy_tls_email: admin@my-awesome-app.com
        docker_swarm_app_caddy_github_org: MyGitHubOrg
        # Ensure CADDY_* environment variables are set on the control node.
```

## License

MIT

## Author Information

Created by xNok.
