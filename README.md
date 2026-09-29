# iCloud MCP Sidecar

Containerized iCloud Calendar MCP sidecar for **Der Koch / Hermes Agent**.

It combines:

- [ThomasCrouzet/icloud-mcp](https://github.com/ThomasCrouzet/icloud-mcp) `v0.4.1`
- [Supergateway](https://github.com/supercorp-ai/supergateway) `3.2.0`

`icloud-mcp` runs as a local stdio MCP server inside the container.
Supergateway exposes it as Streamable HTTP for Hermes.

## Architecture

```text
Der Koch / Hermes
        |
        | Streamable HTTP
        | http://icloud-mcp:8000/mcp
        v
   Supergateway
        |
        | stdio
        v
    icloud-mcp
        |
        | CalDAV
        v
      iCloud
```

This wrapper intentionally exposes **Calendar only**. Contacts and iCloud Mail
are forced off in the entrypoint.

## Credentials

Create an **app-specific Apple password**. Never use the main Apple Account password.

The container accepts either direct variables or mounted secret files:

```text
ICLOUD_EMAIL
ICLOUD_PASSWORD

ICLOUD_EMAIL_FILE
ICLOUD_PASSWORD_FILE
```

Recommended:

```text
ICLOUD_EMAIL_FILE=/run/secrets/icloud_email
ICLOUD_PASSWORD_FILE=/run/secrets/icloud_password
```

## Read/write mode

The wrapper defaults to:

```text
ICLOUD_MCP_READ_ONLY=true
ICLOUD_MCP_DEFAULT_TZ=Europe/Berlin
```

Read-only exposes Calendar read tools such as calendar discovery, event search,
event lookup and free-slot lookup.

To allow Der Koch to create, update and delete calendar events:

```text
ICLOUD_MCP_READ_ONLY=false
```

## Coolify / Compose

Example service:

```yaml
icloud-mcp:
  build:
    context: 'https://github.com/hungerundkoch/icloud-mcp-sidecar.git#main'
    dockerfile: Dockerfile
  restart: unless-stopped
  expose:
    - '8000'
  environment:
    ICLOUD_EMAIL_FILE: /run/secrets/icloud_email
    ICLOUD_PASSWORD_FILE: /run/secrets/icloud_password
    ICLOUD_MCP_READ_ONLY: 'true'
    ICLOUD_MCP_DEFAULT_TZ: Europe/Berlin
  volumes:
    - '/etc/koch-secrets/icloud_email:/run/secrets/icloud_email:ro'
    - '/etc/koch-secrets/icloud_password:/run/secrets/icloud_password:ro'
```

The mounted files must be readable by container UID/GID `10000:10000`.

## Hermes

Add the sidecar to `/opt/data/config.yaml`:

```yaml
mcp_servers:
  icloud-calendar:
    url: http://icloud-mcp:8000/mcp
```

Then restart/reload Hermes MCP discovery as appropriate for the running setup.

The MCP endpoint is:

```text
http://icloud-mcp:8000/mcp
```

Health endpoint:

```text
http://icloud-mcp:8000/healthz
```

## Security choices

- Calendar-only wrapper
- read-only by default
- app-specific Apple password
- secret-file support
- upstream release archive is SHA-256 pinned
- no public port is required; use the internal Docker network
