# ansible-role-docker-swarm-manager

## 0.1.0

### Minor Changes

- af6e8d6: Standardize Docker Swarm inventory group names: rename default group from `managers` / `nodes` to `docker_swarm_managers` / `docker_swarm_nodes` to align with the Terraform provisioning roles. Fix variable reference for join-token retrieval in the node role.
