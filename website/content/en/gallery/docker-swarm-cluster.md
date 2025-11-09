---
title: "Docker Swarm Cluster"
date: 2025-11-03
description: A 3-node Docker Swarm cluster running various self-hosted services
featured_image: https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=800&q=80
tags:
  - Docker
  - Swarm
  - Infrastructure
---

My production Docker Swarm cluster consisting of three nodes running multiple services including monitoring, databases, and web applications.

## Stack Details

- 3 manager nodes for high availability
- Traefik for reverse proxy and SSL termination
- Portainer for management
- Prometheus + Grafana for monitoring
