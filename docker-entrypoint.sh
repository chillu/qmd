#!/bin/bash
set -e

# Export environment variables
export QMD_OPENAI=1
export OPENAI_BASE_URL=https://api.openai.com/v1
export PATH=/app/bin:$PATH
export VAULT_PATH=${VAULT_PATH:-/vault}
export MCPVAULT_PORT=${MCPVAULT_PORT:-8182}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a port is listening
check_port() {
    local port=$1
    local timeout=${2:-15}
    local count=0
    while ! nc -z localhost $port 2>/dev/null; do
        sleep 1
        count=$((count + 1))
        if [ $count -ge $timeout ]; then
            return 1
        fi
    done
    return 0
}

# Function to check if MCPVault is responding
check_mcpvault() {
    local port=$1
    local timeout=${2:-15}
    local count=0
    while ! curl -s http://localhost:$port/health > /dev/null 2>&1; do
        sleep 1
        count=$((count + 1))
        if [ $count -ge $timeout ]; then
            return 1
        fi
    done
    return 0
}

# Start QMD MCP server in background
echo "[QMD] Starting MCP server on port 8181..."
qmd mcp --http --port 8181 &
QMD_PID=$!

# Start MCPVault HTTP server in background
echo "[MCPVault] Starting MCP server on port ${MCPVAULT_PORT}..."
echo "[MCPVault] Serving vault: ${VAULT_PATH}"
cd /app/mcpvault && bun run mcpvault-http.ts &
MCPVAULT_PID=$!
echo "[MCPVault] PID: $MCPVAULT_PID"
cd /app

# Wait for both servers to be ready
echo ""
echo "Waiting for servers to be ready..."
echo ""

# Give servers a moment to start
sleep 3

# Check QMD
if check_port 8181 15; then
    echo -e "${GREEN}✓${NC} QMD MCP server is running (PID: $QMD_PID)"
    echo -e "  Endpoint: http://localhost:8181/mcp"
else
    echo -e "${RED}✗${NC} QMD MCP server failed to start"
    kill $MCPVAULT_PID 2>/dev/null || true
    exit 1
fi

# Check MCPVault
if check_mcpvault $MCPVAULT_PORT 15; then
    echo -e "${GREEN}✓${NC} MCPVault server is running (PID: $MCPVAULT_PID)"
    echo -e "  Endpoint: http://localhost:${MCPVAULT_PORT}/sse"
    echo -e "  Vault: ${VAULT_PATH}"
else
    echo -e "${RED}✗${NC} MCPVault server failed to start"
    # Check if process is still running
    if kill -0 $MCPVAULT_PID 2>/dev/null; then
        echo -e "  Process is running but health check is not responding"
    else
        echo -e "  Process has died"
    fi
    kill $QMD_PID 2>/dev/null || true
    kill $MCPVAULT_PID 2>/dev/null || true
    exit 1
fi

echo ""
echo "================================================"
echo -e "${GREEN}Both MCP servers are ready!${NC}"
echo "================================================"
echo ""
echo "QMD Server (Books Collection):"
echo "  http://localhost:8181/mcp"
echo ""
echo "MCPVault Server (Obsidian Vault):"
echo "  http://localhost:${MCPVAULT_PORT}/mcp"
echo "  Vault path: ${VAULT_PATH}"
echo ""
echo "CLI Access:"
echo "  docker exec -it mcp-servers bash"
echo ""
echo "QMD Quick Start:"
echo "  qmd collection add /collections/books --name books"
echo "  qmd context add qmd://books 'Book notes and summaries'"
echo "  qmd embed"
echo "  qmd query 'your search query'"
echo "================================================"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Shutting down servers..."
    kill $QMD_PID 2>/dev/null || true
    kill $MCPVAULT_PID 2>/dev/null || true
    wait
    echo "Servers stopped."
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Monitor both processes and keep container running
while true; do
    # Check if either process died
    if ! kill -0 $QMD_PID 2>/dev/null; then
        echo -e "${RED}✗${NC} QMD server (PID: $QMD_PID) stopped unexpectedly"
        kill $MCPVAULT_PID 2>/dev/null || true
        exit 1
    fi
    if ! kill -0 $MCPVAULT_PID 2>/dev/null; then
        echo -e "${RED}✗${NC} MCPVault server (PID: $MCPVAULT_PID) stopped unexpectedly"
        kill $QMD_PID 2>/dev/null || true
        exit 1
    fi
    sleep 5
done
