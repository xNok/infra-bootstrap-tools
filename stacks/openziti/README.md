# OpenZiti - Secure Zero-Trust Network Overlay

This directory contains multiple stack configurations for deploying OpenZiti with SPIRE (internal identity) and Keycloak (external identity) on Docker Swarm.

## Quick Start

### Local Development

For quick local testing with Docker Compose:

```bash
# Using ibt helper (recommended)
ibt stacks run openziti spire-stack
ibt stacks run openziti keycloak-stack
ibt stacks run openziti openziti-stack

# Or using docker compose directly
# Create required secrets first
cp stacks/openziti/secrets/ziti_admin_password.example stacks/openziti/secrets/ziti_admin_password

docker compose -f spire-stack.local.yaml up -d
docker compose -f keycloak-stack.local.yaml up -d
docker compose -f openziti-stack.local.yaml up -d
```

### Production Deployment

For Docker Swarm deployment with full documentation, see:
- **[Deployment Guide](docs/QUICKSTART.md)** - Step-by-step deployment instructions
- **[Architecture](docs/ARCHITECTURE.md)** - Detailed architecture and design

## Stack Overview

The deployment consists of three separate stacks:

1. **SPIRE Stack** (`spire-stack.yml` / `.local.yaml`) - Internal identity infrastructure
2. **Keycloak Stack** (`keycloak-stack.yml` / `.local.yaml`) - External identity provider (OIDC)
3. **OpenZiti Stack** (`openziti-stack.yml` / `.local.yaml`) - Zero-trust network overlay with SPIFFE integration

## Key Features

- **Persistent Storage**: Rclone driver syncing to DigitalOcean Spaces (production) or local volumes (development)
- **Internal Identity**: SPIRE provides cryptographic workload identity via SPIFFE
- **External Identity**: Keycloak provides OIDC for human users
- **Auto-enrollment**: SPIFFE helper enables automatic router enrollment
- **Secret Management**: Docker secrets for all sensitive credentials (production)
- **Production Ready**: Health checks, restart policies, and proper dependencies

## Files

- `*.yml` - Production Docker Swarm stack files (with rclone volumes and secrets)
- `*.local.yaml` - Local development Docker Compose files
- `config/` - Configuration files for SPIRE and SPIFFE helper
- `bootstrap/` - Bootstrap service Docker image and scripts
- `docs/` - Comprehensive documentation
- `.env.example` - Environment variable template

## Production Deployment

For full production deployment on Docker Swarm:

1. Read the [Quick Start Guide](docs/QUICKSTART.md)
2. Review the [Architecture Documentation](docs/ARCHITECTURE.md)
3. Configure environment variables (see `.env.example`)
4. Create required Docker secrets
5. Deploy stacks in order: SPIRE → Keycloak → OpenZiti

## Configuration

Copy and customize the environment file:

```bash
cp .env.example .env
# Edit .env with your domain names and configuration
```

See [docs/QUICKSTART.md](docs/QUICKSTART.md) for detailed configuration instructions.

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

For more troubleshooting guidance, see [docs/QUICKSTART.md](docs/QUICKSTART.md).

## References

- [OpenZiti Documentation](https://docs.openziti.io/)
- [SPIRE Documentation](https://spiffe.io/docs/latest/spire-about/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Rclone Docker Volume Plugin](https://rclone.org/docker/)


