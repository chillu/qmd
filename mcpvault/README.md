# MCPVault Server

[MCPVault](https://github.com/bitbonsai/mcpvault) provides direct access to your Obsidian vault through the Model Context Protocol.

## Features

- **Vault Access**: Read and browse your Obsidian vault files
- **MCP Server**: Runs on port 8182 for AI agent integration
- **SSE Transport**: Server-Sent Events for real-time communication
- **File Operations**: List directories, read files, search notes

## Quick Start

```bash
# Start just MCPVault
docker-compose up -d mcpvault

# View logs
docker logs mcpvault-server
```

## MCP Server Usage

The MCP server runs on `http://localhost:8182/sse`

### Claude Desktop Configuration

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "mcpvault": {
      "url": "http://localhost:8182/sse"
    }
  }
}
```

### Available MCP Tools

- `list_vault` - List contents of vault directories
- `read_file` - Read contents of vault files
- `search_vault` - Search for files matching patterns

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VAULT_PATH` | `/vault` | Path to Obsidian vault inside container |
| `MCPVAULT_PORT` | `8182` | HTTP server port |

## Endpoints

| Endpoint | Description |
|----------|-------------|
| `http://localhost:8182/sse` | MCP SSE connection |
| `http://localhost:8182/health` | Health check |

## Troubleshooting

```bash
# View logs
docker logs mcpvault-server

# Rebuild after changes
docker-compose up -d --build mcpvault
```

## References

- [MCPVault](https://github.com/bitbonsai/mcpvault) - Original project
- [MCP Protocol](https://modelcontextprotocol.io/) - Model Context Protocol specification
