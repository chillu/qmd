#!/bin/bash
# Setup Tailscale serve for all Obsidian PKM services including MCP Connector
# This exposes your services ONLY through Tailscale (not local network)

set -e

# Determine Tailscale binary path
if [ -f "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]; then
    TAILSCALE="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
elif command -v tailscale &> /dev/null; then
    TAILSCALE="tailscale"
else
    echo "Error: Tailscale not found. Please install Tailscale."
    exit 1
fi

echo "=== Tailscale Serve Setup for Obsidian PKM ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Tailscale is running
if ! pgrep -x "Tailscale" > /dev/null 2>&1; then
    echo -e "${RED}Error: Tailscale is not running. Please start Tailscale first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Tailscale is running${NC}"

# Get Tailscale info
TAILSCALE_IP=$($TAILSCALE ip -4 2>/dev/null || echo "")
TAILSCALE_HOSTNAME=$($TAILSCALE status --json 2>/dev/null | grep -o '"DNSName":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")

if [ -z "$TAILSCALE_IP" ]; then
    echo -e "${RED}Error: Could not get Tailscale IP. Is Tailscale connected?${NC}"
    exit 1
fi

echo ""
echo "Tailscale IP: $TAILSCALE_IP"
if [ -n "$TAILSCALE_HOSTNAME" ]; then
    echo "Tailscale Hostname: $TAILSCALE_HOSTNAME"
fi
echo ""

# Check if Docker containers are running
echo "Checking Docker containers..."
if ! docker ps | grep -q "qmd-server"; then
    echo -e "${YELLOW}⚠ Warning: qmd-server container is not running${NC}"
    echo "  Start it with: docker-compose up -d qmd"
fi

if ! docker ps | grep -q "mcpvault-server"; then
    echo -e "${YELLOW}⚠ Warning: mcpvault-server container is not running${NC}"
    echo "  Start it with: docker-compose up -d mcpvault"
fi

if ! docker ps | grep -q "typingmind-mcp-connector"; then
    echo -e "${YELLOW}⚠ Warning: typingmind-mcp-connector container is not running${NC}"
    echo "  Start it with: docker-compose up -d mcp-connector"
fi

# Setup tailscale serve
echo ""
echo "Setting up tailscale serve..."

echo "  Configuring /qmd -> localhost:8181..."
$TAILSCALE serve --bg --set-path=/qmd 127.0.0.1:8181 2>/dev/null || echo "    (Already configured or updating)"

echo "  Configuring /mcpvault -> localhost:8182..."
$TAILSCALE serve --bg --set-path=/mcpvault 127.0.0.1:8182 2>/dev/null || echo "    (Already configured or updating)"

echo "  Configuring /mcp-connector -> localhost:50880..."
$TAILSCALE serve --bg --set-path=/mcp-connector 127.0.0.1:50880 2>/dev/null || echo "    (Already configured or updating)"

echo ""
echo -e "${GREEN}✓ Tailscale serve configured!${NC}"
echo ""

# Display connection info
echo "=========================================="
echo "=== Connection URLs (Tailnet Only) ==="
echo "=========================================="
echo ""

echo -e "${BLUE}Direct MCP Server URLs:${NC}"
echo "  QMD:           https://${TAILSCALE_HOSTNAME:-<hostname>}/qmd/mcp"
echo "  MCPVault:      https://${TAILSCALE_HOSTNAME:-<hostname>}/mcpvault/mcp"
echo ""

echo -e "${BLUE}TypingMind MCP Connector:${NC}"
echo "  Connector URL: https://${TAILSCALE_HOSTNAME:-<hostname>}/mcp-connector"
echo "                 (Use this in TypingMind MCP settings)"
echo ""

echo "=========================================="
echo ""
echo "To get your MCP Connector Auth Token:"
echo "  docker logs typingmind-mcp-connector | grep 'Auth Token:'"
echo ""
echo "=== Security Note ==="
echo "These services are ONLY accessible through your Tailscale network."
echo "They are NOT exposed on your local network (e.g., 192.168.x.x)."
echo "Only devices signed into your tailnet can access these URLs."
echo ""
echo "To verify:"
echo "  $TAILSCALE serve status"
echo ""
echo "To disable:"
echo "  $TAILSCALE serve --https=0 --http=0"
