#!/bin/bash
# Setup Tailscale serve for Obsidian PKM MCP servers
# This exposes your MCP services ONLY through Tailscale (not local network)

set -e

echo "=== Tailscale Serve Setup for Obsidian PKM ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Tailscale is running
if ! pgrep -x "Tailscale" > /dev/null; then
    echo -e "${RED}Error: Tailscale is not running. Please start Tailscale first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Tailscale is running${NC}"

# Get Tailscale info
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
TAILSCALE_HOSTNAME=$(tailscale status --json 2>/dev/null | grep -o '"DNSName":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")

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

# Setup tailscale serve
echo ""
echo "Setting up tailscale serve..."

# Clear any existing serve configurations for these ports (optional)
echo "  Configuring /qmd -> localhost:8181..."
tailscale serve --bg --set-path=/qmd 127.0.0.1:8181 2>/dev/null || true

echo "  Configuring /mcpvault -> localhost:8182..."
tailscale serve --bg --set-path=/mcpvault 127.0.0.1:8182 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ Tailscale serve configured!${NC}"
echo ""

# Display connection info
echo "=== Connection URLs ==="
echo ""
echo "QMD MCP Server:"
echo "  http://${TAILSCALE_IP}:8181/mcp"
if [ -n "$TAILSCALE_HOSTNAME" ]; then
    echo "  https://${TAILSCALE_HOSTNAME}/qmd/mcp"
fi

echo ""
echo "MCPVault Server:"
echo "  http://${TAILSCALE_IP}:8182/mcp"
if [ -n "$TAILSCALE_HOSTNAME" ]; then
    echo "  https://${TAILSCALE_HOSTNAME}/mcpvault/mcp"
fi

echo ""
echo "=== Security Note ==="
echo "These services are ONLY accessible through your Tailscale network."
echo "They are NOT exposed on your local network (e.g., 192.168.x.x)."
echo "Only devices signed into your tailnet can access these URLs."
echo ""
echo "To verify:"
echo "  tailscale serve status"
echo ""
echo "To disable:"
echo "  tailscale serve --https=0 --http=0"
