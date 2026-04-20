---
"ansible-collection-infra-bootstrap-tools": minor
"ansible-role-terraform-aws": minor
"ansible-role-terraform-digitalocean": minor
"ansible-role-terraform-gcp": minor
---

Remove `diodonfrost.terraform` dependency from Terraform roles and switch to `community.general.terraform` module. Add configurable inventory group name variables (`*_inventory_managers_group` and `*_inventory_nodes_group`) defaulting to `docker_swarm_managers` / `docker_swarm_nodes`.
