# OpenZiti Stack Architecture

## Overview

This architecture provides a production-ready, Docker Swarm-based deployment of OpenZiti with integrated identity management through SPIRE (for workloads) and Keycloak (for users).

## Component Architecture

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
│  │         │                  └────────────────────────────┘ │  │
│  │         │ (rclone volume)                                  │  │
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
│  │         │                  │  - JWT Issuer            │  │  │
│  │         │ (rclone volume)  └──────────────────────────┘  │  │
│  │         ▼                           │                      │  │
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

## Key Differences from Local Deployment

### Local Deployment (`ziti.local.yaml`)
- Uses local Docker volumes
- Shares secrets via volume mounts (hack)
- Single-host oriented
- No identity integration
- Manual configuration

### Production Deployment (Stack files)
- Uses rclone driver for persistent storage
- Docker Swarm secrets for credentials
- Multi-node capable
- SPIRE for workload identity
- Keycloak for user identity
- Automated bootstrap configuration

## Identity Flow

### Workload Identity (SPIRE/SPIFFE)
1. SPIRE Agent runs on each node (global mode)
2. Ziti Router gets SVID from local SPIRE Agent via Unix socket
3. SPIFFE Helper retrieves and refreshes SVIDs
4. Router auto-enrolls using SPIFFE identity
5. Controller validates against SPIRE CA

### User Identity (Keycloak)
1. User authenticates via Keycloak
2. Keycloak issues JWT token
3. Ziti Controller validates JWT using Keycloak's JWKS endpoint
4. User receives Ziti identity with policies applied

## Storage Architecture

### Critical Persistent Data
All persistent data uses rclone driver syncing to DigitalOcean Spaces:

1. **Ziti Controller Data** (`ziti-controller-data`)
   - PKI certificates and keys
   - Controller database
   - Network configuration

2. **SPIRE Server Data** (`spire-server-data`)
   - CA keys and certificates
   - Trust bundles
   - Registration entries
   - SPIRE database

3. **Keycloak Database** (`keycloak-db-data`)
   - User accounts and credentials
   - Realm configurations
   - Client configurations

### Ephemeral Data
- SPIRE Agent data (node-local)
- SPIFFE certificates (tmpfs shared volume)

## Network Architecture

### Overlay Networks

1. **spire** - SPIRE server and agent communication
2. **keycloak** - Keycloak and its database
3. **ziti** - OpenZiti internal communication
4. **caddy_caddy** (external) - Public access via reverse proxy

### Service Communication

```
External Users ──► Caddy Proxy ──► Keycloak (HTTPS)
                              └──► Ziti Console (HTTPS)

Ziti Router ──► SPIRE Agent (Unix Socket) ──► SPIRE Server (TCP:8081)
            └──► Ziti Controller (TCP:6262, TCP:1280)

Bootstrap ──► Ziti Controller (HTTPS:1280)
          └──► SPIRE Server (HTTP:8081)
          └──► Keycloak (HTTPS)
```

## Deployment Order

The stack deployment follows this order:

1. **SPIRE Stack** - Provides foundational identity infrastructure
2. **Keycloak Stack** - Provides user authentication
3. **OpenZiti Stack** - Depends on both SPIRE and Keycloak

This order ensures all dependencies are available when each service starts.

## High Availability Considerations

### Current Design
- Single replica for stateful services (Controller, SPIRE Server, Keycloak)
- Global deployment for SPIRE Agent (one per node)
- Persistent storage via rclone ensures data survives node failures

### Future HA Enhancements
- Multiple Controller replicas with shared storage
- SPIRE Server HA with database backend
- Keycloak clustering
- Multiple Router replicas for load balancing

## Security Layers

1. **Transport Security**
   - All communication uses TLS/mTLS
   - Certificate-based authentication

2. **Identity Security**
   - SPIFFE cryptographic identity for workloads
   - OIDC token validation for users
   - Short-lived credentials with automatic rotation

3. **Secret Management**
   - Docker Swarm secrets for sensitive data
   - No credentials in environment variables or volumes
   - Automatic secret mounting

4. **Network Isolation**
   - Overlay networks with minimal connectivity
   - Services only join required networks
   - Zero-trust architecture via Ziti

## Monitoring & Observability

### Health Checks
All services implement health checks:
- SPIRE: `/health/ready` and `/health/live`
- Keycloak: `/health/ready`
- Ziti Controller: `/.well-known/health-check`

### Logs
Access service logs:
```bash
docker service logs -f spire_spire-server
docker service logs -f keycloak_keycloak
docker service logs -f openziti_ziti-controller
docker service logs -f openziti_bootstrap
```

### Metrics
- Keycloak: Prometheus metrics at `/metrics`
- Ziti: Built-in metrics (configure exporter)

## Scaling Considerations

### Horizontal Scaling
- Ziti Routers: Deploy additional router services
- SPIRE Agents: Automatically scales with nodes (global mode)

### Vertical Scaling
- Adjust resource limits in deployment constraints
- Increase volume sizes as needed

## Backup & Disaster Recovery

### Backup Strategy
All critical data is backed up to DigitalOcean Spaces via rclone:
- Continuous sync of changes
- Survives node failures
- Can be replicated across regions

### Recovery
1. Redeploy stacks in order (SPIRE → Keycloak → OpenZiti)
2. Rclone volumes automatically restore data
3. Services recover state from persistent storage

### RTO/RPO
- Recovery Time Objective (RTO): ~10 minutes
- Recovery Point Objective (RPO): Real-time (continuous sync)

## References

- [OpenZiti Documentation](https://docs.openziti.io/)
- [SPIFFE/SPIRE Documentation](https://spiffe.io/docs/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)
- [Rclone Documentation](https://rclone.org/docker/)
