# Obsidian PKM MCP Servers

Secure Docker Compose setup running two independent MCP servers for your Obsidian vault. **All services are protected by Tailscale** - no exposure to local networks.

## Security Model

```
┌─────────────────────────────────────────────────────────────┐
│  Your Mac (Host)                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Tailscale Network (Authenticated)                     │ │
│  │  ┌─────────────┐     ┌─────────────────────────────┐   │ │
│  │  │ Tailscale   │────▶│  https://<hostname>/qmd    │   │ │
│  │  │ Serve       │     │  https://<hostname>/mcpvault│   │ │
│  │  └─────────────┘     └─────────────────────────────┘   │ │
│  │         │                        │                      │ │
│  │         │   (Tailscale proxies   │                      │ │
│  │         ▼    to localhost)       ▼                      │ │
│  │  ┌─────────────────────────────────────────────────┐   │ │
│  │  │  Localhost Only (Docker containers)             │   │ │
│  │  │  • 127.0.0.1:8181 → QMD (semantic search)      │   │ │
│  │  │  • 127.0.0.1:8182 → MCPVault (vault access)    │   │ │
│  │  │  • 127.0.0.1:50880 → MCP Connector             │   │ │
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
- ✅ Services bind only to `127.0.0.1` inside Docker (not exposed on local network)
- ✅ **Zero exposure** to local WiFi/coffee shop networks
- ✅ Tailscale serve proxies from tailnet to localhost securely
- ✅ Access only through authenticated Tailscale connections
- ✅ No firewall rules or port forwarding needed
- ✅ Automatic end-to-end encryption via Tailscale

## Services

| Service | Local Port | Tailscale Path | Description |
|---------|-----------|----------------|-------------|
| [QMD](./qmd/) | 8181 | `/qmd` | Semantic search with Jina AI embeddings |
| [MCPVault](./mcpvault/) | 8182 | `/mcpvault` | Direct vault access for AI agents |
| [MCP Connector](./mcp-connector/) | 50880 | `/mcp-connector` | **Docker-isolated** TypingMind bridge |

## Configuration

Before starting, copy the example configuration files:

```bash
cp .env.example .env
cp config.example.json config.json
```

Then edit them with your settings:

### 1. Set Your Vault Path

Edit `.env` and set your Obsidian vault path:

```bash
# .env
VAULT_PATH=/Users/yourname/Documents/ObsidianVault
```

### 2. Configure QMD Collections (Optional)

QMD can automatically index specific folders in your vault as "collections" for semantic search.

1. **Copy the example configuration:**
   ```bash
   cp config.example.json config.json
   ```

2. **Customize `config.json`** with your collections:
   ```json
   {
     "collections": {
       "books": {
         "path": "books",
         "description": "Book notes and highlights from reading"
       },
       "notes": {
         "path": "notes",
         "description": "General Obsidian vault notes"
       }
     }
   }
   ```

   - `path`: Folder path **relative to your vault root**
   - `description`: Context description for AI queries

3. **Place `config.json` next to your `.env` file** (in the repo root, not inside your vault)

> **Note:** `config.json` is gitignored - it won't be committed to version control.

### 3. Add Your Jina AI API Key

Get a free API key at [jina.ai](https://jina.ai/). Then add it to `.env`:

```bash
# .env
JINA_API_KEY=jina_your_api_key_here
```

The `QMD_EMBED_PROVIDER` and `QMD_RERANK_PROVIDER` variables are already set to `jina` in `docker-compose.yml`, so you don't need to change them unless you want to switch backends.

## Why pluginmd/qmd?

We use [`pluginmd/qmd`](https://github.com/pluginmd/qmd) — an enhanced fork of upstream [`tobi/qmd`](https://github.com/tobi/qmd) — for our semantic search backend. Here's why:

### GPU-Free Server Deployment

Upstream QMD runs embedding and reranking models locally via `node-llama-cpp`, which requires a GPU for acceptable performance. `pluginmd/qmd` adds a **polymorphic provider backend** that lets us delegate the heavy work to remote APIs:

- **Embeddings** → Jina AI `jina-embeddings-v3` (1024-dim, 8192 token context)
- **Reranking** → Jina AI `jina-reranker-v2-base-multilingual`
- **Query expansion** → still runs locally (latency-critical, ~1.1B parameter model)

This makes the stack fully portable to CPU-only servers, CI runners, and low-end laptops.

### Trade-offs

| Aspect | Local (upstream) | Jina Remote (this fork) |
|--------|-----------------|------------------------|
| Embedding speed | ~40s for 35 books | ~5s for 35 books |
| GPU required | Yes for comfort | No |
| Multilingual | English-biased | 89 languages (including CJK) |
| Query expansion | Fast on GPU | 10–15s cold start on CPU |
| Privacy | Fully offline | Documents sent to Jina API |

**The main downside:** Query expansion always runs locally (it's not delegated to Jina), so the first `qmd query` after container restart has a ~10–15 second cold-start while the 1.1B parameter model loads into RAM. After that, the model stays warm. For fast repeated queries, use `qmd search` (BM25 only) or `qmd vsearch` (vector only) — neither needs query expansion.

### What About OpenAI?

We previously experimented with [`tobi/qmd` PR #619](https://github.com/tobi/qmd/pull/619) (OpenAI-compatible backend) on a separate branch. It works for embeddings and query expansion, but OpenAI has no `/v1/rerank` endpoint — so reranking silently fails and falls back to RRF-only scoring. Jina gives us the full hybrid pipeline.

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

Both services mount the same vault at `/vault`. The vault path is configured via the `VAULT_PATH` environment variable in `.env`:

```yaml
# docker-compose.yml
volumes:
  - "${VAULT_PATH}:/vault"
