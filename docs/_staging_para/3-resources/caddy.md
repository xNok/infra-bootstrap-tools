---
type: resource
description: Automatic HTTPS reverse proxy with HTTP/2, HTTP/3, and dynamic configuration
related_projects:
  - docker-swarm-env
related_areas:
  - infra-orchestration
---

# Caddy

## Overview

Caddy is a powerful, extensible web server with automatic HTTPS. In the infra-bootstrap-tools stack, it serves as the primary reverse proxy and ingress controller for Docker Swarm, providing automatic SSL/TLS certificates from Let's Encrypt and dynamic configuration via Docker labels.

## Key Features

- **Automatic HTTPS**: Zero-config SSL/TLS from Let's Encrypt
- **HTTP/2 & HTTP/3**: Modern protocol support
- **Dynamic Configuration**: Configure via Docker service labels
- **Reverse Proxy**: Route traffic to backend services
- **Load Balancing**: Built-in load balancing capabilities
- **WebSocket Support**: Full WebSocket proxy support

## Use in This Project

### Docker Swarm Integration

Caddy runs as a Docker Swarm service and automatically configures itself based on labels on other services:

```yaml
# Example service with Caddy labels
services:
  myapp:
    image: myapp:latest
    deploy:
      labels:
        - "caddy=myapp.example.com"
        - "caddy.reverse_proxy={{upstreams}}"
    networks:
      - caddy_caddy
```

### Common Configurations

**Simple Reverse Proxy:**
```yaml
labels:
  - "caddy=app.example.com"
  - "caddy.reverse_proxy={{upstreams}} 8080"
```

**With Custom Headers:**
```yaml
labels:
  - "caddy=app.example.com"
  - "caddy.reverse_proxy={{upstreams}} 8080"
  - "caddy.header=/* X-Custom-Header 'value'"
```

**WebSocket Support:**
```yaml
labels:
  - "caddy=ws.example.com"
  - "caddy.reverse_proxy={{upstreams}} 3000"
  - "caddy.reverse_proxy.header_up=Upgrade {http.request.header.Upgrade}"
  - "caddy.reverse_proxy.header_up=Connection {http.request.header.Connection}"
```

## Configuration Patterns

### Basic Setup

The Caddy service in Docker Swarm:

```yaml
services:
  caddy:
    image: lucaslorentz/caddy-docker-proxy:latest
    ports:
      - "80:80"
      - "443:443"
    environment:
      - CADDY_INGRESS_NETWORKS=caddy_caddy
    networks:
      - caddy_caddy
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - caddy_data:/data
    deploy:
      mode: global
      placement:
        constraints:
          - node.role == manager
```

### Advanced Features

**Rate Limiting:**
```yaml
labels:
  - "caddy.rate_limit={path} 100r/m"
```

**Authentication:**
```yaml
labels:
  - "caddy.basic_auth=/* {$BASIC_AUTH_HASH}"
```

**Custom Error Pages:**
```yaml
labels:
  - "caddy.handle_errors.respond={err.status_code} {err.status_text}"
```

## Resources

### Internal Documentation
- [Caddy Web Server Documentation](../../website/content/en/docs/a1.caddy.md)
- [Ansible Role: docker_swarm_app_caddy](../../ansible/roles/docker_swarm_app_caddy/README.md)
- [Blog: Automating SSL with Caddy](../../website/content/en/blog/automating-ssl-caddy.md)

### External Links
- [Caddy Official Documentation](https://caddyserver.com/docs/)
- [Caddy Docker Proxy](https://github.com/lucaslorentz/caddy-docker-proxy)
- [Caddy Community Forum](https://caddy.community/)

## Troubleshooting

### Certificate Issues
```bash
# Check Caddy logs
docker service logs -f caddy_caddy

# Verify DNS is pointing to server
dig app.example.com

# Check if port 80/443 are accessible
curl -I http://app.example.com
```

### Service Not Routing
```bash
# Verify service labels
docker service inspect myapp --format '{{json .Spec.Labels}}'

# Check Caddy can reach service
docker exec -it $(docker ps -qf name=caddy) ping myapp

# Verify network connectivity
docker network inspect caddy_caddy
```

## Best Practices

1. **Network Connectivity**: Ensure services are on the `caddy_caddy` network
2. **DNS Configuration**: Set up DNS records before deploying
3. **Label Format**: Follow exact label syntax for Caddy directives
4. **SSL Certificates**: Let's Encrypt has rate limits, test with staging first
5. **Health Checks**: Configure service health checks for better routing

## Configuration Snippets

### API with CORS
```yaml
labels:
  - "caddy=api.example.com"
  - "caddy.reverse_proxy={{upstreams}} 8080"
  - "caddy.header=/* Access-Control-Allow-Origin *"
  - "caddy.header=/* Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS'"
```

### Static Site with SPA Routing
```yaml
labels:
  - "caddy=app.example.com"
  - "caddy.reverse_proxy={{upstreams}} 80"
  - "caddy.handle_path=/api/*"
  - "caddy.handle_path.reverse_proxy={{upstreams}} 8080"
  - "caddy.try_files={path} /index.html"
```

### Multiple Domains
```yaml
labels:
  - "caddy_0=app.example.com, www.app.example.com"
  - "caddy_0.reverse_proxy={{upstreams}} 8080"
```

## Related Resources

- [Portainer](./portainer.md) - Container management UI
- [Docker](./docker.md) - Container runtime
- [Docker Swarm](./docker-swarm.md) - Orchestration platform
