# K3s Agent Ansible Role

## Description

Configures a node to join an existing K3s cluster as an agent (worker node). This role requires that a K3s server has already been initialized and its node token is available.

## Requirements

-   A Linux system (Ubuntu, Debian, CentOS, etc.)
-   Internet access to download K3s
-   An existing K3s server with the node token available
-   Ansible version: 2.9+

## Role Variables

Available variables are listed in `defaults/main.yaml`:

```yaml
# defaults/main.yaml
k3s_agent_server_inventory_group_name: 'managers'
k3s_agent_version: '' # Match server version if set
k3s_agent_extra_args: ''
```

### Variable Details

-   **k3s_agent_server_inventory_group_name**: The inventory group name containing the K3s server nodes. Used to retrieve the server's host and token.
-   **k3s_agent_version**: Specifies the K3s version to install. Should typically match the server version. Leave empty to use the stable channel.
-   **k3s_agent_extra_args**: Additional arguments to pass to the K3s agent.

The role expects the node token to be available as a host fact from the K3s server, set by the `k3s_server` role (e.g., `hostvars[groups[k3s_agent_server_inventory_group_name][0]]['k3s_server_token']`).

## Dependencies

-   A K3s server must be initialized first using the `xnok.infra_bootstrap_tools.k3s_server` role

## Example Playbook

```yaml
- hosts: k3s_agents
  become: yes
  roles:
    - role: xnok.infra_bootstrap_tools.k3s_agent
      vars:
        k3s_agent_version: 'v1.28.0+k3s1'
        k3s_agent_server_inventory_group_name: 'k3s_servers'
```

## Complete Example

```yaml
- name: Setup K3s Server
  hosts: k3s_servers
  become: true
  roles:
    - xnok.infra_bootstrap_tools.k3s_server

- name: Setup K3s Agents
  hosts: k3s_agents
  become: true
  roles:
    - xnok.infra_bootstrap_tools.k3s_agent
```

## License

MIT

## Author Information

Created by xNok.
