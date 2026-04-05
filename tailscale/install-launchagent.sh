#!/bin/bash
# Install LaunchAgent to auto-start Tailscale serve on macOS login

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_NAME="com.tailscale.serve.pkm.plist"
PLIST_SOURCE="$SCRIPT_DIR/$PLIST_NAME"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"

echo "=== Installing Tailscale Serve LaunchAgent ==="
echo ""

# Check if plist exists
if [ ! -f "$PLIST_SOURCE" ]; then
    echo "Error: $PLIST_NAME not found in $SCRIPT_DIR"
    exit 1
fi

# Copy plist to LaunchAgents
cp "$PLIST_SOURCE" "$PLIST_DEST"
echo "✓ Copied $PLIST_NAME to ~/Library/LaunchAgents/"

# Load the LaunchAgent
launchctl load "$PLIST_DEST" 2>/dev/null || launchctl bootstrap gui/$(id -u) "$PLIST_DEST"
echo "✓ Loaded LaunchAgent"

# Start it immediately
launchctl start "$PLIST_NAME" 2>/dev/null || true
echo "✓ Started service"

echo ""
echo "=== Installation Complete ==="
echo ""
echo "The LaunchAgent will:"
echo "  • Auto-start Tailscale serve when you log in"
echo "  • Expose qmd on /qmd path (localhost:8181)"
echo "  • Expose mcpvault on /mcpvault path (localhost:8182)"
echo "  • Expose mcp-connector on /mcp-connector path (localhost:50880)"
echo "  • Wait 30 seconds after login for Tailscale to connect"
echo ""
echo "To verify it's running:"
echo "  /Applications/Tailscale.app/Contents/MacOS/Tailscale serve status"
echo "  (or just 'tailscale serve status' if tailscale is in your PATH)"
echo ""
echo "To uninstall:"
echo "  ./tailscale/uninstall-launchagent.sh"
