---
type: project
status: active
description: Current infrastructure orchestration layer managing Docker Swarm with Caddy, Portainer, and various stacks
related_projects:
  - ibt-cli-tool
  - openziti-mesh
  - k3s-migration
  - agentic-framework
  - n8n-workflows
related_resources:
  - docker
  - docker-swarm
  - caddy
  - portainer
  - ansible
  - terraform
related_areas:
  - infra-orchestration
  - deployment-automation
---

# Docker Swarm Environment

## Overview

The Docker Swarm Environment is the current production infrastructure orchestration layer for the infra-bootstrap-tools project. It provides a complete, production-ready setup for running self-hosted applications with automated HTTPS, container management, and GitOps workflows.

## Current State

**Status**: Active / Production  
**Version**: 1.0.x  
**Last Updated**: January 2025

This is the **current standard** for infrastructure orchestration in the project:
- ✅ Fully implemented and battle-tested
- ✅ Ansible roles for automated deployment
- ✅ Terraform integration for infrastructure provisioning
- ✅ Published as Ansible Galaxy collection
- ✅ Comprehensive documentation and tutorials
- ✅ GitHub Actions CI/CD workflows
- ✅ Production deployments in use

## Key Files and Directories

### Ansible Roles
```
ansible/
├── playbooks/              # Main playbooks
│   ├── all.yml            # Complete infrastructure setup
│   ├── docker.yml         # Docker installation
│   └── swarm.yml          # Swarm cluster setup
├── roles/
│   ├── docker/                        # Docker installation and config
│   ├── docker_swarm_controller/       # Initialize Swarm cluster
│   ├── docker_swarm_manager/          # Add manager nodes
│   ├── docker_swarm_node/             # Add worker nodes
│   ├── docker_swarm_app_caddy/        # Deploy Caddy reverse proxy
│   ├── docker_swarm_app_portainer/    # Deploy Portainer
│   ├── docker_swarm_plugin_rclone/    # Rclone volume plugin
│   └── utils_*/                       # Utility roles
├── galaxy.yml              # Ansible Galaxy collection metadata
├── README.md
├── CHANGELOG.md
└── package.json
```

### Terraform Configurations
```
terraform/
├── terraform-aws-instance/       # AWS VM provisioning
└── terraform-digitalocean-*/     # DigitalOcean infrastructure
```

### Stack Definitions
```
stacks/
├── caddy/                  # Caddy configurations
├── portainer/              # Portainer setup
├── n8n/                    # n8n workflow automation
├── prefect/                # Prefect orchestration
└── openziti/               # OpenZiti networking
```

### Documentation
```
website/content/en/docs/
├── gs1.getting_started.md  # Getting started guide
├── a1.caddy.md            # Caddy documentation
├── a2.portainer.md        # Portainer documentation
├── b1.ansible_concepts.md # Ansible concepts
├── b2.terraform_ansible.md # Terraform integration
└── b3.docker_swarm.md     # Docker Swarm setup
```

## Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Cloud Provider (DigitalOcean/AWS)             │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Docker Swarm Cluster                         │  │
│  │                                                            │  │
│  │  ┌────────────────┐  ┌────────────────┐  ┌────────────┐ │  │
│  │  │  Manager Node  │  │  Worker Node   │  │Worker Node │ │  │
│  │  │  (Controller)  │  │                │  │            │ │  │
│  │  └────────────────┘  └────────────────┘  └────────────┘ │  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────────────────────┐│  │
│  │  │              Overlay Network (ingress)                ││  │
│  │  └──────────────────────────────────────────────────────┘│  │
│  │                                                            │  │
│  │  Stack: Caddy (Reverse Proxy & HTTPS)                    │  │
│  │  ├─ Auto HTTPS via Let's Encrypt                         │  │
│  │  └─ Routes traffic to services                           │  │
│  │                                                            │  │
│  │  Stack: Portainer (Management UI)                         │  │
│  │  ├─ Agent on all nodes                                    │  │
│  │  ├─ Server on manager                                     │  │
│  │  └─ Web UI for cluster management                        │  │
│  │                                                            │  │
│  │  Stack: Application Stacks (n8n, Prefect, etc.)          │  │
│  │  └─ User-defined services and workloads                  │  │
│  │                                                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Core Components

1. **Docker Swarm Cluster**
   - Manager node(s): Control plane
   - Worker nodes: Workload execution
   - Built-in load balancing
   - Service discovery
   - Rolling updates

