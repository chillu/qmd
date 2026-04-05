# Obsidian PKM MCP Servers

Docker Compose setup running two independent MCP servers that share access to your Obsidian vault.

## Services

| Service | Port | Description |
|---------|------|-------------|
| [QMD](./qmd/) | 8181 | Semantic search with OpenAI embeddings for Obsidian notes |
| [MCPVault](./mcpvault/) | 8182 | Direct vault access for AI agents |

## Quick Start

```bash
# Start both services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

## Shared Vault

Both services mount the same vault at `/vault`:

```yaml
volumes:
  - "/path/to/your/vault:/vault"
```

## Individual Services

See the README in each service directory for detailed documentation:

- **[./qmd/README.md](./qmd/)** - QMD semantic search setup and usage
- **[./mcpvault/README.md](./mcpvault/)** - MCPVault direct vault access
