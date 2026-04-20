---
"ansible-collection-infra-bootstrap-tools": minor
"ansible-role-docker-swarm-manager": minor
"ansible-role-docker-swarm-node": minor
---

Standardize Docker Swarm inventory group names: rename default group from `managers` / `nodes` to `docker_swarm_managers` / `docker_swarm_nodes` to align with the Terraform provisioning roles. Fix variable reference for join-token retrieval in the node role.
