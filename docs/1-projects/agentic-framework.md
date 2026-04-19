---
type: project
status: active
description: Python-based package for building and hosting AI agent workflows using Prefect orchestration and MCP servers
related_projects:
  - n8n-workflows
  - docker-swarm-env
related_resources:
  - prefect
  - pydantic-ai
  - mcp-hub
  - python
related_areas:
  - ai-workflow-automation
  - workflow-orchestration
---

# Agentic Framework (AI Workflow)

## Overview

The Agentic Framework is a Python-based package (`infra-bootstrap-tools-agentic`) for building and hosting AI agent workflows. It integrates Pydantic AI for intelligent agent creation, Prefect for workflow orchestration, and Model Context Protocol (MCP) for centralized tool management.

## Current State

**Status**: Active Development  
**Version**: 0.1.x  
**Last Updated**: January 2025

The project has completed its initial implementation phase with:
- ✅ Prefect workflow integration with task-based orchestration
- ✅ Jules agent implementation using Pydantic AI
- ✅ MCP Hub integration for GitHub and Jules API tools
- ✅ Comprehensive documentation (README, QUICKSTART, IMPLEMENTATION)
- ✅ Automated deployment script
- ✅ Security scanning passed (CodeQL)

## Key Files and Directories

### Core Package Structure
```
agentic/
├── __init__.py              # Package initialization with version
├── pyproject.toml           # Python package configuration
├── requirements.txt         # Python dependencies
├── .env.example            # Environment variable template
├── README.md               # Comprehensive documentation
├── QUICKSTART.md           # Quick start guide
├── IMPLEMENTATION.md       # Implementation summary
├── CHANGELOG.md            # Version history
├── jules/                  # Jules agent module
│   ├── agent.py           # Original standalone agent
│   └── models.py          # Pydantic models for Jules API
├── workflows/             # Prefect workflows
│   └── jules_workflow.py  # Main workflow definition
└── deployment/            # Deployment automation
    └── deploy.py          # Deployment script
```

### Related Infrastructure
- **Stack Definition**: `stacks/prefect/` - Docker Compose configuration
- **MCP Schema**: `agentic/jules.schema.json` - Jules API OpenAPI spec
- **Documentation**: `agentic/README.md`, `agentic/QUICKSTART.md`

## Architecture

```
┌─────────────────┐      ┌──────────────┐      ┌─────────────┐
│  Prefect Flow   │─────▶│   MCP Hub    │─────▶│   Jules API │
│                 │      │              │      │             │
│ Jules Workflow  │      │ - GitHub MCP │      │ Google Cloud│
└─────────────────┘      │ - Jules MCP  │      └─────────────┘
                         └──────────────┘
```

### Components

1. **Prefect Workflow** (`workflows/jules_workflow.py`)
   - Task-based workflow with retry logic
   - Environment variable validation
   - Configurable MCP server URL and LLM model
   - Support for programmatic and CLI usage

2. **MCP Hub Integration**
   - GitHub MCP Server: Full GitHub API access via stdio
   - Jules MCP Server: OpenAPI-based Jules API integration
   - Centralized tool management

3. **Deployment Automation** (`deployment/deploy.py`)
   - Health checks for MCP Hub and Prefect
   - Automated MCP server preloading
   - Workflow deployment with serve
   - Command-line options for flexibility

## Resources and Dependencies

### Core Dependencies
- **pydantic-ai-slim[google-gla]** >=0.0.14 - AI agent framework with Google Gemini support
- **prefect** >=3.0.0 - Workflow orchestration
- **pydantic** >=2.0.0 - Data validation
- **requests** >=2.31.0 - HTTP client for MCP Hub API
- **python-dotenv** >=1.0.0 - Environment variable management

### External Services Required
- Google AI Studio API key (for Gemini models)
- GitHub Personal Access Token (repo scope)
- Jules API key (from Google Cloud)
- Optional: OpenAI API key (if using OpenAI models)

### Infrastructure Dependencies
- Docker and Docker Compose
- Prefect Server (port 4200)
- MCP Hub (port 3000)
- PostgreSQL (port 5432)

## Development Workflow

### Quick Start
```bash
# 1. Start infrastructure
ibt stacks run prefect mcp-hub

# 2. Install dependencies
pip install -r agentic/requirements.txt

# 3. Configure environment
cp agentic/.env.example agentic/.env
# Edit .env with API keys

# 4. Deploy workflow
cd agentic
python deployment/deploy.py

# 5. Trigger workflow
python -m agentic.workflows.jules_workflow https://github.com/owner/repo/issues/123
```

### Access Points
- Prefect UI: http://localhost:4200
- MCP Hub: http://localhost:3000

## Known Issues and Limitations

### Current Limitations
- Single LLM provider at a time (configured via env var)
- Manual API key management (no vault integration)
- Local deployment only (no production templates yet)
- No unit/integration tests

### Planned Improvements
- Add unit tests for workflow tasks
- Add integration tests with mock MCP servers
- Support for multiple LLM providers simultaneously
- Webhook integration for automatic triggering
- Scheduled workflow execution
- Metrics and monitoring integration
- Production deployment templates
- CI/CD pipeline integration

## Release Management

The package is managed through the monorepo's Changeset system:
- Version managed in `agentic/package.json`
- Releases tagged as `infra-bootstrap-tools-agentic@x.y.z`
- GitHub Releases with wheel and source distribution
- Changelog in `agentic/CHANGELOG.md`

### Installation
```bash
pip install https://github.com/xNok/infra-bootstrap-tools/releases/download/infra-bootstrap-tools-agentic@0.1.1/infra_bootstrap_tools_agentic-0.1.1-py3-none-any.whl
```

## Documentation Links

- [Main README](../../agentic/README.md) - Comprehensive documentation
- [Quick Start Guide](../../agentic/QUICKSTART.md) - Step-by-step setup
- [Implementation Summary](../../agentic/IMPLEMENTATION.md) - Technical details
- [Prefect Stack README](../../stacks/prefect/README.md) - Infrastructure setup

## Related Projects

- **n8n-workflows**: Alternative low-code approach to workflow automation
- **docker-swarm-env**: Infrastructure layer hosting Prefect stack
- **ibt-nix-refactor**: Environment management for Python dependencies

## Next Steps

1. **Testing**: Add comprehensive test suite
2. **Multi-Provider Support**: Enable using multiple LLM providers
3. **Production Deployment**: Create production-ready templates
4. **CI/CD Integration**: Automate testing and deployment
5. **Documentation**: Expand tutorials and examples
