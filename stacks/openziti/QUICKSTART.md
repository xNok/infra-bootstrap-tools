# OpenZiti + SPIRE + Keycloak - Quick Start Guide

This guide walks you through deploying the complete OpenZiti stack with SPIRE and Keycloak on Docker Swarm.

## Prerequisites Checklist

- [ ] Docker Swarm initialized (`docker swarm init`)
- [ ] At least one worker node
- [ ] Rclone volume plugin installed
- [ ] DigitalOcean Spaces (or S3) configured
- [ ] Caddy reverse proxy deployed with `caddy_caddy` network

## Step 1: Install Rclone Plugin

```bash
# Install the plugin
docker plugin install rclone/docker-volume-rclone:amd64 \
  args="-v" \
  --grant-all-permissions

# Verify installation
docker plugin ls
```

## Step 2: Create Docker Secrets

```bash
# Navigate to the openziti directory
cd stacks/openziti

# Create secrets
echo "admin" | docker secret create ziti_admin_user -
openssl rand -base64 32 | docker secret create ziti_admin_password -

echo "keycloak" | docker secret create keycloak_db_user -
openssl rand -base64 32 | docker secret create keycloak_db_password -

echo "admin" | docker secret create keycloak_admin_user -
openssl rand -base64 32 | docker secret create keycloak_admin_password -

# Verify secrets
docker secret ls
```

## Step 3: Configure Environment

```bash
# Copy the example environment file
cp .env.example .env

# Edit with your domain names
nano .env

# Update these critical values:
# - ZITI_CTRL_ADVERTISED_ADDRESS
# - ZITI_CTRL_EDGE_ADVERTISED_ADDRESS
# - ZITI_CONSOLE_HOSTNAME
# - KEYCLOAK_HOSTNAME
# - KEYCLOAK_URL
# - DOMAIN_NAME
```

## Step 4: Deploy SPIRE Stack

```bash
# Deploy SPIRE
docker stack deploy -c spire-stack.yml spire

# Wait for services to be ready (1-2 minutes)
watch docker stack ps spire

# Check logs
docker service logs -f spire_spire-server
docker service logs -f spire_spire-agent
```

## Step 5: Deploy Keycloak Stack

```bash
# Source environment variables
source .env

# Deploy Keycloak
docker stack deploy -c keycloak-stack.yml keycloak

# Wait for services to be ready (2-3 minutes)
watch docker stack ps keycloak

# Check logs
docker service logs -f keycloak_keycloak
```

## Step 6: Configure Keycloak

1. Access Keycloak at `https://keycloak.example.com`
2. Login with admin credentials (from secret)
3. Create a new realm: `openziti`
4. Create a client:
   - Client ID: `openziti-client`
   - Client Protocol: `openid-connect`
   - Access Type: `confidential`
   - Valid Redirect URIs: `https://ziti-edge-controller.example.com/*`
5. Note the JWKS endpoint: `https://keycloak.example.com/realms/openziti/protocol/openid-connect/certs`

## Step 7: Build Bootstrap Image (Optional)

If you're not using a pre-built image:

```bash
# Build the bootstrap image
docker compose -f bootstrap-build.yml build

# Tag and push to your registry
docker tag openziti/ziti-bootstrap:latest your-registry/ziti-bootstrap:latest
docker push your-registry/ziti-bootstrap:latest
```

## Step 8: Deploy OpenZiti Stack

```bash
# Source environment variables
source .env

# Deploy OpenZiti
docker stack deploy -c openziti-stack.yml openziti

# Wait for services to be ready (2-3 minutes)
watch docker stack ps openziti

# Check bootstrap logs for configuration progress
docker service logs -f openziti_bootstrap
```

## Step 9: Verify Deployment

```bash
# Check all stacks
docker stack ls

# Check all services are running
docker service ls

# View controller logs
docker service logs openziti_ziti-controller

# Access Ziti Console
# Navigate to https://ziti-console.example.com
```

## Step 10: Post-Deployment Configuration

### Create Test Identity

```bash
# Execute in the controller container
docker exec -it $(docker ps -q -f name=openziti_ziti-controller) /bin/bash

# Inside container
ziti edge login ziti-controller:1280 -u admin -p <password>
ziti edge create identity device test-device -o test-device.jwt
```

### Create Test Service

```bash
ziti edge create service test-service
ziti edge create service-policy test-dial-policy Dial --service-roles "@test-service" --identity-roles "#all"
ziti edge create service-policy test-bind-policy Bind --service-roles "@test-service" --identity-roles "#all"
```

## Troubleshooting

### Services Not Starting

```bash
# Check service status
docker service ps <service-name> --no-trunc

# Check logs
docker service logs <service-name>

# Inspect service
docker service inspect <service-name>
```

### Rclone Volume Issues

```bash
# List volumes
docker volume ls | grep rclone

# Inspect volume
docker volume inspect ziti-controller-data

# Check rclone plugin logs
docker plugin disable rclone/docker-volume-rclone:amd64
docker plugin enable rclone/docker-volume-rclone:amd64
```

### SPIRE Issues

```bash
# Check SPIRE server entries
docker exec -it $(docker ps -q -f name=spire_spire-server) /bin/sh
spire-server entry show
spire-server bundle show

# Check SPIRE agent status
docker exec -it $(docker ps -q -f name=spire_spire-agent) /bin/sh
spire-agent healthcheck
```

### Bootstrap Failures

```bash
# View detailed bootstrap logs
docker service logs --raw openziti_bootstrap

# Manually run bootstrap steps
docker exec -it $(docker ps -q -f name=openziti_bootstrap) /bin/bash
```

## Updating Stacks

To update a running stack:

```bash
# Edit the stack file
vim openziti-stack.yml

# Redeploy (rolling update)
docker stack deploy -c openziti-stack.yml openziti
```

## Cleanup

To remove all stacks:

```bash
docker stack rm openziti
docker stack rm keycloak
docker stack rm spire

# Remove volumes (WARNING: This deletes all data)
docker volume rm ziti-controller-data
docker volume rm spire-server-data
docker volume rm keycloak-db-data
```

## Next Steps

- Configure additional edge routers
- Set up service-specific policies
- Integrate applications with Ziti SDK
- Configure monitoring and alerting
- Set up backup for rclone volumes

## Support

For issues and questions:
- OpenZiti: https://openziti.discourse.group/
- SPIRE: https://github.com/spiffe/spire/discussions
- Keycloak: https://github.com/keycloak/keycloak/discussions
