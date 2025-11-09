FROM debian:bookworm-slim

# Install required tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    jq \
    openssl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Ziti CLI
ARG ZITI_VERSION=1.1.15
RUN wget -q "https://github.com/openziti/ziti/releases/download/v${ZITI_VERSION}/ziti-linux-amd64-${ZITI_VERSION}.tar.gz" \
    && tar -xzf "ziti-linux-amd64-${ZITI_VERSION}.tar.gz" -C /usr/local/bin \
    && rm "ziti-linux-amd64-${ZITI_VERSION}.tar.gz" \
    && chmod +x /usr/local/bin/ziti

# Install SPIRE Server CLI
ARG SPIRE_VERSION=1.10.3
RUN wget -q "https://github.com/spiffe/spire/releases/download/v${SPIRE_VERSION}/spire-${SPIRE_VERSION}-linux-amd64-musl.tar.gz" \
    && tar -xzf "spire-${SPIRE_VERSION}-linux-amd64-musl.tar.gz" \
    && cp "spire-${SPIRE_VERSION}/bin/spire-server" /usr/local/bin/ \
    && rm -rf "spire-${SPIRE_VERSION}" "spire-${SPIRE_VERSION}-linux-amd64-musl.tar.gz" \
    && chmod +x /usr/local/bin/spire-server

# Create directory for bootstrap scripts
RUN mkdir -p /bootstrap

# Copy bootstrap script
COPY setup.sh /bootstrap/setup.sh
RUN chmod +x /bootstrap/setup.sh

WORKDIR /bootstrap

CMD ["/bootstrap/setup.sh"]
