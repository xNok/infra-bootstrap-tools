---
"docker-stack-openziti": minor
---

Add Keycloak and SPIRE stacks for Docker Swarm deployment with rclone persistence

**New Stacks:**
- `spire-stack.yml` - SPIRE server with rclone-backed storage, global agents
- `keycloak-stack.yml` - OIDC provider with PostgreSQL, externalized secrets
- `openziti-stack.yml` - Enhanced OpenZiti with SPIFFE auto-enrollment

**Local Development:**
- `.local.yaml` variants for all stacks for quick testing with `ibt stacks run`

**Bootstrap Service:**
- Custom Docker image published to GitHub Container Registry
- Automated SPIRE registration, Keycloak OIDC, and CA binding

**Key Features:**
- Persistent storage via rclone driver syncing to DigitalOcean Spaces
- SPIRE provides cryptographic workload identity
- Keycloak provides external OIDC for human users
- All credentials moved to Docker Swarm secrets
- Comprehensive documentation in `docs/` folder
