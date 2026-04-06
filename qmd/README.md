# QMD MCP Server

[QMD](https://github.com/tobi/qmd) (Query Markup Documents) with OpenAI embeddings for semantic search through your Obsidian vault.

> **Fork lineage**: This uses `chillu/qmd`, a fork of `alexleach/qmd`, which tracks upstream `tobi/qmd`. The chillu fork includes working OpenAI embeddings support for both document indexing and queries.

## Features

- **MCP Server**: Runs on port 8181 for AI agent integration
- **Interactive CLI**: Access via `docker exec` for manual queries  
- **Full OpenAI Integration**: Uses OpenAI API for **both** document embeddings and query embeddings (1536-dim)
- **Fast Embeddings**: ~5 seconds for 35 books via OpenAI API vs ~40 seconds locally
- **Persistent Storage**: Index survives container resets (stored in Docker volume)
- **Hybrid Search**: BM25 + Vector search with re-ranking

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
| `QMD_OPENAI` | `1` | Enable OpenAI-compatible mode |
| `OPENAI_BASE_URL` | `https://api.openai.com/v1` | OpenAI API endpoint |
| `OPENAI_API_KEY` | *from .env* | Your OpenAI API key |
| `QMD_CONFIG_PATH` | `/config.json` | Path to collections config file |

## Architecture

- **Base Image**: `oven/bun:1-debian` (Bun runtime)
- **QMD Fork**: [`chillu/qmd:feat/openai-embeddings-clean`](https://github.com/chillu/qmd/tree/feat/openai-embeddings-clean) (based on [alexleach's PR #480](https://github.com/tobi/qmd/pull/480) to `tobi/qmd`)
- **Document Embeddings**: OpenAI text-embedding-3-small (1536 dimensions)
- **Query Embeddings**: OpenAI text-embedding-3-small (1536 dimensions)
- **Reranking**: OpenAI gpt-4o-mini
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
- [alexleach Fork](https://github.com/alexleach/qmd/tree/feat/openai-embeddings-clean) - OpenAI embeddings implementation
- [tobi/qmd PR #480](https://github.com/tobi/qmd/pull/480) - Original OpenAI embeddings PR
- [chillu Fork](https://github.com/chillu/qmd/tree/feat/openai-embeddings-clean) - Contains MCP server fixes
- [MCP Protocol](https://modelcontextprotocol.io/) - Model Context Protocol specification
