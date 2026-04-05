#!/bin/bash
set -e

export QMD_OPENAI=1
export OPENAI_BASE_URL=${OPENAI_BASE_URL:-https://api.openai.com/v1}
export PATH="/app/bin:$PATH"

echo "[QMD] Initializing vault collections..."

# Wait a moment for any filesystem mounts to settle
sleep 1

# Add default collections if vault directories exist
if [ -d "/vault/books" ]; then
    echo "[QMD] Adding books collection..."
    qmd collection add /vault/books --name books 2>/dev/null || echo "[QMD] Books collection already exists or failed"
    qmd context add qmd://books "Book notes and highlights from reading" 2>/dev/null || true
fi

if [ -d "/vault/notes" ]; then
    echo "[QMD] Adding notes collection..."
    qmd collection add /vault/notes --name notes 2>/dev/null || echo "[QMD] Notes collection already exists or failed"
    qmd context add qmd://notes "General Obsidian vault notes" 2>/dev/null || true
fi

# Run embed to index the collections
echo "[QMD] Running embed to index collections..."
qmd embed 2>/dev/null || echo "[QMD] Embed completed or nothing new to index"

echo "[QMD] Starting MCP server on port 8181..."
exec qmd mcp --http --port 8181 "$@"
