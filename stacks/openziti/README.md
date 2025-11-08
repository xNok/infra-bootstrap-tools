# OpenZiti - Secure Zero-Trust Network Overlay

This directory contains multiple stack configurations for deploying OpenZiti with SPIRE (internal identity) and Keycloak (external identity) on Docker Swarm.

## Architecture Overview

The deployment consists of three separate stacks:

1. **SPIRE Stack** (`spire-stack.yml`) - Internal identity infrastructure
2. **Keycloak Stack** (`keycloak-stack.yml`) - External identity provider (OIDC)
3. **OpenZiti Stack** (`openziti-stack.yml`) - Zero-trust network overlay with SPIFFE integration

## Prerequisites

### Required Infrastructure

- Docker Swarm cluster with at least one worker node
- Rclone volume plugin installed on all nodes for persistent storage
- DigitalOcean Spaces (or compatible S3) configured for rclone
- Caddy reverse proxy network (`caddy_caddy`) for external access

### Required Secrets

Before deploying, create the following Docker secrets:

```bash
# Ziti admin credentials
echo "admin" | docker secret create ziti_admin_user -
echo "your-secure-password" | docker secret create ziti_admin_password -

# Keycloak database credentials
echo "keycloak" | docker secret create keycloak_db_user -
echo "your-db-password" | docker secret create keycloak_db_password -

# Keycloak admin credentials
echo "admin" | docker secret create keycloak_admin_user -
echo "your-keycloak-admin-password" | docker secret create keycloak_admin_password -
```

### Rclone Configuration

Configure rclone for DigitalOcean Spaces (or your S3-compatible storage):

```bash
# Install rclone volume plugin
docker plugin install rclone/docker-volume-rclone:amd64 \
  args="-v" \
  --grant-all-permissions

# Configure rclone with your DigitalOcean credentials
# The remote name should be "digitalocean" to match the stack configurations
```

## Deployment

### 1. Deploy SPIRE Stack (Internal Identity)

```bash
docker stack deploy -c spire-stack.yml spire
```

This deploys:
- SPIRE Server: Central CA and identity registry
- SPIRE Agent: Global service (one per node) for workload attestation

Wait for SPIRE to be healthy:
```bash
docker service ls | grep spire
```

### 2. Deploy Keycloak Stack (External Identity)

```bash
# Set environment variables
export KEYCLOAK_HOSTNAME=keycloak.example.com

docker stack deploy -c keycloak-stack.yml keycloak
```

This deploys:
- PostgreSQL: Database for Keycloak
- Keycloak: OIDC provider for user authentication

Wait for Keycloak to be ready:
```bash
docker service logs keycloak_keycloak
```

Access Keycloak at `https://keycloak.example.com` and:
1. Login with admin credentials
2. Create a new realm (e.g., `openziti`)
3. Create a client for OpenZiti (e.g., `openziti-client`)
4. Configure client settings and obtain JWKS endpoint

### 3. Deploy OpenZiti Stack (Networking)

```bash
# Set environment variables
export ZITI_IMAGE=openziti/ziti-controller
export ZITI_VERSION=latest
export ZITI_CTRL_NAME=ziti-controller
export ZITI_CTRL_ADVERTISED_ADDRESS=ziti-controller.example.com
export ZITI_CTRL_EDGE_ADVERTISED_ADDRESS=ziti-edge-controller.example.com
export ZITI_CTRL_EDGE_ADVERTISED_PORT=1280
export ZITI_ROUTER_NAME=ziti-edge-router
export ZITI_CONSOLE_HOSTNAME=ziti-console.example.com
export KEYCLOAK_URL=https://keycloak.example.com
export KEYCLOAK_REALM=openziti
export TRUST_DOMAIN=openziti.local

docker stack deploy -c openziti-stack.yml openziti
```

This deploys:
- Ziti Controller: The brain of the Ziti network
- Ziti Console: Web UI for management
- Ziti Edge Router: Network data plane with SPIFFE auto-enrollment
- SPIFFE Helper: Sidecar for obtaining SVIDs from SPIRE
- Bootstrap: Automated configuration service

### 4. Verify Deployment

Check all services are running:
```bash
docker stack ps spire --no-trunc
docker stack ps keycloak --no-trunc
docker stack ps openziti --no-trunc
```

Check bootstrap logs:
```bash
docker service logs openziti_bootstrap
```

The bootstrap service will:
1. Wait for Ziti Controller and SPIRE Server
2. Log in to Ziti Controller
3. Register Ziti router workload in SPIRE
4. Configure Keycloak OIDC in Ziti
5. Bind SPIRE CA to Ziti
6. Create default policies

## Volume Management

All persistent data is stored using the rclone volume driver, which syncs to DigitalOcean Spaces:

- `ziti-controller-data`: Controller PKI and database
- `spire-server-data`: SPIRE server data and trust bundles
- `keycloak-db-data`: Keycloak PostgreSQL database

Data is automatically synchronized to object storage, preventing data loss in a Docker Swarm environment.

## Configuration Files

### SPIRE Configuration

- `config/spire/server.conf`: SPIRE server configuration
- `config/spire/agent.conf`: SPIRE agent configuration

### SPIFFE Helper Configuration

- `config/spiffe/helper.conf`: SPIFFE helper configuration for certificate management

### Bootstrap Service

- `bootstrap/Dockerfile`: Bootstrap image with Ziti CLI, SPIRE CLI, and utilities
- `bootstrap/setup.sh`: Automated configuration script

## Updating Stack Configurations

To update a running stack:

```bash
# Update configuration
vim openziti-stack.yml

# Redeploy (Docker will perform rolling update)
docker stack deploy -c openziti-stack.yml openziti
```

## Troubleshooting

### View service logs
```bash
docker service logs -f openziti_ziti-controller
docker service logs -f openziti_bootstrap
docker service logs -f spire_spire-server
docker service logs -f keycloak_keycloak
```

### Check service health
```bash
docker service ps openziti_ziti-controller --no-trunc
docker service inspect openziti_ziti-controller
```

### Access SPIRE Server
```bash
docker exec -it $(docker ps -q -f name=spire_spire-server) /bin/sh
spire-server entry show
spire-server bundle show
```

### Verify rclone volumes
```bash
docker volume ls | grep rclone
docker volume inspect ziti-controller-data
```

## Local Testing (Docker Compose)

For local development and testing, use the legacy compose file:

```bash
docker compose -f ziti.local.yaml up -d
```

Note: The local compose file uses local volumes and does not include SPIRE or Keycloak integration.

## Security Considerations

1. **Secrets Management**: All sensitive credentials are stored as Docker secrets
2. **Network Isolation**: Services use overlay networks with minimal exposure
3. **TLS/mTLS**: All inter-service communication uses TLS
4. **SPIFFE/SPIRE**: Provides cryptographic workload identity
5. **Persistent Storage**: Rclone volumes ensure PKI is never lost

## Next Steps

After deployment:

1. Configure Keycloak realm with appropriate users and groups
2. Create Ziti services and identities
3. Deploy additional edge routers as needed
4. Configure service policies for zero-trust access control
5. Monitor services using Ziti Console

## References

- [OpenZiti Documentation](https://docs.openziti.io/)
- [SPIRE Documentation](https://spiffe.io/docs/latest/spire-about/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Rclone Docker Volume Plugin](https://rclone.org/docker/)

