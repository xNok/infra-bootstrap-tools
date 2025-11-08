# docker-stack-openziti

## Unreleased

### Major Changes

- Added SPIRE stack for internal workload identity
  - SPIRE server with persistent storage using rclone driver
  - SPIRE agent deployed globally (one per node)
  - Docker-based workload attestation
  
- Added Keycloak stack for external identity (OIDC)
  - Keycloak service with PostgreSQL database
  - Docker secrets integration for credentials
  - Persistent storage using rclone driver
  
- Enhanced OpenZiti stack for Docker Swarm deployment
  - Replaced local volumes with rclone driver for DigitalOcean Spaces
  - Added SPIFFE helper sidecar for router auto-enrollment
  - Integrated with SPIRE and Keycloak networks
  - Added bootstrap service for automated configuration
  
- Added bootstrap service
  - Custom Docker image with Ziti CLI and SPIRE CLI
  - Automated configuration script for initial setup
  - SPIRE workload registration
  - Keycloak OIDC integration
  - SPIRE CA binding to Ziti

### Documentation

- Comprehensive README with deployment instructions
- Environment variable examples (.env.example)
- Configuration file templates for SPIRE and SPIFFE helper

## 0.0.2

### Patch Changes

- 5eff9e4: Initial versioning for stacks

  Experimenting with [changesets](https://github.com/changesets/changesets), adding versioning to pretty much everything
