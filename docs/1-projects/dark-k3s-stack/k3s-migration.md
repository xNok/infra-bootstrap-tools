---
type: project
status: planning
description: Upcoming exploration and migration to lightweight Kubernetes (K3s) for more complex workload orchestration
related_projects:
  - docker-swarm-env
  - openziti-mesh
related_resources: []
related_areas:
  - infra-orchestration
---

# K3s Migration

## Overview

K3s Migration is an upcoming project to explore and potentially migrate from Docker Swarm to K3s (Lightweight Kubernetes) for more complex workload orchestration. This would provide access to the broader Kubernetes ecosystem while maintaining a lightweight footprint suitable for small to medium deployments.

## Current State

**Status**: Planning / Research  
**Version**: N/A (Not yet implemented)  
**Last Updated**: January 2025

Current phase:
- 🔄 **Research**: Evaluating K3s benefits vs Docker Swarm
- 🔄 **Use Case Definition**: Identifying scenarios where K3s is beneficial
- 📋 **Planning**: Architecture design in progress
- ⏸️ **Implementation**: Not started yet

## Motivation

### Why Consider K3s?

1. **Ecosystem Access**
   - Helm charts for applications
   - Operators for complex stateful apps
   - Service meshes (Linkerd, Istio)
   - Advanced monitoring tools (Prometheus Operator)

2. **Advanced Features**
   - Custom Resource Definitions (CRDs)
   - Advanced scheduling (affinity, taints)
   - Network policies
   - Pod security policies
   - Autoscaling (HPA, VPA)

3. **Industry Standard**
   - Kubernetes skills are transferable
   - Larger community and resources
   - More third-party integrations
   - Better documentation

4. **Future-Proofing**
   - Kubernetes is industry direction
   - Docker Swarm is in maintenance mode
   - Better long-term support
   - More active development

### Why K3s Specifically?

1. **Lightweight**: Single binary, ~100MB
2. **Simple Setup**: Easy installation
3. **Low Resource**: Works on edge devices
4. **Production Ready**: Used in production by Rancher
5. **Batteries Included**: Traefik, CoreDNS, local storage
6. **Edge Friendly**: Designed for edge and IoT

## Proposed Architecture

### High-Level Design

