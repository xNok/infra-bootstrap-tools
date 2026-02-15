# k3s_os_hardening

This Ansible role applies basic OS-level hardening for a K3s node.  
It configures UFW (Uncomplicated Firewall) and related settings to secure the host for the **Dark K3s** stack, allowing only the ports required for K3s control plane, worker nodes, and supporting services.

## Features

- Enables and configures UFW on the target host.
- Restricts inbound traffic to only the ports required by the Dark K3s stack.
- Optionally allows additional ports for SSH and other management services.
- Provides variables to customize allowed ports and default policies.

## Requirements

- A supported Linux distribution (typically Ubuntu/Debian-based) with:
  - `ufw` available in the package repositories.
  - Systemd (or equivalent) for managing services.
- Ansible user with sufficient privileges to:
  - Install packages.
  - Enable and configure UFW.
  - Modify system firewall settings (typically via `become: true`).

## Role Variables

The following variables are defined in `defaults/main.yml`:

- `k3s_os_hardening_default_input` (string, default: `"deny"`)  
  Default policy for incoming connections.

- `k3s_os_hardening_default_output` (string, default: `"allow"`)  
  Default policy for outgoing connections.

- `k3s_os_hardening_k3s_api_cidr` (string, default: `"10.0.0.0/24"`)  
  CIDR range for internal K3s traffic (API server, kubelet, flannel VXLAN).
  **IMPORTANT**: Override this variable with your actual internal network CIDR range for your infrastructure.

> Refer to this role's `defaults/main.yml` and `vars/` files for the authoritative list of variables and their defaults.

## Usage

Include the role in your playbook and set any variables relevant to your environment:

```yaml
- hosts: k3s_nodes
  become: true
  roles:
    - role: k3s_os_hardening
      vars:
        k3s_os_hardening_k3s_api_cidr: "192.168.1.0/24"
```

## Dependencies

- `community.general` collection (for the `ufw` module)

## License

See the repository LICENSE file.

## Author Information

This role is part of the `infra-bootstrap-tools` project.
