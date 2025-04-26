# Caddy Role Assets

## Validating default config

```bash
docker run -v $PWD:/var/data/caddy  ghcr.io/xnok/infra-bootstrap-tools-caddy:main caddy validate -c /var/data/caddy/Caddyfile
```