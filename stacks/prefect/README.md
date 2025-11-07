# Prefect - Workflow Orchestration Platform

Prefect is a modern workflow orchestration platform for building, observing, and reacting to data pipelines. This stack provides a local Prefect server setup with Docker Compose, allowing you to deploy and manage agents defined in the `agentic` directory.

## Components

- **Prefect Server**: The main Prefect orchestration server with UI
- **PostgreSQL**: Database backend for Prefect
- **MCP Hub**: Model Context Protocol hub for agent communication

## Local Testing

To run the Prefect stack locally:

```bash
docker compose \
    -f prefect.local.yaml \
    -f mcp-hub.local.yaml \
    up
```

Or using the stacks helper script:

```bash
ibt stacks run prefect mcp-hub
```

Note: The `ibt stacks` command will automatically use `.local.yaml` files when available.

## Accessing Services

After starting the stack:

- **Prefect UI**: http://localhost:4200
- **MCP Hub**: http://localhost:3000

## Deploying Agents

Agents defined in the `agentic/` directory can be deployed to this Prefect server. The agents can use the MCP Hub for tool discovery and interaction.

### Example: Deploying a Flow

1. Set the Prefect API URL to point to your local server:
   ```bash
   export PREFECT_API_URL="http://localhost:4200/api"
   ```

2. Create and deploy your flow using Prefect's Python SDK:
   ```python
   from prefect import flow
   
   @flow
   def my_agent_flow():
       # Your agent logic here
       pass
   
   if __name__ == "__main__":
       my_agent_flow.serve(name="my-agent")
   ```

## Architecture

The Prefect stack includes:

- A PostgreSQL database for persisting workflow state
- A Prefect server that provides the API and UI
- MCP Hub for centralized tool management across agents

## Going Live

For production deployment, you would typically:

1. Use external PostgreSQL database with proper credentials
2. Configure proper authentication and RBAC
3. Set up SSL/TLS certificates
4. Deploy worker agents on separate infrastructure
5. Configure secrets management for sensitive data

See the main repository documentation for more details on production deployments.
