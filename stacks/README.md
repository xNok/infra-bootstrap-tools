# Stacks

This directory contains reusable Docker Compose stack configurations for deploying applications in a flexible and consistent manner. Stacks are designed to be used both for local experimentation and for production deployment in Docker Swarm, either directly or via Portainer.

## What is a Stack?

A **stack** is a modular set of Docker Compose YAML files that define one or more services, networks, and volumes for an application or group of applications. Stacks in this repository are structured to support:

- **Local Development & Testing:**  
	Files with the `.local.yaml` suffix are tailored for running with `docker compose` on your local machine. These typically expose ports directly and use local volumes for easy access and debugging.

- **Production/Swarm Deployment:**  
	Standard `.yaml` files are intended for deployment in a Docker Swarm cluster, either via the `docker stack deploy` command or through Portainer's "Stacks" feature. These files are often templated for use with Portainer, allowing you to parameterize deployments.

## Usage

### Local Usage

To run a stack locally, use the `.local.yaml` files. For example, to start the `n8n` stack and its related component:

```bash
docker compose \
		-f n8n.local.yaml \
		-f mcp-hub.local.yaml \
		up
```

You can also use the provided [stacks.sh](../../bin/bash/stacks.sh) script for convenience:

```bash
# List available stacks
ibt stacks list

# Run a stack locally
ibt stacks run n8n local
```

### Swarm/Portainer Usage

For production, use the standard `.yaml` files. These can be deployed:

- **Directly with Docker Swarm:**
	```bash
	docker stack deploy -c n8n.yaml n8n
	```

- **Via Portainer:**  
	Upload or point Portainer to the stack YAML file, or use a GitOps workflow to manage stacks from a Git repository. See [Portainer documentation](../../website/content/en/docs/a2.portainer.md) for more details.

## Structure

- Each subdirectory in `stacks/` represents a logical application or service group.
- Each stack can have:
	- `stackname.yaml` — Swarm/production configuration
	- `stackname.local.yaml` — Local development configuration
	- Additional component files as needed (e.g., `mcp-hub.local.yaml`)

## Best Practices

- **Secrets & Sensitive Data:**  
	Do not hardcode secrets in stack files. Use Docker secrets, environment variables, or integrate with secret management tools (see [Secrets Management Guide](../../website/content/en/docs/gs1.getting_started.md#configuration---secrets-management)).
- **Modularity:**  
	Compose stacks from multiple files to enable flexible combinations for different environments.
- **Portainer Templates:**  
	Stacks can be used as templates in Portainer for rapid, repeatable deployments.

## Related Tooling

- [stacks.sh](../../bin/bash/stacks.sh): Bash script for listing and running stacks with support for modular composition and local overrides.
- [tools.sh](../../bin/bash/tools.sh): Provides Docker-based aliases for running infrastructure tools in a containerized environment.

## Further Reading

- [Getting Started Guide](../../website/content/en/docs/gs1.getting_started.md)
- [Portainer Management UI](../../website/content/en/docs/a2.portainer.md)
- [Docker Swarm Setup](../../website/content/en/docs/b3.docker_swarm.md)

