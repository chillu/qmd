#!/bin/bash
# Uninstall Tailscale serve LaunchAgent

set -e

# Determine Tailscale binary path
if [ -f "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]; then
    TAILSCALE="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
elif command -v tailscale &> /dev/null; then
    TAILSCALE="tailscale"
else
    echo "Warning: Tailscale not found, using 'tailscale' as default"
    TAILSCALE="tailscale"
fi

PLIST_NAME="com.tailscale.serve.pkm.plist"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME"

echo "=== Uninstalling Tailscale Serve LaunchAgent ==="
echo ""

# Stop if running
launchctl stop "$PLIST_NAME" 2>/dev/null || true
echo "✓ Stopped service"

# Unload
launchctl unload "$PLIST_PATH" 2>/dev/null || true
echo "✓ Unloaded LaunchAgent"

# Remove plist
if [ -f "$PLIST_PATH" ]; then
    rm "$PLIST_PATH"
    echo "✓ Removed $PLIST_NAME"
fi

# Stop tailscale serve
echo ""
echo "Stopping tailscale serve..."
$TAILSCALE serve --https=0 --http=0 2>/dev/null || true
echo "✓ Stopped tailscale serve"

echo ""
echo "=== Uninstall Complete ==="
