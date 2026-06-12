#!/bin/bash
docker run --rm -t caddy:2.10.0-builder-alpine sh -c "xcaddy build \
    --with github.com/lucaslorentz/caddy-docker-proxy/v2@v2.8.0 \
    --with github.com/greenpau/caddy-security@v1.1.25 \
    --with github.com/greenpau/caddy-trace@v1.1.12 \
    --with github.com/caddy-dns/digitalocean=github.com/xnok/caddy-dns-digitalocean@master \
    --replace github.com/libdns/digitalocean=github.com/xNok/libdns-digitalocean@master \
    --with github.com/mholt/caddy-dynamicdns"
