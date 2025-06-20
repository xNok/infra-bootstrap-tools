# Utils Rotate Docker Configs Ansible Role

## Description

Utility role to rotate Docker Swarm configs. This role helps manage updates to Docker Swarm configurations by creating a new version of a config and then updating a specified Docker Swarm service (via its compose file) to use the new config. It's designed to allow services to pick up config changes without manual intervention.

## Requirements

-   Target node must be a Docker Swarm manager.
-   Docker CLI available on the Swarm manager.
-   Ansible version: 2.9

## Role Variables

Available variables are listed in `defaults/main.yaml`:

```yaml
# defaults/main.yaml
# utils_rotate_docker_configs_docker_compose_path: "{{ undef(hint='You must specify docker-compose file to update') }}"
```
This role requires the following variables to be passed directly during the role call:
- `config_name`: The base name of the Docker Swarm config to rotate (e.g., `my_app_config`).
- `config_content`: The new content for the Docker Swarm config.
- `service_name`: The name of the Docker Swarm service that uses this config and needs to be updated.
- `docker_compose_path`: The path to the Docker Compose file that defines the service. This variable is also in defaults but must be overridden.

The role generates a new config name with a timestamp (e.g., `my_app_config_20230101120000`).

## Dependencies

This role has no external Galaxy dependencies.

## Example Playbook

```yaml
- hosts: swarm_managers
  become: yes
  roles:
    - role: xnok.infra_bootstrap_tools.utils_rotate_docker_configs
      vars:
        config_name: "my_caddy_config"
        config_content: |
          # New Caddyfile content
          example.com {
            reverse_proxy my_app_service:80
          }
        service_name: "caddy_service" # As defined in your docker-compose.yml
        docker_compose_path: "/opt/myapp/docker-compose.yml"
```

This will create a new Docker config (e.g., `my_caddy_config_xxxxxxxxxxxxxx`), update the service `caddy_service` in `/opt/myapp/docker-compose.yml` to point to this new config, and then re-deploy the service.

## License

MIT

## Author Information

Created by xNok.
