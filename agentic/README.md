# Jules Agent - Prefect Workflow Automation

This package provides an automated workflow for assigning GitHub issues to the Jules AI agent using Prefect orchestration and MCP (Model Context Protocol) servers.

## Overview

The Jules agent workflow integrates:
- **Pydantic AI**: For intelligent agent creation and tool usage
- **Prefect**: For workflow orchestration and scheduling
- **MCP Hub**: For centralized tool management (GitHub and Jules MCP servers)
- **Jules API**: Google's AI-powered coding agent

## Architecture

```
┌─────────────────┐      ┌──────────────┐      ┌─────────────┐
│  Prefect Flow   │─────▶│   MCP Hub    │─────▶│   Jules API │
│                 │      │              │      │             │
│ Jules Workflow  │      │ - GitHub MCP │      │ Google Cloud│
└─────────────────┘      │ - Jules MCP  │      └─────────────┘
                         └──────────────┘
```

## Quick Start

### 1. Prerequisites

- Python 3.9+
- Docker and Docker Compose
- API Keys:
  - Google AI Studio API key (default, recommended)
  - GitHub Personal Access Token
  - Jules API key
  - OpenAI API key (optional, only if using OpenAI models)

### 2. Start the Prefect Stack

Start the local Prefect server and MCP Hub:

```bash
# Using the ibt CLI
ibt stacks run prefect mcp-hub

# Or using docker compose directly
cd stacks/prefect
docker compose -f prefect.local.yaml -f mcp-hub.local.yaml up
```

This will start:
- Prefect Server UI at http://localhost:4200
- MCP Hub at http://localhost:3000
- PostgreSQL database for Prefect

### 3. Install Python Dependencies

```bash
pip install -r agentic/requirements.txt
```

### 4. Configure Environment Variables

Copy the example environment file and fill in your API keys:

```bash
cp agentic/.env.example agentic/.env
# Edit .env with your actual API keys
```

Required variables:
- `GOOGLE_API_KEY`: Your Google AI Studio API key (for default Gemini model)
- `GITHUB_TOKEN`: GitHub personal access token with `repo` scope
- `JULES_API_KEY`: Your Jules API key from Google Cloud

Optional variables:
- `OPENAI_API_KEY`: Only needed if you choose to use OpenAI models
- `LLM_MODEL`: Change the model (default: `google-gla:gemini-1.5-flash`)

### 5. Deploy the Workflow

Run the deployment script to preload MCP servers and deploy the workflow:

```bash
cd agentic
python deployment/deploy.py
```

This script will:
1. Check MCP Hub health
2. Preload the GitHub MCP server
3. Preload the Jules MCP server (from OpenAPI spec)
4. Deploy the Jules workflow to Prefect
5. Start serving the workflow

The workflow will run in the foreground. Press Ctrl+C when you want to stop it.

### 6. Trigger the Workflow

Once deployed, you can trigger the workflow in several ways:

#### Via Prefect UI
1. Navigate to http://localhost:4200
2. Find the "jules-agent-workflow" deployment
3. Create a new flow run with the GitHub issue URL as a parameter

#### Via Python
```python
from agentic.workflows.jules_workflow import jules_agent_workflow

result = jules_agent_workflow(
    github_issue_url="https://github.com/owner/repo/issues/123"
)
print(result)
```

#### Via CLI (for testing)
```bash
python -m agentic.workflows.jules_workflow https://github.com/owner/repo/issues/123
```

## Project Structure

```
agentic/
├── __init__.py              # Package initialization
├── README.md                # This file
├── requirements.txt         # Python dependencies
├── .env.example            # Environment variable template
├── jules.schema.json       # OpenAPI spec for Jules API
├── jules/                  # Jules agent module
│   ├── __init__.py
│   ├── agent.py           # Original agent script
│   └── models.py          # Pydantic models for Jules API
├── workflows/             # Prefect workflows
│   ├── __init__.py
│   └── jules_workflow.py  # Main workflow definition
└── deployment/            # Deployment scripts
    └── deploy.py          # Automated deployment script
```

## Workflows

### Jules Agent Workflow

The main workflow (`jules_agent_workflow`) performs the following steps:

1. **Initialize MCP Toolset**: Connects to MCP Hub and discovers available tools
2. **Create Jules Agent**: Configures the Pydantic AI agent with the MCP toolset
3. **Assign GitHub Issue**: Processes the issue URL and assigns it to Jules