```

Set this in your `.env` file:
```bash
VAULT_PATH=/path/to/your/vault
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

## Connection URLs

After setting up `tailscale serve`, your services are available at:

| Service | URL | For |
|---------|-----|-----|
| QMD | `https://<YOUR_HOSTNAME>/qmd/mcp` | Direct MCP access |
| MCPVault | `https://<YOUR_HOSTNAME>/mcpvault/mcp` | Direct MCP access |
| MCP Connector | `https://<YOUR_HOSTNAME>/mcp-connector` | TypingMind integration |

**Get your hostname:**
```bash
tailscale status | head -1
# Output: 100.x.x.x  your-hostname  user@  macOS  -
#                   ^^^^^^^^^^^^^
#                   Your hostname
```

**Example:** If your hostname is `your-hostname.tailXXXX.ts.net`:
- QMD: `https://your-hostname.tailXXXX.ts.net/qmd/mcp`
- MCP Connector: `https://your-hostname.tailXXXX.ts.net/mcp-connector`

### For iOS/iPhone Users

If your iPhone can't resolve the MagicDNS hostname, you have two options:

**Option A: Fix iOS DNS** (recommended)
- See [docs/ios-troubleshooting.md](./docs/ios-troubleshooting.md)
- Usually just needs Tailscale app restart or DNS toggle

**Option B: Use IP-Based Connection** (if DNS won't work)
```
http://<TAILSCALE_IP>:<PORT>
```

However, note that the current setup uses `tailscale serve` which creates HTTPS endpoints on the **hostname**, not the IP. For IP-based access, you'd need to either:
1. Accept that IP access requires using HTTP (not HTTPS) which is still encrypted by Tailscale
2. Set up custom SSL certificates for your Tailscale IP

## Troubleshooting

### Services not accessible from other devices

1. **Verify Tailscale is connected on both devices:**
   ```bash
   # On your Mac
tailscale status
   # Should show both your Mac and iPhone connected
   ```

2. **Check tailscale serve is running:**
   ```bash
   tailscale serve status
   # Should show /qmd, /mcpvault, and /mcp-connector
   ```

3. **Test from this Mac first:**
   ```bash
   # Get your auth token
   TOKEN=$(docker logs typingmind-mcp-connector | grep "Auth Token:" | tail -1 | sed 's/.*Auth Token: //')
   
   # Test via Tailscale hostname
   curl -H "Authorization: Bearer $TOKEN" \
        https://$(tailscale ip -4 | xargs dig +short -x | cut -d' ' -f1)/mcp-connector/ping
   ```

4. **Check Docker containers:** `docker ps`

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

**Symptom:** Can access from this Mac, but not from iPhone or other tailnet devices.

**Most likely cause:** Your Tailscale IP has changed.

**Fix:**
```bash
# Run the IP checker to detect and fix
./tailscale/check-tailscale-ip.sh
```

**Alternative:** Access directly via IP instead of hostname:
```bash
# Get current Tailscale IP
TAILSCALE_IP=$(tailscale ip -4)

# Use this IP in your MCP clients
echo "Use: http://${TAILSCALE_IP}:50880"
```

## Individual Services

See detailed documentation:
- **[./qmd/README.md](./qmd/)** - QMD semantic search setup and usage
- **[./mcpvault/README.md](./mcpvault/)** - MCPVault direct vault access

## Security Checklist

- [ ] Services bind to `127.0.0.1` only in Docker (verify in `docker-compose.yml`)
- [ ] Verified no exposure on local network: `netstat -an | grep -E "8181|8182|50880"` (should show only 127.0.0.1)
- [ ] Tailscale serve is configured (`tailscale serve status` shows all three endpoints)
- [ ] LaunchAgent installed for auto-start (optional but recommended)
- [ ] MCP clients configured with Tailscale hostname (e.g., `your-hostname.tailXXXX.ts.net`)

## Requirements

- macOS with Docker Desktop
- Tailscale installed and authenticated
- Obsidian vault at the configured path
