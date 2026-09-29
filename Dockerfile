FROM node:22-alpine

ARG ICLOUD_MCP_VERSION=v0.4.1
ARG SUPERGATEWAY_VERSION=3.2.0
ARG TARGETARCH
ARG ICLOUD_MCP_SHA256_AMD64=af4a08069576c0fd7cabe68373d7fcf78eb3ece956c98991d0ec7f875bba6b71
ARG ICLOUD_MCP_SHA256_ARM64=b910e730a0d25e53d0a467ce9e31465240381e8f7aa4f0c7a06d8f4dd2e4fc15

RUN apk add --no-cache ca-certificates wget tar \
    && npm install -g "supergateway@${SUPERGATEWAY_VERSION}"

RUN set -eux; \
    ARCH="${TARGETARCH:-amd64}"; \
    case "${ARCH}" in \
      amd64) SHA256="${ICLOUD_MCP_SHA256_AMD64}" ;; \
      arm64) SHA256="${ICLOUD_MCP_SHA256_ARM64}" ;; \
      *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
    esac; \
    ARCHIVE="icloud-mcp-${ICLOUD_MCP_VERSION}-linux-${ARCH}.tar.gz"; \
    URL="https://github.com/ThomasCrouzet/icloud-mcp/releases/download/${ICLOUD_MCP_VERSION}/${ARCHIVE}"; \
    wget -O "/tmp/${ARCHIVE}" "${URL}"; \
    echo "${SHA256}  /tmp/${ARCHIVE}" | sha256sum -c -; \
    mkdir -p /tmp/icloud; \
    tar -xzf "/tmp/${ARCHIVE}" -C /tmp/icloud; \
    BINARY="$(find /tmp/icloud -type f -name icloud-mcp | head -n1)"; \
    test -n "${BINARY}"; \
    install -m 0755 "${BINARY}" /usr/local/bin/icloud-mcp; \
    rm -rf /tmp/*

RUN addgroup -g 10000 icloud \
    && adduser -D -u 10000 -G icloud icloud

COPY --chmod=0755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

USER icloud

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["supergateway", "--stdio", "/usr/local/bin/icloud-mcp", "--outputTransport", "streamableHttp", "--port", "8000", "--streamableHttpPath", "/mcp", "--healthEndpoint", "/healthz"]
