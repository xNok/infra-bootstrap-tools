---
"docker-stack-collection-infra-bootstrap-tools": patch
"docker-stack-prefect": patch
---

Add new Prefect stack for workflow orchestration and agent deployment. The stack includes:
- Prefect server with PostgreSQL database backend
- MCP Hub integration for agent communication
- Local Docker Compose configuration for development and testing
