# Jules Agent Quick Start Guide

This guide will help you quickly get started with the Jules agent workflow on Prefect.

## Prerequisites

- Docker and Docker Compose installed
- Python 3.9 or higher
- API Keys:
  - Google AI Studio API key (get from https://aistudio.google.com/apikey) - default, recommended
  - GitHub Personal Access Token (create at https://github.com/settings/tokens with `repo` scope)
  - Jules API key (get from https://jules.googleapis.com/)
  - OpenAI API key (optional, only if using OpenAI models from https://platform.openai.com/api-keys)

## Step-by-Step Setup

### 1. Start the Infrastructure Stack

```bash
# From the repository root
ibt stacks run prefect mcp-hub
```

This starts:
- Prefect Server at http://localhost:4200
- MCP Hub at http://localhost:3000
- PostgreSQL database

Wait for all services to be healthy (about 30 seconds).

### 2. Install Python Dependencies

```bash
pip install -r agentic/requirements.txt
```

### 3. Configure Your API Keys

```bash
# Copy the example environment file
cp agentic/.env.example agentic/.env

# Edit the file with your API keys
nano agentic/.env  # or use your preferred editor
```

Set these variables:
```env
GOOGLE_API_KEY=your-google-api-key-here
GITHUB_TOKEN=your-github-token-here
JULES_API_KEY=your-jules-api-key-here
# Optional: OPENAI_API_KEY=your-openai-api-key-here  (only if using OpenAI models)
```

### 4. Deploy the Workflow

```bash
cd agentic
python deployment/deploy.py
```

The script will:
- ✓ Check MCP Hub health
- ✓ Preload GitHub MCP server
- ✓ Preload Jules MCP server
- ✓ Deploy and serve the workflow

Keep this terminal open (the workflow is running).

### 5. Trigger Your First Workflow

Open a new terminal and run:

```bash
# Source your environment variables
export $(cat agentic/.env | xargs)

# Run the workflow
cd agentic
python -m agentic.workflows.jules_workflow https://github.com/owner/repo/issues/123
```

Replace the URL with an actual GitHub issue URL from a repository you have access to.

## Monitoring

- **Prefect UI**: http://localhost:4200
  - View flow runs
  - Check logs
  - Monitor performance

- **MCP Hub**: http://localhost:3000
  - Verify MCP servers are loaded
  - Check server health

## Common Operations

### Stop the Workflow Server

Press `Ctrl+C` in the terminal running the deployment script.

### Stop the Infrastructure Stack

```bash
# In the directory with docker-compose files
docker compose -f stacks/prefect/prefect.local.yaml -f stacks/prefect/mcp-hub.local.yaml down
```

### Redeploy the Workflow

If you made changes to the workflow code:

```bash
cd agentic
# Stop the current deployment (Ctrl+C)
# Then redeploy
python deployment/deploy.py
```

### Skip MCP Preloading (if servers already configured)

```bash
python deployment/deploy.py --skip-mcp-preload
```

## Troubleshooting

### "MCP Hub is not available"

- Check if Docker containers are running: `docker ps`
- Wait a bit longer for services to start
- Check logs: `docker compose logs mcphub`

### "Missing required environment variables"

- Ensure `.env` file exists in the `agentic/` directory
- Verify all three API keys are set
- Check for typos in variable names

### "Failed to initialize MCP toolset"

- Verify MCP servers are loaded: `curl http://localhost:3000/api/servers`
- Check MCP Hub logs: `docker compose logs mcphub`

### Workflow fails with authentication error

- Verify your API keys are correct
- Check if keys have expired
- Ensure GitHub token has the required scopes (`repo`)

## Next Steps

- Read the full documentation in `agentic/README.md`
- Explore the Prefect UI to understand workflow execution
- Customize the workflow for your use case
- Set up scheduled runs in Prefect
- Configure webhooks for automatic triggering

## Getting Help

- Check the main README: `agentic/README.md`
- Review Prefect stack documentation: `stacks/prefect/README.md`
- Open an issue on GitHub for bugs or feature requests