2. **Caddy Reverse Proxy**
   - Automatic HTTPS with Let's Encrypt
   - Dynamic configuration via labels
   - HTTP/2 and HTTP/3 support
   - Load balancing
   - WebSocket support

3. **Portainer Management**
   - Web-based UI for Swarm management
   - Stack deployment (GitOps)
   - Container logs and stats
   - User access control
   - Template library

4. **Rclone Volume Plugin** (optional)
   - Cloud storage integration
   - DigitalOcean Spaces
   - AWS S3
   - Multiple backends supported

## Resources and Dependencies

### Infrastructure
- **Cloud Provider**: DigitalOcean or AWS
- **Operating System**: Ubuntu/Debian (Ansible playbooks)
- **Minimum Resources**: 
  - Manager: 2 vCPUs, 2GB RAM
  - Worker: 1 vCPU, 1GB RAM

### Tools and Technologies
- **Docker**: Container runtime (v20+)
- **Docker Swarm**: Built-in orchestration
- **Ansible**: Configuration management (v2.12+)
- **Terraform**: Infrastructure provisioning (v1.0+)
- **Python**: 3.9+ for Ansible
- **Git**: Version control

### External Services
- **Domain Name**: Required for HTTPS
- **DNS Provider**: For domain configuration
- **1Password CLI**: Optional secret management
- **GitHub**: CI/CD and GitOps

## Deployment Workflow

### Quick Start (Complete Setup)

```bash
# 1. Set up local environment
source ./bin/bash/ibt.sh
ibt setup ansible pre-commit

# 2. Configure secrets (1Password or manual)
# See website/content/en/docs/gs1.getting_started.md

# 3. Deploy entire infrastructure
make up
```

This single command will:
1. Provision VMs with Terraform
2. Install Docker on all hosts
3. Initialize Docker Swarm cluster
4. Deploy Caddy and Portainer
5. Configure HTTPS and DNS

### Step-by-Step Deployment

#### 1. Provision Infrastructure (Terraform)
```bash
cd terraform/terraform-digitalocean-*
terraform init
terraform plan
terraform apply
```

#### 2. Install Docker (Ansible)
```bash
ansible-playbook ansible/playbooks/docker.yml
```

#### 3. Initialize Swarm Cluster (Ansible)
```bash
ansible-playbook ansible/playbooks/swarm.yml
```

#### 4. Deploy Core Services
```bash
# Caddy reverse proxy
ansible-playbook ansible/playbooks/caddy.yml

# Portainer management UI
ansible-playbook ansible/playbooks/portainer.yml
```

#### 5. Deploy Application Stacks
Via Portainer UI or `docker stack deploy`:
```bash
docker stack deploy -c stacks/n8n/n8n.yaml n8n
```

### Teardown
```bash
make down
```

## Ansible Roles

### Core Infrastructure Roles

#### docker
Installs and configures Docker on target hosts.
- Adds Docker repository
- Installs Docker packages
- Configures Docker daemon
- Adds users to docker group

#### docker_swarm_controller
Initializes a new Docker Swarm cluster.
- Creates first manager node
- Generates join tokens
- Configures advertise address
- Saves cluster state

#### docker_swarm_manager
Joins nodes as Swarm managers.
- Uses manager join token
- Configures raft consensus
- Enables redundancy

#### docker_swarm_node
Joins nodes as Swarm workers.
- Uses worker join token
- Configures node labels
- Sets resource constraints

### Application Roles

#### docker_swarm_app_caddy
Deploys Caddy as a Swarm service.
- Automatic HTTPS configuration
- Dynamic service discovery
- Label-based routing
- Health checks

#### docker_swarm_app_portainer
Deploys Portainer for cluster management.
- Agent on all nodes
- Server on manager
- Persistent storage
- GitOps integration

#### docker_swarm_plugin_rclone
Installs Rclone volume plugin.
- Cloud storage integration
- Multiple backend support
- Per-volume configuration

### Utility Roles

#### utils_affected_roles
Determines which roles changed in CI.
- Optimizes CI runtime
- Selective role execution
- Git diff analysis

#### utils_rotate_docker_configs
Rotates Docker Swarm configs.
- Zero-downtime updates
- Automatic rollback on failure
- Config versioning

