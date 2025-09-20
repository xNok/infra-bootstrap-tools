# Docker Swarm App Portainer Ansible Role

## Description

Deploys Portainer (Agent and Server) as a Docker Swarm service. Portainer is a lightweight management UI which allows you to easily manage your Docker Swarm cluster. This role uses a Jinja2 template (`portainer-agent-stack.yml.j2`) to define the Portainer stack.

## Requirements

-   A running Docker Swarm cluster.
-   Ansible version: 2.9

## Role Variables

Available variables are listed in `defaults/main.yaml`:

```yaml
# defaults/main.yaml
# docker_swarm_app_portainer_assets_path: "{{ role_path }}/assets"
# docker_swarm_app_portainer_host_dir: /var/data/portainer
# docker_swarm_app_portainer_caddy: false # Set to true to expose Portainer via Caddy
```
The `docker_swarm_app_portainer_caddy` variable can be set to true if you are using the `docker_swarm_app_caddy` role to automatically expose Portainer with HTTPS.

## Dependencies

This role has no external Galaxy dependencies.

## Example Playbook

```yaml
- hosts: swarm_managers
  become: yes
  roles:
    - role: xnok.infra_bootstrap_tools.docker_swarm_app_portainer
      # docker_swarm_app_portainer_caddy: true # If using Caddy for exposure
```

## License

MIT

## Author Information

Created by xNok.