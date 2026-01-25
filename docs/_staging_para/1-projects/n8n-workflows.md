---
type: project
status: active
description: AI-powered workflow automation using n8n for a low-code/no-code approach
related_projects:
  - agentic-framework
  - docker-swarm-env
related_resources:
  - n8n
  - mcp-hub
  - docker-compose
related_areas:
  - ai-workflow-automation
  - infra-orchestration
---

# Agentic No-Code (n8n Workflows)

## Overview

The n8n Workflows project provides a low-code/no-code alternative to Python-based workflow automation. It leverages n8n's visual workflow builder with MCP Hub integration for AI-powered automation.

## Current State

**Status**: Active  
**Version**: 1.0.x  
**Last Updated**: January 2025

This is an alternative approach to the Python-based Agentic Framework, offering:
- Visual workflow design
- Lower barrier to entry for non-programmers
- Integration with MCP Hub for AI capabilities
- Quick experimentation and prototyping

## Key Files and Directories

### Stack Configuration
```
stacks/n8n/
├── n8n.local.yaml          # Local development configuration
├── mcp-hub.local.yaml      # MCP Hub integration
├── n8n.yaml                # Production Docker Swarm stack
├── README.md               # Basic setup guide
├── CHANGELOG.md            # Version history
└── package.json            # NPM package metadata
```

### Configuration Files
- **Docker Compose**: Local development with `docker compose`
- **Swarm Stack**: Production deployment on Docker Swarm
- **MCP Integration**: Shared MCP Hub configuration

## Architecture

```
┌─────────────────┐      ┌──────────────┐      ┌─────────────┐
│   n8n Workflow  │─────▶│   MCP Hub    │─────▶│  AI Services│
│   (Visual UI)   │      │              │      │  & APIs     │
│                 │      │ - MCP Servers│      │             │
└─────────────────┘      │ - Tool Proxy │      └─────────────┘
                         └──────────────┘
```

### Components

1. **n8n Server**
   - Visual workflow builder
   - Node-based automation
   - HTTP API endpoints
   - Webhook triggers
   - Schedule-based execution

2. **MCP Hub Integration**
   - Centralized tool management
   - AI service connectivity
   - Custom MCP servers
   - Authentication handling

## Resources and Dependencies

### Core Services
- **n8n**: Workflow automation platform
- **MCP Hub**: Model Context Protocol hub (port 3000)
- **Docker**: Container runtime

### Authentication
- HTTP Basic Auth or OAuth for n8n UI
- MCP Hub dashboard password (htpasswd encrypted)
- API credentials for MCP servers

### Port Mappings
- n8n UI: Port 5678 (configurable)
- MCP Hub: Port 3000
- Webhook endpoints: Configurable

## Development Workflow

### Local Development

```bash
# Using ibt helper (recommended)
ibt stacks run n8n local

# Or using docker compose directly
docker compose \
    -f stacks/n8n/n8n.local.yaml \
    -f stacks/n8n/mcp-hub.local.yaml \
    up
```

### Production Deployment

```bash
# Deploy to Docker Swarm
docker stack deploy -c stacks/n8n/n8n.yaml n8n
```

### Configuration

#### Secure MCP Hub Dashboard Password
```bash
htpasswd -bnBC 10 "" YOUR_PASSWORD | tr -d ':\n'
```

#### Create mcp_settings.json
```json
{
  "mcpServers": {
    // Add your MCP server configurations here
  },
  "users": [
    {
      "username": "admin",
      "password": "YOUR_ENCRYPTED_PASSWORD",
      "isAdmin": true
    }
  ]
}
```

This file should be saved as a Docker secret for production deployments.

## Use Cases

### Workflow Examples
1. **GitHub Issue Automation**
   - Monitor GitHub webhooks
   - Classify and route issues
   - Auto-assign based on labels
   - Trigger AI analysis

2. **Infrastructure Monitoring**
   - Collect metrics from services
   - Alert on anomalies
   - Auto-remediation workflows
   - Status page updates

3. **Content Generation**
   - Automated documentation
   - Blog post drafting
   - Social media scheduling
   - Newsletter compilation

4. **Data Processing**
   - ETL pipelines
   - API data synchronization
   - Report generation
   - Backup orchestration

## Comparison: n8n vs Python Agentic

| Aspect | n8n Workflows | Python Agentic |
|--------|---------------|----------------|
| **Learning Curve** | Low (visual) | Medium (Python) |
| **Flexibility** | Good (nodes) | Excellent (code) |
| **Debugging** | Visual logs | Full debugger |
| **Version Control** | JSON export | Native Git |
| **Testing** | Manual | Automated tests |
| **Performance** | Good | Excellent |
| **Extensibility** | Custom nodes | Custom code |
| **Best For** | Quick prototypes | Complex logic |

## Integration with Other Projects

### Docker Swarm Environment
- Runs as a Docker Swarm service
- Uses Caddy for HTTPS reverse proxy
- Managed via Portainer UI
- Shared networking with other stacks

### IBT CLI Integration
- Managed via `ibt stacks` command
- Quick start/stop for development
- Consistent with other stacks

## Known Issues and Limitations

### Current Limitations
- MCP server configuration not fully documented
- Production stack needs secrets management
- No automated backup solution yet
- Limited error handling examples

### Security Considerations
- Store API keys in Docker secrets (production)
- Use encrypted passwords for MCP Hub
- Enable HTTPS in production (via Caddy)
- Implement rate limiting for webhooks

## Planned Improvements

1. **Documentation**
   - Detailed MCP server setup guide
   - Workflow template examples
   - Best practices guide
   - Troubleshooting common issues

2. **Features**
   - Pre-built workflow templates
   - Custom node library
   - Backup/restore automation
   - Monitoring dashboard

3. **Integration**
   - Connect with Prefect for hybrid workflows
   - Share MCP servers with Agentic Framework
   - Unified authentication

## Documentation Links

- [Stack README](../../stacks/n8n/README.md) - Basic setup
- [n8n Official Docs](https://docs.n8n.io/) - Platform documentation
- [MCP Hub Repository](https://github.com/samanhappy/mcphub) - MCP Hub details

## Release Management

Managed through monorepo Changeset system:
- Version in `stacks/n8n/package.json`
- Part of `infra-bootstrap-tools-stacks` releases
- Packaged as zip archive in GitHub Releases
- Changelog in `stacks/n8n/CHANGELOG.md`

## Next Steps

1. **Create Workflow Templates**: Build reusable workflow examples
2. **Document MCP Setup**: Complete guide for MCP server configuration
3. **Production Hardening**: Implement secrets management and monitoring
4. **Tutorial Series**: Step-by-step guides for common use cases
5. **Integration Testing**: Validate n8n + MCP Hub workflows
