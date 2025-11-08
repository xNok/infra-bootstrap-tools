# Prefect - Workflow Orchestration Platform

Prefect is a modern workflow orchestration platform for building, observing, and reacting to data pipelines. This stack provides a local Prefect server setup with Docker Compose, allowing you to deploy and manage agents defined in the `agentic` directory.

## Components

- **Prefect Server**: The main Prefect orchestration server with UI
- **PostgreSQL**: Database backend for Prefect
- **MCP Hub**: Model Context Protocol hub for agent communication

## Quick Start

### 1. Start the Stack

Run the Prefect stack locally with MCP Hub:

```bash
# Using the stacks helper script (recommended)
ibt stacks run prefect mcp-hub

# Or using docker compose directly
docker compose \
    -f prefect.local.yaml \
    -f mcp-hub.local.yaml \
    up
```

Note: The `ibt stacks` command will automatically use `.local.yaml` files when available.

### 2. Access Services

After starting the stack:

- **Prefect UI**: http://localhost:4200
- **MCP Hub**: http://localhost:3000

### 3. Deploy the Jules Agent Workflow

The Jules agent workflow is ready to deploy. Follow these steps:

#### a. Install Python Dependencies

```bash
pip install -r agentic/requirements.txt
```

#### b. Configure Environment Variables

Copy and configure the environment file:

```bash
cp agentic/.env.example agentic/.env
# Edit agentic/.env with your API keys:
# - GOOGLE_API_KEY (required for default Gemini model)
# - GITHUB_TOKEN
# - JULES_API_KEY
# - OPENAI_API_KEY (optional, only if using OpenAI models)
```

#### c. Deploy the Workflow

Run the automated deployment script:

```bash
cd agentic
python deployment/deploy.py
```

This will:
1. Check MCP Hub health
2. Preload GitHub MCP server
3. Preload Jules MCP server (from OpenAPI spec)
4. Deploy the workflow to Prefect
5. Start serving the workflow

The deployment script will run in the foreground. Press Ctrl+C when you want to stop serving the workflow.

### 4. Use the Workflow

Once deployed, trigger the workflow:

#### Via Prefect UI
1. Navigate to http://localhost:4200
2. Find "jules-agent-workflow" deployment
3. Create a flow run with a GitHub issue URL

#### Via Python
```python
from agentic.workflows.jules_workflow import jules_agent_workflow

result = jules_agent_workflow(
    github_issue_url="https://github.com/owner/repo/issues/123"
)
```

#### Via CLI
```bash
python -m agentic.workflows.jules_workflow https://github.com/owner/repo/issues/123
```

## Architecture

The Prefect stack includes:

- **PostgreSQL database** for persisting workflow state
- **Prefect server** that provides the API and UI
- **MCP Hub** for centralized tool management across agents

The workflow architecture:

```
┌─────────────────┐      ┌──────────────┐      ┌─────────────┐
│  Prefect Flow   │─────▶│   MCP Hub    │─────▶│   Jules API │
│                 │      │              │      │             │
│ Jules Workflow  │      │ - GitHub MCP │      │ Google Cloud│
└─────────────────┘      │ - Jules MCP  │      └─────────────┘
                         └──────────────┘
```

## Deployment Details

### MCP Servers

The deployment automatically configures two MCP servers:

1. **GitHub MCP Server** (`@modelcontextprotocol/server-github`)
   - Provides GitHub repository interaction tools
   - Requires: `GITHUB_TOKEN` with repo scope

2. **Jules MCP Server** (from OpenAPI spec)
   - Provides Jules API interaction tools
   - Generated from `agentic/jules.schema.json`
   - Requires: `JULES_API_KEY`

### Deployment Options

The deployment script supports various options:

```bash
# Full deployment
python deployment/deploy.py

# Skip MCP preloading (if already configured)
python deployment/deploy.py --skip-mcp-preload

# Custom URLs
python deployment/deploy.py \
  --mcp-hub-url http://custom:3000 \
  --prefect-api-url http://custom:4200/api

# Deploy only (skip health checks)
python deployment/deploy.py --deploy-only
```

### Environment Variables

Required:
- `GOOGLE_API_KEY`: For Google AI Studio (Gemini) models (default)
- `GITHUB_TOKEN`: For GitHub MCP server
- `JULES_API_KEY`: For Jules API access

Optional:
- `OPENAI_API_KEY`: Only if using OpenAI models
- `MCP_SERVER_URL`: Default `http://localhost:8000/mcp`
- `LLM_MODEL`: Default `google-gla:gemini-1.5-flash`
- `PREFECT_API_URL`: Default `http://localhost:4200/api`

## Troubleshooting

### Stack Won't Start

Check if ports are already in use:
```bash
# Check port 4200 (Prefect)
lsof -i :4200

# Check port 3000 (MCP Hub)
lsof -i :3000

# Check port 5432 (PostgreSQL)
lsof -i :5432
```

### MCP Hub Connection Issues

```bash
# Check MCP Hub health
curl http://localhost:3000/health

# Check MCP Hub logs
docker compose -f mcp-hub.local.yaml logs mcphub

# List configured MCP servers
curl http://localhost:3000/api/servers
```

### Prefect Connection Issues

```bash
# Check Prefect API health
curl http://localhost:4200/api/health

# Check Prefect logs
docker compose -f prefect.local.yaml logs prefect-server

# Check PostgreSQL connection
docker compose -f prefect.local.yaml logs postgres
```

### Workflow Execution Errors

Check the Prefect UI (http://localhost:4200) for:
- Flow run logs
- Task-level errors
- Retry history

Common issues:
- **Missing API keys**: Verify your `.env` file
- **MCP server not responding**: Ensure servers are preloaded
- **Network timeouts**: Check Docker network configuration

## Manual Deployment (Advanced)

If you prefer manual deployment instead of using the deployment script:

### 1. Set Prefect API URL

```bash
export PREFECT_API_URL="http://localhost:4200/api"
```

### 2. Preload MCP Servers Manually

#### GitHub MCP Server
```bash
curl -X POST http://localhost:3000/api/servers \
  -H "Content-Type: application/json" \
  -d '{
    "name": "github",
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-github"],
    "env": {
      "GITHUB_PERSONAL_ACCESS_TOKEN": "your-token"
    }
  }'
```

#### Jules MCP Server
```bash
curl -X POST http://localhost:3000/api/servers \
  -H "Content-Type: application/json" \
  -d @agentic/jules.schema.json
```

### 3. Deploy Workflow

```python
from agentic.workflows.jules_workflow import jules_agent_workflow

# Deploy with serve (foreground)
jules_agent_workflow.serve(
    name="jules-agent-deployment",
    tags=["jules", "github"],
    version="1.0.0"
)
```

## Going Live

For production deployment:

1. **Database**: Use external PostgreSQL with proper credentials
2. **Authentication**: Configure Prefect RBAC and API keys
3. **SSL/TLS**: Set up certificates for secure communication
4. **Workers**: Deploy worker agents on separate infrastructure
5. **Secrets**: Use Prefect's secret management or external vault
6. **Monitoring**: Set up alerting and logging
7. **Scaling**: Configure work pools and concurrency limits

See the main repository documentation for production deployment guides.

## Additional Resources

- [Prefect Documentation](https://docs.prefect.io/)
- [MCP Hub Documentation](https://github.com/samanhappy/mcphub)
- [Jules Agent README](../../agentic/README.md)
- [Pydantic AI Documentation](https://ai.pydantic.dev/)
