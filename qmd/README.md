# QMD MCP Server

[QMD](https://github.com/tobi/qmd) (Query Markup Documents) with Jina AI embeddings and reranking for semantic search through your Obsidian vault.

> **Fork lineage**: This uses [`pluginmd/qmd`](https://github.com/pluginmd/qmd), an enhanced fork of upstream `tobi/qmd`. It adds Jina AI as a remote provider for embeddings and reranking — fully portable to server environments without a GPU.

## Features

- **MCP Server**: Runs on port 8181 for AI agent integration
- **Interactive CLI**: Access via `docker exec` for manual queries
- **Remote Embeddings**: Uses Jina AI API for embeddings — no local GPU required
- **Remote Reranking**: Uses Jina AI API for reranking — full hybrid search quality
- **Fast Embeddings**: ~5 seconds for 35 books via Jina API vs ~40 seconds locally
- **Persistent Storage**: Index survives container resets (stored in Docker volume)
- **Hybrid Search**: BM25 + Vector search with Jina AI re-ranking

## Quick Start

```bash
# Start just QMD
docker-compose up -d qmd

# Access CLI
docker exec -it qmd-server bash

# Search
qmd query "time management techniques"
```

## Auto-Initialized Collections

On first start, QMD automatically creates collections based on your `config.json` file. Each collection maps a vault folder to a searchable index with a descriptive context.

### Configuration

1. Copy the example configuration from the repo root:
   ```bash
   cp ../config.example.json ../config.json
   ```

2. Edit `config.json` to define your collections:
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

3. Place `config.json` in the repo root (next to `docker-compose.yml`)

### How It Works

- Collections are **only created if the directories exist** in your vault
- Each collection gets a context description that helps AI queries understand what's in the collection
- The index is persisted across container restarts via the `qmd-cache` Docker volume
- No collections are hardcoded - everything comes from your `config.json`

### Manual Collection Management

You can also add collections manually via CLI:

```bash
# From inside the container
docker exec -it qmd-server bash

# Add a collection
qmd collection add /vault/path/to/folder --name my-collection
qmd context add qmd://my-collection "Description of this collection"
qmd embed  # Re-index
```

## MCP Server Usage

The MCP server runs on `http://localhost:8181/mcp`

### Claude Desktop Configuration

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "qmd": {
      "url": "http://localhost:8181/mcp"
    }
  }
}
```

### Available MCP Tools

- `query` - Search with typed sub-queries (lex/vec/hyde), combined via RRF + reranking
- `get` - Retrieve a document by path or docid
- `multi_get` - Batch retrieve by glob pattern
- `status` - Index health and collection info

## CLI Commands

```bash
# Keyword search (BM25)
qmd search "productivity"

# Vector search (semantic similarity)
qmd vsearch "how to focus better"

# Hybrid search (best quality - BM25 + vectors + reranking)
qmd query "time management techniques"

# Get a specific book
qmd get "Book Deep Work.md"

# List all collections
qmd collection list

# Check status
qmd status
```

## Environment Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `QMD_EMBED_PROVIDER` | `jina` | Use Jina AI for embeddings |
| `QMD_RERANK_PROVIDER` | `jina` | Use Jina AI for reranking |
| `JINA_API_KEY` | *from .env* | Your Jina AI API key |
| `QMD_CONFIG_PATH` | `/config.json` | Path to collections config file |

## Architecture

- **Base Image**: `oven/bun:1-debian` (Bun runtime)
- **QMD Source**: [`pluginmd/qmd`](https://github.com/pluginmd/qmd) — enhanced fork of upstream `tobi/qmd` with Jina AI remote provider support
- **Document Embeddings**: Jina jina-embeddings-v3 (1024 dimensions, 8192 ctx)
- **Query Embeddings**: Jina jina-embeddings-v3 (1024 dimensions, 8192 ctx)
- **Reranking**: Jina jina-reranker-v2-base-multilingual
- **Database**: SQLite with FTS5 + sqlite-vec extension

## Troubleshooting

```bash
# View logs
docker logs qmd-server

# Rebuild after changes
docker-compose up -d --build qmd

# Reset index
docker exec qmd-server rm /root/.cache/qmd/index.sqlite
```

## References

- [QMD Original](https://github.com/tobi/qmd) - Tobi Lutke's original project
- [pluginmd/qmd](https://github.com/pluginmd/qmd) - Enhanced fork with Jina AI remote provider, observability, and secrets hygiene
- [MCP Protocol](https://modelcontextprotocol.io/) - Model Context Protocol specification
