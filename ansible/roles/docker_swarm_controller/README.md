# Docker Swarm Controller Ansible Role

## Description

Initializes a Docker Swarm cluster on the target node, making it the first manager (controller) of the Swarm. It also stores the join tokens for managers and workers, which can be used by other roles to add more nodes to the Swarm.

## Requirements

-   Docker installed and running on the target node. (This role is often used in conjunction with a Docker installation role).
-   Ansible version: 2.9

## Role Variables

This role does not have configurable variables with defaults. It uses facts set during its execution (like join tokens) that can be used by subsequent roles or plays.

## Dependencies

This role has no external Galaxy dependencies. It is recommended to run a Docker installation role before this one.

## Example Playbook

```yaml
- hosts: swarm_controller_node
  become: yes
  roles:
    - role: xnok.infra_bootstrap_tools.docker  # Example: ensure Docker is installed
    - role: xnok.infra_bootstrap_tools.docker_swarm_controller
```

## License

MIT

## Author Information

Created by xNok.
