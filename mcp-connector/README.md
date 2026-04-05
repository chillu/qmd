# TypingMind MCP Connector (Docker Isolated)

This directory contains the **Docker-isolated** TypingMind MCP Connector. This approach keeps the TypingMind connector code running in a container, isolated from your host machine.

## Why Docker Isolation?

The TypingMind MCP Connector is a Node.js application that bridges TypingMind to your MCP servers. Running it in Docker provides:

- ✅ **Code isolation**: The connector runs in a container, not directly on your Mac
- ✅ **Network isolation**: It can only access the explicitly defined MCP services
- ✅ **Process isolation**: Limited to the container's resources and permissions
- ✅ **Easy cleanup**: Remove the container and all traces are gone
- ✅ **Version control**: Pin to a specific version of the connector

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Docker Network: mcp-network                               │
│                                                             │
│  ┌──────────────┐      ┌──────────────┐      ┌───────────┐ │
│  │   QMD        │      │  MCPVault    │      │ MCP Conn. │ │
│  │  :8181       │      │   :8182      │      │  :50880   │ │
│  └──────┬───────┘      └──────┬───────┘      └─────┬─────┘ │
│         │                     │                    │       │
│         └─────────────────────┴────────────────────┘       │
│                              │                              │
│                    (Internal Docker network)               │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               │ localhost:50880 (exposed)
                               ↓
┌─────────────────────────────────────────────────────────────┐
│  Your Mac (Host)                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Tailscale serve                                        │ │
│  │  https://<hostname>/mcp-connector                       │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## How It Works

1. **QMD** and **MCPVault** run as isolated MCP servers (exposed only on localhost)
2. **MCP Connector** runs in Docker and connects to both services internally
3. **Tailscale serve** exposes the MCP Connector on your tailnet via HTTPS
4. **TypingMind** connects to the Tailscale URL with your auth token
5. **All code is isolated**: Neither TypingMind's connector nor their code runs on your host

## Configuration

### 1. Start All Services

```bash
cd /Users/ingo/Projects/obsidian-pkm
docker-compose up -d
```

This starts:
- QMD (semantic search)
- MCPVault (vault access)
- MCP Connector (TypingMind bridge)

### 2. Get Your Auth Token

The MCP Connector generates an auth token on first run. Get it with:

```bash
docker logs typingmind-mcp-connector | grep "Auth Token:"
```

**Save this token!** You'll need it for TypingMind configuration.

You can also set a custom token in `docker-compose.yml`:

```yaml
environment:
  - MCP_AUTH_TOKEN=your-secure-token-here
```

### 3. Configure Tailscale

```bash
./tailscale/setup-serve.sh
```

This exposes:
- QMD: `https://<hostname>/qmd/mcp`
- MCPVault: `https://<hostname>/mcpvault/mcp`
- MCP Connector: `https://<hostname>/mcp-connector`

### 4. Configure TypingMind

In TypingMind's MCP settings:

1. **Connector URL**: `https://<your-hostname>/mcp-connector`
2. **Auth Token**: (the token from step 2)

3. **Edit Servers** and add your MCP servers:

```json
{
  "mcpServers": {
    "qmd": {
      "url": "http://qmd:8181/mcp"
    },
    "mcpvault": {
      "url": "http://mcpvault:8182/mcp"
    }
  }
}
```

**Note**: Use internal Docker hostnames (`qmd`, `mcpvault`) since they're on the same Docker network.

## Security Features

### Container Isolation

The MCP Connector runs in an Alpine Linux container with:
- Minimal base image (Node.js 20 Alpine)
- No access to host filesystem except explicitly mounted volumes
- Network limited to the `mcp-network` Docker bridge
- No elevated privileges

### Network Security

```
Host Machine (Your Mac)
  └── localhost:50880 (MCP Connector exposed here)
      └── Tailscale serve
          └── https://<hostname>/mcp-connector (Tailnet only)
```

- MCP Connector not exposed to local network
- Only accessible via authenticated Tailscale connection
- End-to-end encryption via Tailscale

### What the Connector Can Access

The MCP Connector can only access:
1. ✅ QMD service (port 8181, internal Docker network)
2. ✅ MCPVault service (port 8182, internal Docker network)
3. ✅ TypingMind's external API (for tunneling)

The MCP Connector **cannot** access:
1. ❌ Your host filesystem (except Docker volumes you explicitly mount)
2. ❌ Other processes on your Mac
3. ❌ Your vault files directly (only via MCPVault's API)
4. ❌ Local network (192.168.x.x)

## Monitoring

### View Connector Logs

```bash
docker logs typingmind-mcp-connector
# Follow logs
docker logs -f typingmind-mcp-connector
```

### Check Connector Status

```bash
# Ping endpoint
curl -H "Authorization: Bearer <your-token>" http://localhost:50880/ping

# List connected clients
curl -H "Authorization: Bearer <your-token>" http://localhost:50880/clients
```

### Health Check

The container includes a built-in health check:

```bash
docker ps | grep typingmind-mcp-connector
# Should show (healthy)
```

## Troubleshooting

### Connector Can't Connect to QMD/MCPVault

If you see connection errors in the logs:

```bash
# Verify services are running
docker-compose ps

# Check internal network connectivity
docker exec typingmind-mcp-connector curl -v http://qmd:8181/health
docker exec typingmind-mcp-connector curl -v http://mcpvault:8182/health

# Restart the connector
docker-compose restart mcp-connector
```

### Auth Token Issues

If TypingMind can't authenticate:

1. Get the current token: `docker logs typingmind-mcp-connector | grep "Auth Token:"`
2. Verify the token is being used: Check TypingMind's MCP settings
3. Restart if needed: `docker-compose restart mcp-connector`

### Container Won't Start

```bash
# Check for port conflicts
lsof -i :50880

# Rebuild the image
docker-compose build --no-cache mcp-connector

# Check logs
docker-compose logs mcp-connector
```

## Updating

To update the MCP Connector to a newer version:

```bash
# Edit Dockerfile to update @typingmind/mcp version
# Then rebuild
docker-compose down
docker-compose build --no-cache mcp-connector
docker-compose up -d
```

## Comparison: Docker vs. Local

| Approach | Isolation | Setup Complexity | Trust Level |
|----------|-----------|------------------|-------------|
| **Docker (this setup)** | High (containerized) | Medium | Run their code in sandbox |
| **Local npx** | None (runs on host) | Low | Run their code on your machine |
| **Auth Proxy** | Medium (your own proxy) | High | Full control over auth |

**Docker isolation** provides the best balance of security and usability for most users.

## Files

- `Dockerfile` - Container definition
- `entrypoint.sh` - Container startup script with auto-configuration
- `README.md` - This file

## References

- [TypingMind MCP Documentation](https://docs.typingmind.com/model-context-protocol-(mcp)-in-typingmind)
- [TypingMind MCP Connector GitHub](https://github.com/TypingMind/typingmind-mcp)
- [MCP Protocol](https://modelcontextprotocol.io/)
