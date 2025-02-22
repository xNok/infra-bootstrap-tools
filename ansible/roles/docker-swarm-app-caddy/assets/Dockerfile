ARG CADDY_VERSION=2.9.1
FROM caddy:${CADDY_VERSION}-builder-alpine AS builder

RUN xcaddy build \
    --with github.com/lucaslorentz/caddy-docker-proxy/v2 \
    --with github.com/greenpau/caddy-security \
    --with github.com/greenpau/caddy-trace \
    --with github.com/caddy-dns/digitalocean=github.com/xnok/caddy-dns-digitalocean@master \
    --with github.com/mholt/caddy-dynamicdns

FROM caddy:${CADDY_VERSION}-alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["caddy", "docker-proxy"]
