---
type: project
status: investigating
description: Zero-trust mesh networking using OpenZiti with SPIRE (internal identity) and Keycloak (external identity)
related_projects:
  - docker-swarm-env
  - k3s-migration
related_resources:
  - openziti
  - spire-spiffe
  - keycloak
  - rclone
related_areas:
  - infra-orchestration
  - security-identity
  - networking
---

# OpenZiti - Zero-Trust Network Overlay

## Overview

OpenZiti is a new initiative exploring zero-trust mesh networking as an overlay on the existing infrastructure. It integrates SPIRE for workload identity (SPIFFE), Keycloak for user authentication (OIDC), and provides secure, policy-based connectivity.

## Current State

**Status**: Investigating / Early Implementation  
**Version**: 1.0.x  
**Last Updated**: January 2025

The project has made significant progress:
- ✅ Three-stack architecture designed (SPIRE, Keycloak, OpenZiti)
- ✅ Production-ready Docker Swarm deployment
- ✅ Comprehensive architecture documentation
- ✅ Local development setup
- ✅ Automated bootstrap service for initial configuration
- 🔄 Testing and validation in progress
- 🔄 Production deployment pending

## Key Files and Directories

### Stack Configuration
```
stacks/openziti/
├── spire-stack.yml          # SPIRE Server & Agent (internal identity)
├── spire-stack.local.yaml   # Local development
├── keycloak-stack.yml       # Keycloak & PostgreSQL (external identity)
├── keycloak-stack.local.yaml
├── openziti-stack.yml       # Ziti Controller, Router, Console, Bootstrap
├── openziti-stack.local.yaml
├── config/                  # Configuration files
│   ├── spire-server.conf   # SPIRE server configuration
│   ├── spire-agent.conf    # SPIRE agent configuration
│   └── spiffe-helper.conf  # SPIFFE helper for auto-enrollment
├── bootstrap/              # Bootstrap service
│   ├── Dockerfile
│   └── bootstrap.sh        # Initialization script
├── docs/
│   ├── ARCHITECTURE.md     # Detailed architecture
│   └── QUICKSTART.md       # Deployment guide
├── .env.example            # Environment template
├── README.md               # Overview and quick start
├── CHANGELOG.md
└── package.json
```

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Docker Swarm Cluster                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                     SPIRE Stack                           │  │
│  │  ┌─────────────────┐      ┌────────────────────────────┐ │  │
│  │  │  SPIRE Server   │      │   SPIRE Agent (Global)      │ │  │
│  │  │  - CA Registry  │◄─────┤   - Per-node deployment    │ │  │
│  │  │  - SVID Issuer  │      │   - Workload attestation   │ │  │
│  │  └─────────────────┘      │   - Unix socket: /run/spire│ │  │
│  │         │ (rclone volume)  └────────────────────────────┘ │  │
│  │         ▼                                                   │  │
│  │  [DigitalOcean Spaces]                                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   Keycloak Stack                          │  │
│  │  ┌─────────────────┐      ┌──────────────────────────┐  │  │
│  │  │   PostgreSQL    │◄─────┤      Keycloak            │  │  │
│  │  │   - Realm DB    │      │  - OIDC Provider         │  │  │
│  │  └─────────────────┘      │  - User Management       │  │  │
│  │         │ (rclone volume)  │  - JWT Issuer            │  │  │
│  │         ▼                  └──────────────────────────┘  │  │
│  │  [DigitalOcean Spaces]              │ (via Caddy)         │  │
│  └─────────────────────────────────────┼──────────────────────┘  │
│                                         │                        │
│  ┌─────────────────────────────────────┼──────────────────────┐  │
│  │                  OpenZiti Stack     │                      │  │
│  │                                      ▼                      │  │
│  │  ┌──────────────────────────────────────────────────────┐ │  │
│  │  │              Ziti Controller                         │ │  │
│  │  │  - Network Control Plane                             │ │  │
│  │  │  - PKI Management                                    │ │  │
│  │  │  - Policy Engine                                     │ │  │
│  │  │  - Keycloak Integration (OIDC)                       │ │  │
│  │  │  - SPIRE CA Integration                              │ │  │
│  │  └──────────────────────────────────────────────────────┘ │  │
│  │         │ (rclone volume)                                  │  │
│  │         ▼                                                   │  │
│  │  [DigitalOcean Spaces]                                     │  │
│  │                                                              │  │
│  │  ┌──────────────────┐  ┌─────────────────┐  ┌──────────┐ │  │
│  │  │  Ziti Console    │  │  Ziti Router    │  │ SPIFFE   │ │  │
│  │  │  - Web UI        │  │  - Data Plane   │◄─┤ Helper   │ │  │
│  │  │  (via Caddy)     │  │  - Auto-enroll  │  │ - SVID   │ │  │
│  │  └──────────────────┘  └─────────────────┘  └──────────┘ │  │
│  │                                                              │  │
│  │  ┌──────────────────────────────────────────────────────┐ │  │
│  │  │              Bootstrap Service                        │ │  │
│  │  │  - SPIRE workload registration                        │ │  │
│  │  │  - Keycloak OIDC configuration                        │ │  │
│  │  │  - CA binding & verification                          │ │  │
│  │  │  - Default policies                                   │ │  │
│  │  └──────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Three-Stack Design