```
┌─────────────────────────────────────────────────────────────────┐
│                    Cloud Provider / On-Prem                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                 K3s Cluster                               │  │
│  │                                                            │  │
│  │  ┌────────────────┐  ┌────────────────┐  ┌────────────┐ │  │
│  │  │  Control Plane │  │  Worker Node   │  │Worker Node │ │  │
│  │  │  (K3s Server)  │  │  (K3s Agent)   │  │(K3s Agent) │ │  │
│  │  └────────────────┘  └────────────────┘  └────────────┘ │  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────────────────────┐│  │
│  │  │         Ingress Controller (Traefik or NGINX)         ││  │
│  │  └──────────────────────────────────────────────────────┘│  │
│  │                                                            │  │
│  │  Namespace: Core                                          │  │
│  │  ├─ Cert-Manager (Let's Encrypt)                         │  │
│  │  ├─ External DNS (DNS automation)                        │  │
│  │  └─ Monitoring (Prometheus + Grafana)                    │  │
│  │                                                            │  │
│  │  Namespace: Applications                                  │  │
│  │  ├─ Helm Releases (Stateful apps)                        │  │
│  │  ├─ Custom Deployments                                    │  │
│  │  └─ Migrated Swarm Services                              │  │
│  │                                                            │  │
│  │  Namespace: Data                                          │  │
│  │  ├─ StatefulSets (Databases)                             │  │
│  │  ├─ PersistentVolumeClaims                               │  │
│  │  └─ Rook-Ceph or Longhorn (Storage)                      │  │
│  │                                                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Component Mapping: Swarm to K3s

| Docker Swarm | K3s Equivalent | Notes |
|--------------|----------------|-------|
| **Service** | Deployment + Service | K8s separates concerns |
| **Stack** | Namespace + Manifests | Or Helm chart |
| **Secret** | Secret | Similar concept |
| **Config** | ConfigMap | Native K8s resource |
| **Volume** | PersistentVolume + PVC | More sophisticated |
| **Network** | NetworkPolicy | More granular control |
| **Placement** | NodeAffinity / Taints | More flexible |
| **Caddy** | Traefik / NGINX Ingress | Built-in or Helm |
| **Portainer** | Rancher / K9s / Lens | K8s-native tools |

## Resources and Dependencies

### Infrastructure Requirements
- **Minimum Control Plane**: 2 vCPUs, 4GB RAM
- **Minimum Worker**: 1 vCPU, 2GB RAM
- **Network**: Low latency between nodes
- **Storage**: Local or distributed (Longhorn, Rook-Ceph)

### Tools and Technologies

#### Core K3s Stack
- **K3s**: Lightweight Kubernetes distribution
- **kubectl**: Command-line tool
- **Helm**: Package manager
- **k9s** or **Lens**: Interactive management

#### Deployment and IaC
- **Terraform**: Infrastructure provisioning
- **Ansible**: Configuration management
- **Flux** or **ArgoCD**: GitOps workflow
- **Helmfile**: Helm chart management

#### Storage
- **Longhorn**: Cloud-native distributed storage
- **Rook-Ceph**: Storage orchestration
- **Local Path Provisioner**: Simple local storage (included)

#### Networking
- **Traefik**: Ingress controller (included)
- **NGINX Ingress**: Alternative ingress
- **Cert-Manager**: TLS certificate management
- **External DNS**: DNS record automation

#### Monitoring
- **Prometheus Operator**: Metrics collection
- **Grafana**: Visualization
- **Loki**: Log aggregation
- **Alertmanager**: Alert routing

#### Service Mesh (Future)
- **Linkerd**: Lightweight service mesh
- **Istio**: Full-featured mesh
- **OpenZiti**: Zero-trust overlay (integration)

## Migration Strategy

### Phase 1: Proof of Concept (Current)
- [ ] Set up K3s cluster locally
- [ ] Deploy simple application
- [ ] Test ingress and storage
- [ ] Document findings
- [ ] Compare performance with Swarm

### Phase 2: Parallel Deployment
- [ ] Deploy K3s alongside Docker Swarm
- [ ] Migrate non-critical services
- [ ] Validate functionality
- [ ] Monitor performance and stability
- [ ] Document migration patterns

### Phase 3: Core Services Migration
- [ ] Migrate databases and stateful apps
- [ ] Implement backup/restore procedures
- [ ] Set up monitoring and alerting
- [ ] Establish operational procedures
- [ ] Train team on K3s operations

### Phase 4: Full Migration
- [ ] Migrate all services to K3s
- [ ] Decommission Docker Swarm
- [ ] Archive Swarm documentation
- [ ] Update all tutorials and guides
- [ ] Publish migration case study

### Phase 5: Optimization
- [ ] Implement autoscaling
- [ ] Add service mesh if needed
- [ ] Optimize resource allocation
- [ ] Enhance monitoring and observability
- [ ] Document best practices

## Comparison: Docker Swarm vs K3s

### Complexity
| Aspect | Docker Swarm | K3s |
|--------|--------------|-----|
| Setup | Very Simple | Simple |
| Operations | Simple | Moderate |
| Learning Curve | Gentle | Steeper |
| Debugging | Straightforward | More complex |

### Features
| Feature | Docker Swarm | K3s |
|---------|--------------|-----|
| Built-in LB | ✅ Yes | ✅ Yes (Traefik) |
| Rolling Updates | ✅ Yes | ✅ Yes (better) |
| Autoscaling | ❌ Limited | ✅ Advanced |
| StatefulSets | ⚠️ Via constraints | ✅ Native |
| Network Policies | ❌ No | ✅ Yes |
| Custom Resources | ❌ No | ✅ Yes |
| Service Mesh | ❌ No | ✅ Yes (add-ons) |

### Ecosystem
| Aspect | Docker Swarm | K3s |
|--------|--------------|-----|
| Community | Smaller | Larger |
| Documentation | Good | Excellent |
| Third-party Tools | Limited | Extensive |
| Helm Charts | ❌ No | ✅ Yes |
| Operators | ❌ No | ✅ Yes |

### Resource Usage
| Metric | Docker Swarm | K3s |
|--------|--------------|-----|
| Control Plane | ~200MB | ~500MB |
| Per Node | ~100MB | ~200MB |
| Disk Space | Minimal | ~500MB |
| CPU Overhead | Very Low | Low |

## Use Cases for K3s

### When K3s Makes Sense
1. **Complex Stateful Applications**: Databases requiring advanced orchestration
2. **Helm Chart Availability**: Apps with existing Helm charts
3. **Advanced Scheduling**: Need for complex placement policies
4. **Service Mesh**: Require mTLS and advanced traffic management
5. **Kubernetes Experience**: Team familiar with K8s
6. **Future Scaling**: Plan to grow beyond current infrastructure

### When to Keep Docker Swarm
1. **Simple Deployments**: Basic web services and APIs
2. **Small Team**: Limited operational capacity
3. **Resource Constrained**: Very limited hardware
4. **Working Well**: Current setup meets all needs
5. **No K8s Experience**: Team not ready for complexity

## Integration with Other Projects

### OpenZiti Integration
- K3s workloads can be OpenZiti services
- Zero-trust networking overlay
- SPIFFE/SPIRE for workload identity
- Keycloak for user authentication

### Agentic Framework Integration
- Deploy Prefect on K3s
- Kubernetes executor for workflows
- Better resource management
- Autoscaling for agent workers

### IBT CLI Integration
- `ibt k3s` subcommand for cluster management
- Helm chart deployment helpers
- Namespace and context switching
- Quick cluster setup for development

## Known Challenges

### Technical Challenges
1. **Complexity Increase**: More moving parts
2. **Learning Curve**: Team needs K8s knowledge
3. **Resource Overhead**: Higher baseline requirements
4. **Storage Complexity**: Need distributed storage solution
5. **Network Policies**: More configuration needed

### Operational Challenges
1. **Monitoring**: More components to monitor
2. **Troubleshooting**: Deeper debugging required
3. **Backup/Restore**: More complex procedures
4. **Upgrades**: K3s upgrades require planning
5. **Documentation**: Need to update all guides

### Migration Risks
1. **Downtime**: Service interruption during migration
2. **Data Loss**: Risk during database migration
3. **Configuration Drift**: Settings may not translate directly
4. **Performance**: Initial performance tuning needed
5. **Rollback Complexity**: Harder to revert to Swarm

## Planned Improvements

### Short Term (Research Phase)
1. **Local K3s Cluster**: Set up development cluster
2. **Sample Migrations**: Migrate 2-3 services
3. **Documentation**: Create K3s setup guide
4. **Performance Testing**: Benchmark against Swarm
5. **Cost Analysis**: Compare resource usage

### Medium Term (Pilot)
1. **Terraform Modules**: K3s infrastructure provisioning
2. **Ansible Roles**: K3s installation and configuration
3. **Helm Charts**: Package key applications
4. **GitOps Setup**: Flux or ArgoCD deployment
5. **Monitoring Stack**: Prometheus + Grafana

### Long Term (Production)
1. **Complete Migration**: All services on K3s
2. **High Availability**: Multi-master setup
3. **Disaster Recovery**: Backup and restore automation
4. **Advanced Features**: Service mesh, autoscaling
5. **Documentation Website**: K3s-focused tutorials

## Documentation Links

### External Resources
- [K3s Official Documentation](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Longhorn Storage](https://longhorn.io/docs/)
- [Cert-Manager](https://cert-manager.io/docs/)

### Internal Documentation (To Be Created)
- K3s Setup Guide
- Migration Playbook
- Helm Chart Templates
- Operations Manual
- Troubleshooting Guide

## Decision Criteria

### Go/No-Go Decision Factors

**Proceed with K3s if:**
- ✅ Team ready for K8s learning curve
- ✅ Use cases requiring K8s features identified
- ✅ Resources available for migration effort
- ✅ PoC demonstrates clear benefits
- ✅ Community/ecosystem access is valuable

**Stay with Docker Swarm if:**
- ✅ Current solution meets all needs
- ✅ Team capacity is limited
- ✅ Infrastructure is resource-constrained
- ✅ Complexity increase not justified
- ✅ Migration costs outweigh benefits

## Next Steps

1. **Research Completion**: Finish K3s evaluation (Q1 2025)
2. **PoC Deployment**: Set up local K3s cluster
3. **Migration Test**: Migrate one non-critical service
4. **Decision Point**: Go/No-Go based on PoC results
5. **Documentation**: Create initial setup guides
6. **Team Training**: K8s/K3s workshops if proceeding
7. **Roadmap Update**: Plan migration timeline if approved
