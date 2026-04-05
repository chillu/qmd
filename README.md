# QMD Docker Environment with OpenAI Embeddings

A Docker Compose setup for [QMD](https://github.com/tobi/qmd) (Query Markup Documents) using the [chillu fork](https://github.com/chillu/qmd/tree/feat/openai-embeddings-clean) with **full OpenAI embeddings support**.

> **Fork lineage**: This setup uses `chillu/qmd`, which is a fork of `alexleach/qmd`, which itself tracks the upstream `tobi/qmd`. The chillu fork includes patches to make OpenAI embeddings work properly for both document indexing and query embedding.

## Features

- **MCP Server**: Runs on port 8181 for AI agent integration
- **Interactive CLI**: Access via `docker exec` for manual queries  
- **Full OpenAI Integration**: Uses OpenAI API for **both** document embeddings and query embeddings (1536-dim)
- **Fast Embeddings**: ~5 seconds for 35 books via OpenAI API vs ~40 seconds locally
- **Persistent Storage**: Index survives container resets (stored in Docker volume)
- **Book Collection**: Pre-configured with your book notes from `Claw Notes/books`
- **Hybrid Search**: BM25 + Vector search with re-ranking

## Quick Start

### 1. Start the Environment

```bash
docker-compose up -d
```

### 2. Access the CLI

```bash
docker exec -it qmd bash
```

### 3. Search Your Books

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

## Project Structure

```
.
├── Dockerfile              # QMD with Bun runtime (chillu fork)
├── docker-compose.yml      # Service orchestration
├── docker-entrypoint.sh    # MCP server startup script
├── .env                    # API keys and configuration
└── README.md              # This file
```

## Data Persistence

Docker volumes ensure your data survives container resets:

| Volume | Container Path | Contents |
|--------|---------------|----------|
| `qmd-cache` | `/root/.cache/qmd` | SQLite index with OpenAI embeddings |
| Host bind | `/collections/books` | Your book notes (read-only) |

## Environment Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `QMD_OPENAI` | `1` | Enable OpenAI-compatible mode |
| `OPENAI_BASE_URL` | `https://api.openai.com/v1` | OpenAI API endpoint |
| `OPENAI_API_KEY` | *from .env* | Your OpenAI API key |

## Adding More Collections

To add additional folders as collections:

1. Edit `docker-compose.yml` and add volume mounts:
```yaml
volumes:
  - "/path/to/your/notes:/collections/notes:ro"
```

2. Restart and add the collection:
```bash
docker-compose restart
docker exec -it qmd bash
qmd collection add /collections/notes --name notes
qmd context add qmd://notes "Your notes description"
qmd embed
```

## Useful Commands

```bash
# View logs
docker logs qmd

# Restart container
docker-compose restart

# Reset everything (WARNING: destroys index)
docker-compose down -v
docker-compose up -d

# Interactive shell
docker exec -it qmd bash

# Run single command
docker exec qmd qmd search "your query"
```

## Architecture

This setup uses:
- **Base Image**: `oven/bun:1-debian` (Bun runtime)
- **QMD Fork**: `chillu/qmd:feat/openai-embeddings-clean`
- **Document Embeddings**: OpenAI text-embedding-3-small (1536 dimensions)
- **Query Embeddings**: OpenAI text-embedding-3-small (1536 dimensions)
- **Reranking**: OpenAI gpt-4o-mini
- **Database**: SQLite with FTS5 + sqlite-vec extension

## OpenAI Embeddings Patch

The chillu fork includes two critical patches to make OpenAI embeddings work properly:

1. **Document Embedding Fix** (`generateEmbeddings`): Bypasses the local LLM session wrapper and uses OpenAI directly when `QMD_OPENAI=1` is set.

2. **Query Embedding Fix** (`hybridQuery`): Uses `getDefaultEmbeddingLLM()` instead of `getLlm(store)` for batch query embedding, ensuring consistent 1536-dimensional embeddings.

Without these patches, the original alexleach fork had a dimension mismatch where:
- Documents were embedded with local model (768 dims)
- Queries were embedded with OpenAI (1536 dims)

## Troubleshooting

### Container won't start
```bash
docker-compose logs
```

### MCP server not responding
```bash
docker exec qmd ps aux | grep mcp
```

### Rebuild after changes
```bash
docker-compose down
docker-compose up -d --build
```

### Reset index and start fresh
```bash
docker exec qmd rm /root/.cache/qmd/index.sqlite
docker exec qmd qmd collection add /collections/books --name books
```

## References

- [QMD Original](https://github.com/tobi/qmd) - Tobi Lutke's original project
- [alexleach Fork](https://github.com/alexleach/qmd/tree/feat/openai-embeddings-clean) - Base OpenAI embeddings implementation
- [chillu Fork](https://github.com/chillu/qmd/tree/feat/openai-embeddings-clean) - Patched version with working OpenAI embeddings
- [MCP Protocol](https://modelcontextprotocol.io/) - Model Context Protocol specification
- [PR #480](https://github.com/tobi/qmd/pull/480) - Original OpenAI embeddings PR