The deployment is intentionally separated into three stacks for modularity and maintainability:

1. **SPIRE Stack** - Foundation layer for workload identity
   - SPIRE Server: CA and SVID issuer
   - SPIRE Agent: Per-node attestation (global mode)
   - Persistent storage via rclone to DigitalOcean Spaces

2. **Keycloak Stack** - User authentication and authorization
   - Keycloak: OIDC provider
   - PostgreSQL: Realm and user database
   - Persistent storage via rclone

3. **OpenZiti Stack** - Zero-trust network overlay
   - Ziti Controller: Control plane and policy engine
   - Ziti Router: Data plane with auto-enrollment via SPIFFE
   - Ziti Console: Web UI
   - Bootstrap: Automated configuration service
   - SPIFFE Helper: SVID management for router

### Deployment Order
Must be deployed in order due to dependencies:
1. SPIRE Stack (provides identity foundation)
2. Keycloak Stack (provides user authentication)
3. OpenZiti Stack (consumes both SPIRE and Keycloak)

## Resources and Dependencies

### Core Technologies
- **OpenZiti**: Zero-trust network overlay
- **SPIRE/SPIFFE**: Workload identity and attestation
- **Keycloak**: OIDC identity provider for users
- **Rclone**: Cloud storage driver for persistent volumes
- **DigitalOcean Spaces**: Object storage backend

### Docker Swarm Dependencies
- Overlay networks: `spire`, `keycloak`, `ziti`, `caddy_caddy`
- Docker secrets for sensitive credentials
- Rclone volume plugin for persistent storage
- Caddy reverse proxy for HTTPS access

### External Dependencies
- Domain names for services (configured via env vars)
- SSL certificates (auto-managed by Caddy)
- DigitalOcean Spaces credentials (for rclone)

## Development Workflow

### Local Development
```bash
# Start each stack locally
ibt stacks run openziti spire-stack
ibt stacks run openziti keycloak-stack  
ibt stacks run openziti openziti-stack

# Or with docker compose directly
docker compose -f stacks/openziti/spire-stack.local.yaml up -d
docker compose -f stacks/openziti/keycloak-stack.local.yaml up -d
docker compose -f stacks/openziti/openziti-stack.local.yaml up -d
```

### Production Deployment
```bash
# 1. Configure environment
cp stacks/openziti/.env.example stacks/openziti/.env
# Edit .env with your domain names and settings

# 2. Create Docker secrets (see QUICKSTART.md)

# 3. Deploy stacks in order
docker stack deploy -c stacks/openziti/spire-stack.yml spire
docker stack deploy -c stacks/openziti/keycloak-stack.yml keycloak
docker stack deploy -c stacks/openziti/openziti-stack.yml openziti

# 4. Monitor bootstrap process
docker service logs -f openziti_bootstrap
```

### Troubleshooting
```bash
# Check service health
docker service ps openziti_ziti-controller --no-trunc
docker service logs -f openziti_ziti-controller
docker service logs -f spire_spire-server
docker service logs -f keycloak_keycloak

# Verify SPIRE agent
docker service logs -f spire_spire-agent

# Check bootstrap status
docker service logs -f openziti_bootstrap
```

## Identity Flow

