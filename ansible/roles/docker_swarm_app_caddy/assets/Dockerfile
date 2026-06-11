ARG CADDY_VERSION=2.8.4
FROM caddy:${CADDY_VERSION}-builder-alpine AS builder

RUN xcaddy build \
    --with github.com/lucaslorentz/caddy-docker-proxy/v2@v2.9.1 \
    --with github.com/greenpau/caddy-security@v1.1.60 \
    --with github.com/greenpau/caddy-trace@v1.1.12 \
    --with github.com/caddy-dns/digitalocean=github.com/xnok/caddy-dns-digitalocean@master \
    --replace github.com/libdns/digitalocean=github.com/xNok/libdns-digitalocean@master \
    --with github.com/mholt/caddy-dynamicdns

FROM caddy:${CADDY_VERSION}-alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["caddy", "docker-proxy"]
