# Utils Rotate Docker Secrets Ansible Role

## Description

Utility role to rotate Docker Swarm secrets. This role facilitates updating Docker Swarm secrets by creating a new version of a secret and then updating a specified Docker Swarm service (via its compose file) to use the new secret. This allows services to pick up new secret versions without downtime or manual secret updates.

## Requirements

-   Target node must be a Docker Swarm manager.
-   Docker CLI available on the Swarm manager.
-   Ansible version: 2.9

## Role Variables

Available variables are listed in `defaults/main.yaml`:

```yaml
# defaults/main.yaml
# utils_rotate_docker_secrets_docker_compose_path: "{{ undef(hint='You must specify docker-compose file to update') }}"
```
This role requires the following variables to be passed directly during the role call:
- `secret_name`: The base name of the Docker Swarm secret to rotate (e.g., `my_app_db_password`).
- `secret_value`: The new value for the Docker Swarm secret.
- `service_name`: The name of the Docker Swarm service that uses this secret and needs to be updated.
- `docker_compose_path`: The path to the Docker Compose file that defines the service. This variable is also in defaults but must be overridden.

The role generates a new secret name with a timestamp (e.g., `my_app_db_password_20230101120000`).

## Dependencies

This role has no external Galaxy dependencies.

## Example Playbook

```yaml
- hosts: swarm_managers
  become: yes
  roles:
    - role: xnok.infra_bootstrap_tools.utils_rotate_docker_secrets
      vars:
        secret_name: "webapp_api_key"
        secret_value: "new_super_secret_api_key"
        service_name: "my_webapp_service" # As defined in your docker-compose.yml
        docker_compose_path: "/srv/my_webapp/docker-compose.yml"
```

This will create a new Docker secret (e.g., `webapp_api_key_xxxxxxxxxxxxxx`), update the service `my_webapp_service` in `/srv/my_webapp/docker-compose.yml` to point to this new secret, and then re-deploy the service.

## License

MIT

## Author Information

Created by xNok.
