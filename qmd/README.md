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

## Adding Collections

From inside the container:

```bash
qmd collection add /vault --name vault
qmd context add qmd://vault "Obsidian vault notes"
qmd embed
```

## Architecture

- **Base Image**: `oven/bun:1-debian` (Bun runtime)
- **QMD Fork**: `chillu/qmd:feat/openai-embeddings-clean`
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
- [chillu Fork](https://github.com/chillu/qmd/tree/feat/openai-embeddings-clean) - Working OpenAI embeddings
- [MCP Protocol](https://modelcontextprotocol.io/) - Model Context Protocol specification
