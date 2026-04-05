# Obsidian PKM MCP Servers

Secure Docker Compose setup running two independent MCP servers for your Obsidian vault. **All services are protected by Tailscale** - no exposure to local networks.

## Security Model

```
┌─────────────────────────────────────────────────────────────┐
│  Your Mac (Host)                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Tailscale Network (Authenticated)                     │ │
│  │  ┌─────────────┐     ┌─────────────────────────────┐   │ │
│  │  │ Tailscale   │────▶│  http://<tailscale-ip>:8181 │   │ │
│  │  │ Serve Proxy │     │  https://<hostname>/qmd       │   │ │
│  │  └─────────────┘     └─────────────────────────────┘   │ │
│  │         │                        │                      │ │
│  │         │              (via Docker)                     │ │
│  │         ▼                        ▼                      │ │
│  │  ┌─────────────────────────────────────────────────┐   │ │
│  │  │  Localhost Only (NOT exposed to LAN)            │   │ │
│  │  │  • 127.0.0.1:8181 → QMD (semantic search)      │   │ │
│  │  │  • 127.0.0.1:8182 → MCPVault (vault access)     │   │ │
│  │  └─────────────────────────────────────────────────┘   │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Tailscale tunnel (WireGuard)
                              ▼
                  ┌───────────────────────┐
                  │  Other Tailnet Devices │
                  │  (typingmind, iPad, etc)│
                  └───────────────────────┘
```

**Key Security Features:**
- ✅ Services bind only to `127.0.0.1` (not `0.0.0.0`)
- ✅ **Zero exposure** to local WiFi/coffee shop networks
- ✅ Access only through authenticated Tailscale connections
- ✅ No firewall rules or port forwarding needed
- ✅ Automatic end-to-end encryption via Tailscale

## Services

| Service | Local Port | Tailscale Path | Description |
|---------|-----------|----------------|-------------|
| [QMD](./qmd/) | 8181 | `/qmd` | Semantic search with OpenAI embeddings |
| [MCPVault](./mcpvault/) | 8182 | `/mcpvault` | Direct vault access for AI agents |
| [MCP Connector](./mcp-connector/) | 50880 | `/mcp-connector` | **Docker-isolated** TypingMind bridge |

## Quick Start

### 1. Start the Services

```bash
# Start both services (binds only to localhost)
docker-compose up -d

# View logs
docker-compose logs -f
```

### 2. Set Up Tailscale Access

**Option A: Manual setup (run when needed)**
```bash
./tailscale/setup-serve.sh
```

**Option B: Auto-start on login (recommended)**
```bash
# Install LaunchAgent for automatic startup
./tailscale/install-launchagent.sh
```

This creates a macOS LaunchAgent that automatically starts `tailscale serve` when you log in.

### 3. Verify Connection

```bash
# Check tailscale serve is running
tailscale serve status

# Test from another device on your tailnet
curl http://$(tailscale ip -4):8181/health
```

## MCP Client Configuration

### TypingMind

Add a new MCP server with URL:
```
http://<YOUR_TAILSCALE_IP>:8181/mcp
```

Or with HTTPS (if you have a Tailscale DNS name):
```
https://<YOUR_HOSTNAME>/qmd/mcp
```

#### TypingMind with Docker-Isolated MCP Connector (Recommended)

For better security, use the **Docker-isolated** MCP Connector that keeps TypingMind's code in a container:

1. **Start all services** (includes MCP Connector):
   ```bash
   docker-compose up -d
   ```

2. **Get your Auth Token**:
   ```bash
   docker logs typingmind-mcp-connector | grep "Auth Token:"
   ```
   Save this token!

3. **Configure Tailscale**:
   ```bash
   ./tailscale/setup-serve.sh
   ```

4. **In TypingMind MCP settings**:
   - **Connector URL**: `https://<YOUR_HOSTNAME>/mcp-connector`
   - **Auth Token**: (from step 2)
   - **Edit Servers** and add:
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

   **For iOS/iPhone users:** If you can't resolve the hostname, use the Tailscale IP directly:
   - **Connector URL**: `http://100.x.x.x:50880` (use HTTP, not HTTPS)
   - See [iOS Troubleshooting](./docs/ios-troubleshooting.md) for details

