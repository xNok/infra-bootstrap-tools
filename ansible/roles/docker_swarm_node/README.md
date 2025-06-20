# Docker Swarm Node Ansible Role

## Description

Configures a node to join an existing Docker Swarm cluster as a worker node. This role requires that a Swarm controller (initial manager) has already been initialized and its worker join token is available.

## Requirements

-   Docker installed and running on the target node.
-   An existing Docker Swarm cluster.
-   The Docker Swarm worker join token (typically obtained from a manager node).
-   Ansible version: 2.9

## Role Variables

Available variables are listed in `defaults/main.yaml`:

```yaml
# defaults/main.yaml
# docker_swarm_node_manager_inventory_group_name: 'managers'
```
This variable is used to identify the group of manager nodes in the inventory, which helps in fetching Swarm facts like the worker join token from the correct host (usually the first controller or any manager).

The role expects the worker join token to be available as a host fact, typically set by the `docker_swarm_controller` role (e.g., `hostvars[groups[docker_swarm_node_manager_inventory_group_name][0]]['swarm_worker_join_token']`).

## Dependencies

-   `xnok.infra_bootstrap_tools.docker` (or an equivalent role to ensure Docker is installed)

## Example Playbook

```yaml
- hosts: new_swarm_workers
  become: yes
  roles:
    - role: xnok.infra_bootstrap_tools.docker
    - role: xnok.infra_bootstrap_tools.docker_swarm_node
      # Ensure a manager node (e.g., in 'managers' group) has run docker_swarm_controller
      # and the swarm_worker_join_token is available.
```

## License

MIT

## Author Information

Created by xNok.
