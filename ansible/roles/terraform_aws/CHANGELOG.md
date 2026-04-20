# ansible-role-terraform-aws

## 0.1.0

### Minor Changes

- af6e8d6: Remove `diodonfrost.terraform` dependency from Terraform roles and switch to `community.general.terraform` module. Add configurable inventory group name variables (`*_inventory_managers_group` and `*_inventory_nodes_group`) defaulting to `docker_swarm_managers` / `docker_swarm_nodes`.