**Why Docker isolation?** The MCP Connector runs TypingMind's code in a sandboxed container, not directly on your Mac. It can only access QMD and MCPVault via internal Docker networking - not your host filesystem or other processes.

See [mcp-connector/README.md](./mcp-connector/) for full details.

### ChatGPT Desktop App

Edit `~/Library/Application Support/ChatGPT/mcp_config.json`:
```json
{
  "mcpServers": {
    "qmd": {
      "url": "http://<YOUR_TAILSCALE_IP>:8181/mcp"
    },
    "mcpvault": {
      "url": "http://<YOUR_TAILSCALE_IP>:8182/mcp"
    }
  }
}
```

### Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "qmd": {
      "url": "http://<YOUR_TAILSCALE_IP>:8181/mcp"
    },
    "mcpvault": {
      "url": "http://<YOUR_TAILSCALE_IP>:8182/mcp"
    }
  }
}
```

**Get your Tailscale IP:**
```bash
tailscale ip -4
```

## Architecture Details

### Why Localhost Binding?

```yaml
# docker-compose.yml
ports:
  - "127.0.0.1:8181:8181"  # NOT "0.0.0.0:8181:8181"
```

Binding to `127.0.0.1` ensures:
- Services are unreachable from local network (e.g., `192.168.1.x`)
- Only localhost processes can connect
- Tailscale serve acts as the secure gateway

### How Tailscale Serve Works

1. **On your Mac**: `tailscale serve --bg --set-path=/qmd 127.0.0.1:8181`
2. **Tailscale creates a reverse proxy** on your tailscale IP
3. **External devices** connect through Tailscale's authenticated tunnel
4. **Your Mac's firewall** never sees inbound connections - they're handled by Tailscale

### Network Flow

```
Other Device → Tailscale Tunnel → Your Mac (Tailscale) 
                                    ↓
                              tailscale serve
                                    ↓
                              localhost:8181
                                    ↓
                              Docker → QMD Container
```

## Shared Vault

Both services mount the same vault at `/vault`:

```yaml
volumes:
  - "/path/to/your/vault:/vault"
```

## Management Commands

```bash
# View service logs
docker-compose logs -f qmd
docker-compose logs -f mcpvault

# Restart services
docker-compose restart

# Stop everything
docker-compose down

# Check tailscale serve status
tailscale serve status

# Stop tailscale serve
tailscale serve --https=0 --http=0

# Reinstall LaunchAgent
./tailscale/install-launchagent.sh

# Remove auto-start
./tailscale/uninstall-launchagent.sh
```

## Troubleshooting

### Services not accessible from other devices

1. Check Tailscale is connected: `tailscale status`
2. Verify tailscale serve: `tailscale serve status`
3. Test locally first: `curl http://127.0.0.1:8181/health`
4. Check Docker containers: `docker ps`

### LaunchAgent not starting

```bash
# Check logs
cat /tmp/tailscale-serve-pkm.error.log
cat /tmp/tailscale-serve-pkm.log

# Manually load
launchctl load ~/Library/LaunchAgents/com.tailscale.serve.pkm.plist
launchctl start com.tailscale.serve.pkm
```

### Connection refused from other devices

Ensure you're using the **Tailscale IP** (100.x.x.x), not localhost:
```bash
# Wrong (only works on host machine)
curl http://127.0.0.1:8181/mcp

# Right (works from any tailnet device)
curl http://$(tailscale ip -4):8181/mcp
```

## Individual Services

See detailed documentation:
- **[./qmd/README.md](./qmd/)** - QMD semantic search setup and usage
- **[./mcpvault/README.md](./mcpvault/)** - MCPVault direct vault access

## Security Checklist

- [ ] Services bind to `127.0.0.1` only (verify in `docker-compose.yml`)
- [ ] Tailscale serve is configured (`tailscale serve status`)
- [ ] LaunchAgent installed for auto-start (optional but recommended)
- [ ] Verified no exposure on local network (check `netstat -an | grep 8181`)
- [ ] MCP clients configured with Tailscale IP, not localhost

## Requirements

- macOS with Docker Desktop
- Tailscale installed and authenticated
- Obsidian vault at the configured path
