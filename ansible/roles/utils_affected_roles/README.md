# Utils Affected Roles Ansible Role

## Description

Utility role to determine affected Ansible roles in a CI environment. This role compares the current branch with a target branch (e.g., main) to identify changed files and determines which Ansible roles under a specified path have been modified. This is useful for running linting or tests only on the roles that have changed.

## Requirements

-   Git executable available in the environment where Ansible is run.
-   The Ansible control node should be running from within a Git repository.
-   Ansible version: 2.9

## Role Variables

Available variables are listed in `defaults/main.yaml`:

```yaml
# defaults/main.yaml
# utils_affected_roles_always_run_all_roles: false # Set to true to bypass checking and always return all roles.
# utils_affected_roles_default_branch: "main"      # The branch to compare against.
# utils_affected_roles_roles_folder: "ansible/roles" # The folder containing Ansible roles.
```
The role sets a fact `affected_roles_list` which is a list of role names that have changed.

## Dependencies

This role has no external Galaxy dependencies.

## Example Playbook

```yaml
- hosts: localhost
  connection: local
  gather_facts: no
  roles:
    - role: xnok.infra_bootstrap_tools.utils_affected_roles
      vars:
        utils_affected_roles_default_branch: "production" # Compare against production branch
  tasks:
    - name: Display affected roles
      ansible.builtin.debug:
        var: affected_roles_list

    - name: Run linter on affected roles
      ansible.builtin.command: "ansible-lint {{ item }}"
      loop: "{{ affected_roles_list }}"
      when: affected_roles_list is defined and affected_roles_list | length > 0
```

## License

MIT

## Author Information

Created by xNok.
