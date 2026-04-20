# ansible-collection-infra-bootstrap-tools

## 1.1.0

### Minor Changes

- af6e8d6: Standardize Docker Swarm inventory group names: rename default group from `managers` / `nodes` to `docker_swarm_managers` / `docker_swarm_nodes` to align with the Terraform provisioning roles. Fix variable reference for join-token retrieval in the node role.
- af6e8d6: Improve K3s / Flux Bootstrap support: add Flux CLI installation task, update OCI sync URL to the new fleet path format (`oci://…/kubernetes/fleet/<cluster>`), change `k3s_flux_bootstrap_cluster_name` default to `k3s`, and update `k3s_server_kubeconfig_mode` default to `644`. Add initial Kubernetes infra-addons fleet configuration with cert-manager, trust-manager, OpenZiti controller and router.
- af6e8d6: Remove `diodonfrost.terraform` dependency from Terraform roles and switch to `community.general.terraform` module. Add configurable inventory group name variables (`*_inventory_managers_group` and `*_inventory_nodes_group`) defaulting to `docker_swarm_managers` / `docker_swarm_nodes`.

### Patch Changes

- Updated dependencies [af6e8d6]
- Updated dependencies [af6e8d6]
- Updated dependencies [af6e8d6]
- Updated dependencies [af6e8d6]
  - ansible-role-docker-swarm-manager@0.1.0
  - ansible-role-docker-swarm-node@0.1.0
  - ansible-role-k3s-flux-bootstrap@0.2.0
  - ansible-role-k3s-server@0.1.3
  - ansible-role-terraform-aws@0.1.0
  - ansible-role-terraform-digitalocean@0.2.0
  - ansible-role-utils-affected-roles@0.0.3

## 1.0.7

### Patch Changes

- c6087dd: Updated OpenZiti and K3s "Dark" Setup:
  - **k3s_server**: Migrated from command-line arguments to `/etc/rancher/k3s/config.yaml` for configuration. Added support for binding API only to local interfaces (dark mode).
  - **k3s_flux_bootstrap**: Fixed `FluxInstance` spec to use `kind: OCIRepository` and added `path: "."` for OCI-based bootstrap.
  - **k3s_os_hardening**: Added UFW rules to restrict K3s API access to a specific CIDR and ensure secure defaults.
  - **ansible-collection**: General updates to coordinate the new roles and configuration.

## 1.0.6

### Patch Changes

- Updated dependencies [356cd1f]
  - ansible-role-docker@0.0.2
  - ansible-role-utils-affected-roles@0.0.2

## 1.0.5

### Patch Changes

- 00ac27d: feat: Implement changeset release workflow for Ansible

## 1.0.4

### Patch Changes

- Updated dependencies [1dc6cf5]
  - ansible-role-terraform-digitalocean@0.1.0