Each step is a Prefect task with:
- Automatic retries on failure
- Detailed logging
- Error handling

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GOOGLE_API_KEY` | Yes* | - | Google AI Studio API key for Gemini models |
| `OPENAI_API_KEY` | No** | - | OpenAI API key (only if using OpenAI models) |
| `GITHUB_TOKEN` | Yes | - | GitHub token for MCP server |
| `JULES_API_KEY` | Yes | - | Jules API key |
| `MCP_SERVER_URL` | No | `http://localhost:8000/mcp` | MCP server endpoint |
| `LLM_MODEL` | No | `google-gla:gemini-1.5-flash` | LLM model to use |
| `PREFECT_API_URL` | No | `http://localhost:4200/api` | Prefect API endpoint |

\* Required for default Gemini model  
\*\* Required only if `LLM_MODEL` is set to an OpenAI model

### Supported Models

The workflow supports multiple LLM providers. Configure via `LLM_MODEL` environment variable:

**Google AI Studio (default):**
- `google-gla:gemini-1.5-flash` (default, fast and efficient)
- `google-gla:gemini-1.5-pro` (more capable, higher cost)

**OpenAI:**
- `openai:gpt-4o`
- `openai:gpt-4o-mini`
| `PREFECT_API_URL` | No | `http://localhost:4200/api` | Prefect API endpoint |

### Deployment Options

The deployment script supports several options:

```bash
# Full deployment with MCP preloading
python deployment/deploy.py

# Skip MCP server preloading (if already configured)
python deployment/deploy.py --skip-mcp-preload

# Custom URLs
python deployment/deploy.py \
  --mcp-hub-url http://custom:3000 \
  --prefect-api-url http://custom:4200/api
```

## MCP Servers

### GitHub MCP Server

Provides tools for:
- Reading repository contents
- Creating issues and PRs
- Managing branches
- And more...

### Jules MCP Server

Generated from the OpenAPI specification (`jules.schema.json`), provides tools for:
- Listing sources (connected repositories)
- Creating sessions
- Sending messages to Jules
- Listing activities
- Approving plans

## Troubleshooting

### MCP Hub Connection Issues

```bash
# Check if MCP Hub is running
curl http://localhost:3000/health

# Check MCP Hub logs
docker compose -f stacks/prefect/mcp-hub.local.yaml logs mcphub
```

### Prefect Connection Issues

```bash
# Check if Prefect is running
curl http://localhost:4200/api/health

# Check Prefect logs
docker compose -f stacks/prefect/prefect.local.yaml logs prefect-server
```

### Workflow Execution Errors

Check the Prefect UI at http://localhost:4200 for:
- Flow run logs
- Task-level errors
- Retry history

Common issues:
- Missing API keys: Check your `.env` file
- MCP server not responding: Ensure both servers are preloaded
- Network timeouts: Increase retry delays in workflow configuration

## Development

### Running Tests

Currently, the package follows a minimal change approach. Tests can be added by:

1. Creating a `tests/` directory
2. Adding unit tests for workflow tasks
3. Adding integration tests with mock MCP servers

### Local Development

To develop and test locally without deployment:

```python
# Set environment variables
import os
os.environ["GOOGLE_API_KEY"] = "your-key"  # or OPENAI_API_KEY for OpenAI models
os.environ["GITHUB_TOKEN"] = "your-token"
os.environ["JULES_API_KEY"] = "your-key"

# Import and run workflow
from agentic.workflows.jules_workflow import jules_agent_workflow

result = jules_agent_workflow(
    github_issue_url="https://github.com/owner/repo/issues/123",
    mcp_server_url="http://localhost:8000/mcp"
)
```

## Legacy Components

### Original Agent Script

The original `jules/agent.py` script is preserved for reference and can still be used standalone:

```bash
export GOOGLE_API_KEY="your-key"  # or OPENAI_API_KEY if configured for OpenAI
python3 agentic/jules/agent.py https://github.com/owner/repo/issues/123
```

This requires a running MCP server at `http://localhost:8000/mcp`.

## Contributing

When contributing to this package:

1. Maintain backwards compatibility with the original agent script
2. Follow the existing code structure
3. Add appropriate error handling and logging
4. Update documentation for new features

## License

See the main repository LICENSE file for details.
