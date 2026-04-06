#!/bin/sh
set -e

# MCP Connector Entrypoint
# Automatically connects to QMD and MCPVault services

TOKEN_FILE="/data/.mcp_auth_token"

# Determine the auth token to use
if [ -n "$MCP_AUTH_TOKEN" ]; then
    # User provided a token via environment variable - use it
    echo "[MCP Connector] Using provided auth token from environment"
    FINAL_TOKEN="$MCP_AUTH_TOKEN"
elif [ -f "$TOKEN_FILE" ]; then
    # Use existing persisted token
    FINAL_TOKEN=$(cat "$TOKEN_FILE")
    echo "[MCP Connector] Using persisted auth token from $TOKEN_FILE"
else
    # Generate a new random token and persist it
    FINAL_TOKEN=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)
    # Save to file for persistence across restarts
    echo "$FINAL_TOKEN" > "$TOKEN_FILE"
    echo "[MCP Connector] Generated and persisted new auth token to $TOKEN_FILE"
    echo "[MCP Connector] Save this token! You'll need it for TypingMind configuration."
fi

export MCP_AUTH_TOKEN="$FINAL_TOKEN"

# Wait for services to be ready
echo "[MCP Connector] Waiting for QMD and MCPVault to be ready..."

# Wait for QMD (max 30 seconds)
for i in $(seq 1 30); do
    if curl -s http://qmd:8181/health > /dev/null 2>&1; then
        echo "[MCP Connector] QMD is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "[MCP Connector] Warning: QMD not responding, continuing anyway..."
    else
        sleep 1
    fi
done

# Wait for MCPVault (max 30 seconds)
for i in $(seq 1 30); do
    if curl -s http://mcpvault:8182/health > /dev/null 2>&1; then
        echo "[MCP Connector] MCPVault is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "[MCP Connector] Warning: MCPVault not responding, continuing anyway..."
    else
        sleep 1
    fi
done

echo ""
echo "=========================================="
echo "MCP Connector Configuration:"
echo "=========================================="
echo "Auth Token: $MCP_AUTH_TOKEN"
echo ""
echo "Internal Service URLs:"
echo "  QMD: http://qmd:8181/mcp"
echo "  MCPVault: http://mcpvault:8182/mcp"
echo ""
echo "When configuring TypingMind, you'll need to:"
echo "1. Use the Auth Token above"
echo "2. Configure these MCP servers in TypingMind's Edit Servers dialog"
echo ""
echo "Example server config:"
echo '{"
  "mcpServers": {
    "qmd": {
      "url": "http://qmd:8181/mcp"
    },
    "mcpvault": {
      "url": "http://mcpvault:8182/mcp"
    }
  }
}'
echo ""
echo "=========================================="
echo ""

# Start the MCP connector
echo "[MCP Connector] Starting server on port ${PORT:-50880}..."
exec npx @typingmind/mcp@latest "$MCP_AUTH_TOKEN"
