#!/bin/bash
# Check and update Tailscale IP binding if it has changed
# Run this script if your MCP services become unreachable after Tailscale reconnects

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/../docker-compose.yml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=== Tailscale IP Checker ==="
echo ""

# Determine Tailscale binary
if [ -f "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]; then
    TAILSCALE="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
elif command -v tailscale &> /dev/null; then
    TAILSCALE="tailscale"
else
    echo -e "${RED}Error: Tailscale not found${NC}"
    exit 1
fi

# Get current Tailscale IP
CURRENT_IP=$($TAILSCALE ip -4 2>/dev/null || echo "")

if [ -z "$CURRENT_IP" ]; then
    echo -e "${RED}Error: Could not get Tailscale IP. Is Tailscale connected?${NC}"
    exit 1
fi

echo -e "${BLUE}Current Tailscale IP:${NC} $CURRENT_IP"

# Get IP from docker-compose
COMPOSE_IP=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:50880' "$COMPOSE_FILE" | head -1 | cut -d: -f1)

if [ -z "$COMPOSE_IP" ]; then
    echo -e "${YELLOW}Warning: Could not find existing IP binding in docker-compose.yml${NC}"
    echo "Looking for port 50880 binding..."
    COMPOSE_IP=$(grep -A2 '50880:50880' "$COMPOSE_FILE" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
fi

if [ -n "$COMPOSE_IP" ]; then
    echo -e "${BLUE}IP in docker-compose.yml:${NC} $COMPOSE_IP"
    
    if [ "$CURRENT_IP" = "$COMPOSE_IP" ]; then
        echo ""
        echo -e "${GREEN}✓ IPs match! No update needed.${NC}"
        exit 0
    else
        echo ""
        echo -e "${YELLOW}⚠ IP mismatch detected!${NC}"
        echo "  Current: $CURRENT_IP"
        echo "  Config:  $COMPOSE_IP"
        echo ""
    fi
else
    echo -e "${YELLOW}Could not detect current IP in docker-compose.yml${NC}"
    echo "Will attempt to update with current IP: $CURRENT_IP"
    echo ""
fi

# Ask for confirmation
echo "This will:"
echo "  1. Update docker-compose.yml with IP: $CURRENT_IP"
echo "  2. Restart the mcp-connector container"
echo ""
read -p "Proceed? (y/N) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Update docker-compose.yml
echo ""
echo "Updating docker-compose.yml..."

# Update all Tailscale IP bindings in the file (for qmd, mcpvault, mcp-connector)
sed -i.bak "s/[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+:\(8181\|8182\|50880\):\1/$CURRENT_IP:\1:\1/g" "$COMPOSE_FILE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Updated docker-compose.yml${NC}"
    # Remove backup
    rm -f "$COMPOSE_FILE.bak"
else
    echo -e "${RED}Error: Failed to update docker-compose.yml${NC}"
    exit 1
fi

# Restart the container
echo ""
echo "Restarting mcp-connector container..."
cd "$SCRIPT_DIR/.."
docker-compose up -d --no-deps mcp-connector

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Container restarted successfully${NC}"
else
    echo -e "${RED}Error: Failed to restart container${NC}"
    exit 1
fi

# Get new auth token
echo ""
echo "Getting new auth token..."
sleep 2
NEW_TOKEN=$(docker logs typingmind-mcp-connector 2>&1 | grep "Auth Token:" | tail -1 | sed 's/.*Auth Token: //')

if [ -n "$NEW_TOKEN" ]; then
    echo -e "${BLUE}New Auth Token:${NC} $NEW_TOKEN"
    echo ""
    echo "Update this token in your TypingMind MCP settings!"
else
    echo -e "${YELLOW}Could not retrieve auth token. Check logs with:${NC}"
    echo "  docker logs typingmind-mcp-connector | grep 'Auth Token:'"
fi

echo ""
echo "=== Update Complete ==="
echo ""
echo "Your MCP Connector is now bound to: $CURRENT_IP:50880"
echo "This IP will remain stable as long as your device stays in the tailnet."