### Workload Identity (SPIRE/SPIFFE)
1. SPIRE Agent runs on each node (global mode deployment)
2. Ziti Router connects to local SPIRE Agent via Unix socket
3. SPIFFE Helper retrieves and refreshes SVID certificates
4. Router auto-enrolls using SPIFFE identity
5. Controller validates SVID against SPIRE CA

### User Identity (Keycloak OIDC)
1. User authenticates via Keycloak web UI
2. Keycloak issues JWT token
3. Ziti Controller validates JWT using Keycloak's JWKS endpoint
4. User receives Ziti identity with policies applied

## Storage Architecture

### Persistent Data (Rclone to DigitalOcean Spaces)
1. **ziti-controller-data**: PKI, database, network config
2. **spire-server-data**: CA keys, trust bundles, registration entries
3. **keycloak-db-data**: User accounts, realm configurations

### Ephemeral Data
- SPIRE Agent data (node-local)
- SPIFFE certificates (tmpfs shared volume)

## Use Cases

### Security Enhancements
- Zero-trust networking without VPN
- Microsegmentation of services
- Policy-based access control
- End-to-end encryption

### Application Connectivity
- Secure service-to-service communication
- Remote access without exposing ports
- Multi-cloud connectivity
- Hybrid cloud networking

### Identity Management
- Workload identity via SPIFFE
- User identity via OIDC
- Short-lived credentials
- Automatic rotation

## Comparison: Local vs Production

| Feature | Local (.local.yaml) | Production (.yml) |
|---------|---------------------|-------------------|
| **Storage** | Local volumes | Rclone to Spaces |
| **Secrets** | Volume mounts | Docker secrets |
| **Nodes** | Single host | Multi-node capable |
| **Identity** | None | SPIRE + Keycloak |
| **Bootstrap** | Manual | Automated |
| **HA** | No | Possible |

## Known Issues and Limitations

### Current Limitations
- Single replica for stateful services (no HA yet)
- Manual SPIRE workload registration in some cases
- Limited production testing
- No automated backup solution
- Monitoring not fully implemented

### Security Considerations
- All secrets must be managed via Docker secrets in production
- Proper domain names and SSL certificates required
- SPIRE trust domain must be carefully planned
- Keycloak realm configuration should follow best practices

## Planned Improvements

1. **High Availability**
   - Multiple controller replicas
   - SPIRE Server HA with database backend
   - Keycloak clustering
   - Load-balanced routers

2. **Monitoring & Observability**
   - Prometheus metrics export
   - Grafana dashboards
   - Alerting rules
   - Distributed tracing

3. **Automation**
   - Automated backups
   - Self-healing capabilities
   - Dynamic policy management
   - Integration with existing tooling

4. **Documentation**
   - Production deployment checklist
   - Troubleshooting guide
   - Performance tuning guide
   - Migration guide from existing setups

5. **Integration**
   - K3s integration (future)
   - Terraform deployment
   - Ansible role for configuration
   - CI/CD pipeline examples

## Documentation Links

- [Architecture Documentation](../../stacks/openziti/docs/ARCHITECTURE.md) - Detailed design
- [Quick Start Guide](../../stacks/openziti/docs/QUICKSTART.md) - Deployment steps
- [Stack README](../../stacks/openziti/README.md) - Overview
- [OpenZiti Docs](https://docs.openziti.io/) - Official documentation
- [SPIRE Docs](https://spiffe.io/docs/latest/spire-about/) - SPIFFE/SPIRE
- [Keycloak Docs](https://www.keycloak.org/documentation) - Identity provider

## Release Management

Managed through monorepo Changeset system:
- Version in `stacks/openziti/package.json`
- Part of `infra-bootstrap-tools-stacks` releases
- Packaged in GitHub Releases
- Changelog in `stacks/openziti/CHANGELOG.md`

## Next Steps

1. **Production Testing**: Validate full deployment on Docker Swarm cluster
2. **Documentation**: Complete troubleshooting and operations guides
3. **Monitoring**: Implement metrics collection and dashboards
4. **Backup/Restore**: Automate data backup procedures
5. **HA Configuration**: Test and document high-availability setup
6. **Integration**: Connect with existing infrastructure monitoring
7. **Performance Testing**: Benchmark throughput and latency
8. **Security Audit**: Review configuration and policies
