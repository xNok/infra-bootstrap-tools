# utils-ssh-add

This roles allow you to setup your ansible agent on the fly, this is especially conveniant when fetching the your SSH keys from a secret vault.

## Usage

```yaml
- name: Prepare localhost
  hosts: localhost
  gather_facts: true

  vars:
    private_key_openssh: "{{
        lookup('community.general.onepassword_ssh_key', 'Ansible SSH Key',
        vault='infra-bootstrap-tools', ssh_format=true)
        }}"

  roles:
  - utils-ssh-add


- name: Main Tasks
  hosts: all

  vars:
    ansible_ssh_common_args: "-o 'IdentityAgent={{ hostvars['localhost']['ssh_auth_sock'] }}'"
  environment: 
    SSH_AGENT_PID: "{{ hostvars['localhost']['ssh_agent_pid'] }}"
    SSH_AUTH_SOCK: "{{ hostvars['localhost']['ssh_auth_sock'] }}"
```
