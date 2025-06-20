# Docker Ansible Role

## Description

Installs and configures Docker.

## Requirements

- Ansible version: 2.9

## Role Variables

Refer to `defaults/main.yaml` for a full list of configurable variables. Some key variables include:
```yaml
# defaults/main.yaml
# docker_users: [vagrant, ubuntu]
```

This role does not use variables from `vars/main.yaml` by default.

## Dependencies

This role has no dependencies.

## Example Playbook

```yaml
- hosts: all
  become: yes
  roles:
    - role: xnok.infra_bootstrap_tools.docker
      # docker_users:
      #   - your_user
```

## License

MIT

## Author Information

Created by xNok.