#### utils_rotate_docker_secrets
Rotates Docker Swarm secrets.
- Secure secret management
- Coordinated updates
- Rollback capability

#### utils_ssh_add
Sets up SSH agent for Ansible.
- Dynamic key loading
- Secure key handling
- Agent management

## CI/CD Integration

### GitHub Actions Workflows

1. **Ansible Linting** - Validates playbook syntax
2. **Role Testing** - Tests individual roles
3. **Affected Roles** - Only runs tests for changed roles
4. **Ansible Galaxy Publish** - Publishes collection on release

### Optimization: Affected Roles
Only run playbooks for roles that have changed:
- Speeds up CI/CD by 70%+
- Reduces cloud costs
- Faster feedback loops
- Documented in blog post

## Use Cases

### Small Self-Hosted Projects
- Personal websites and blogs
- Development environments
- Testing infrastructure
- Learning platform

### Homelab Setup
- Home automation
- Media servers
- Network services
- Experimentation

### Small Business Infrastructure
- Internal applications
- Customer-facing services
- Data processing
- Monitoring and alerting

## Comparison with K3s (Future)

| Feature | Docker Swarm | K3s (Future) |
|---------|--------------|--------------|
| **Complexity** | Simple | Moderate |
| **Resource Usage** | Low | Low-Medium |
| **Learning Curve** | Gentle | Steeper |
| **Ecosystem** | Docker-native | Kubernetes |
| **HA Setup** | Simple | Complex |
| **Best For** | Small deployments | Complex apps |

## Known Issues and Limitations

### Current Limitations
- No built-in secrets rotation (manual or via utils roles)
- Limited autoscaling capabilities
- No built-in service mesh
- Manual certificate management for non-standard domains
- Single registry support per stack

### Migration Considerations
- K3s migration planned for future
- OpenZiti can overlay on existing infrastructure
- Gradual migration path possible

## Planned Improvements

1. **Enhanced Automation**
   - Automated backup/restore for volumes
   - Health check automation
   - Auto-scaling policies
   - Disaster recovery procedures

2. **Monitoring & Observability**
   - Prometheus + Grafana stack
   - Log aggregation
   - Alerting rules
   - Performance metrics

3. **Security Enhancements**
   - Automated security scanning
   - Vulnerability patching
   - Enhanced access controls
   - Audit logging

4. **Integration Improvements**
   - Better Terraform modules
   - More Ansible roles
   - Additional cloud providers
   - GitOps workflows

## Documentation Links

- [Getting Started Guide](../../website/content/en/docs/gs1.getting_started.md)
- [Ansible Concepts](../../website/content/en/docs/b1.ansible_concepts.md)
- [Docker Swarm Setup](../../website/content/en/docs/b3.docker_swarm.md)
- [Caddy Documentation](../../website/content/en/docs/a1.caddy.md)
- [Portainer Documentation](../../website/content/en/docs/a2.portainer.md)
- [Terraform + Ansible](../../website/content/en/docs/b2.terraform_ansible.md)
- [Ansible Collection README](../../ansible/README.md)

### Blog Posts / Tutorials
- [Homelab Docker Swarm](../../website/content/en/blog/homelab-docker-swarm.md)
- [Automating SSL with Caddy](../../website/content/en/blog/automating-ssl-caddy.md)
- [Ansible PR Optimization](../../website/content/en/blog/ansible-pr-optimization.md)
- [Getting Started with IaC](../../website/content/en/blog/getting-started-with-iac.md)

## Release Management

### Ansible Collection
- **Name**: `xnok.infra_bootstrap_tools`
- **Published**: Ansible Galaxy
- **Version**: Managed via Changesets
- **Install**: `ansible-galaxy collection install xnok.infra_bootstrap_tools`

### Versioning
- Root version in `package.json` (v1.0.0)
- Individual role versions in their `package.json`
- Git tags: `v*` (e.g., `v1.0.0`)
- Changelog in `ansible/CHANGELOG.md`

## Next Steps

1. **Production Hardening**: Complete security audit and hardening guide
2. **Monitoring Stack**: Deploy Prometheus/Grafana as default stack
3. **Backup Automation**: Automated backup solution for critical data
4. **Multi-Cloud**: Extend Terraform modules for GCP and Azure
5. **Migration Path**: Document migration to K3s for complex workloads
6. **Video Tutorials**: Create video series for common use cases
7. **Template Library**: Expand Portainer template collection
