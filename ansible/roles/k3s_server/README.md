# K3s Server Ansible Role

## Description

Installs and configures a K3s server node (control plane). This role sets up the initial K3s server and makes the node token available for agent nodes to join the cluster.

## Requirements

-   A Linux system (Ubuntu, Debian, CentOS, etc.)
-   Internet access to download K3s
-   Ansible version: 2.9+

## Role Variables

Available variables are listed in `defaults/main.yaml`:

```yaml
# defaults/main.yaml
k3s_server_version: '' # Leave empty for stable channel, or set specific version like 'v1.26.0+k3s1'
k3s_server_kubeconfig_mode: '600' # File mode for kubeconfig; 600 (owner-only) is the secure default. Override with caution (e.g. to '644').
k3s_server_extra_args: "--write-kubeconfig-mode {{ k3s_server_kubeconfig_mode }}"
```

### Variable Details

-   **k3s_server_version**: Specifies the K3s version to install. Leave empty to use the stable channel, or specify a version like 'v1.26.0+k3s1'.
-   **k3s_server_kubeconfig_mode**: Sets the file permissions for the kubeconfig file. Default is '600' (owner-only) for security. Can be overridden to '644' for easier access, but this may expose cluster credentials.
-   **k3s_server_extra_args**: Additional arguments to pass to the K3s server. By default, sets the kubeconfig permissions.

The role sets a fact `k3s_server_token` which contains the node token needed by agent nodes to join the cluster.

## Dependencies

None

## Example Playbook

```yaml
- hosts: k3s_servers
  become: yes
  roles:
    - role: xnok.infra_bootstrap_tools.k3s_server
      vars:
        k3s_server_version: 'v1.28.0+k3s1'
        k3s_server_kubeconfig_mode: '644' # Override for easier access (less secure)
```

## License

MIT

## Author Information

Created by xNok.
