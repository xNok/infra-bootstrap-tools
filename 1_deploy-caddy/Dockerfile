FROM caddy:2-builder AS builder

RUN xcaddy build \
    --with github.com/lucaslorentz/caddy-docker-proxy/plugin/v2

FROM caddy:2

COPY --from=builder /usr/bin/caddy /usr/bin/caddy