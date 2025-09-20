# Utils SSH Add Ansible Role

## Description

Utility role to dynamically set up an SSH agent on the Ansible control node (localhost) and add a private SSH key to it. This is particularly useful for loading SSH keys fetched from a vault (e.g., 1Password) at runtime, allowing Ansible to use these keys for subsequent SSH connections to managed nodes without storing them decrypted on disk permanently.

The role starts an `ssh-agent`, adds the provided private key, and sets facts (`ssh_agent_pid`, `ssh_auth_sock`) that can be used to configure `ansible_ssh_common_args` or environment variables for later tasks.

Despite its name and original meta description, this role primarily focuses on configuring the SSH *agent* for Ansible's *client-side* operations, not on adding keys to `authorized_keys` files on *remote* servers.

## Requirements

-   `ssh-agent` and `ssh-add` utilities must be installed on the Ansible control node (localhost).
-   Ansible version: 2.9

## Role Variables

Available variables are listed in `defaults/main.yaml`:

```yaml
# defaults/main.yaml
# utils_ssh_add_ansible_ssh_private_key_file: "{{ lookup('env', 'HOME') }}/.ssh/private_key_openssh"
```
The key variable that needs to be provided to this role is `private_key_openssh_content`, which should contain the actual private SSH key string. The `utils_ssh_add_ansible_ssh_private_key_file` is more of a temporary path for the key content to be written before adding to agent.

Key input variable:
- `private_key_openssh_content`: (Required) The string content of the private SSH key to be added to the agent.

Output facts:
- `ssh_agent_pid`: PID of the started ssh-agent.
- `ssh_auth_sock`: Path to the ssh-agent's socket.

## Dependencies

This role has no external Galaxy dependencies.

## Example Playbook

```yaml
- name: Prepare SSH Agent on Localhost
  hosts: localhost
  connection: local
  gather_facts: no # Not strictly needed for this role if run early

  vars:
    # Example: Fetching SSH key content from a vault or environment variable
    my_ssh_key_content: "{{ lookup('env', 'MY_SSH_PRIVATE_KEY') }}"
    # Or using a vault like 1Password:
    # my_ssh_key_content: "{{ lookup('community.general.onepassword_ssh_key', 'My Ansible SSH Key', vault='myvault', ssh_format=true) }}"


  roles:
    - role: xnok.infra_bootstrap_tools.utils_ssh_add
      vars:
        private_key_openssh_content: "{{ my_ssh_key_content }}"

- name: Use the SSH Agent for other tasks
  hosts: my_remote_servers
  # These vars/env would be set based on facts from the localhost play
  vars:
    ansible_ssh_common_args: "-o IdentityAgent={{ hostvars['localhost']['ssh_auth_sock'] }}"
  environment:
    SSH_AUTH_SOCK: "{{ hostvars['localhost']['ssh_auth_sock'] }}"
    # SSH_AGENT_PID: "{{ hostvars['localhost']['ssh_agent_pid'] }}" # Less commonly needed for Ansible itself

  tasks:
    - name: Ping remote server using the loaded SSH key
      ansible.builtin.ping:
```

## License

MIT

## Author Information

Created by xNok.
