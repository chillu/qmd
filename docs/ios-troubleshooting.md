# iOS Troubleshooting Guide

## Problem: iPhone Can't Resolve MagicDNS Hostname

Even though Tailscale is enabled on iOS with MagicDNS, sometimes iOS devices can't resolve `.ts.net` hostnames. This is a known issue with iOS DNS handling.

## Solution 1: Use Tailscale IP Address (Recommended)

Instead of the hostname, use your Mac's **Tailscale IP** directly:

**Replace:**
```
https://your-hostname.tailXXXX.ts.net/mcp-connector
```

**With:**
```
http://100.x.x.x:50880
```

### URLs for iOS:

| Service | iOS URL |
|---------|---------|
| MCP Connector | `http://100.x.x.x:50880` |
| QMD | `http://100.x.x.x:8181/mcp` |
| MCPVault | `http://100.x.x.x:8182/mcp` |

**Note:** Use `http://` not `https://` when using IP addresses, unless you configure custom SSL certificates.

## Solution 2: iOS DNS Troubleshooting

If you want to use hostnames, try these steps:

### Step 1: Force Quit Tailscale App
1. Double-tap home button / swipe up from bottom
2. Find Tailscale app
3. Swipe up to force quit
4. Reopen Tailscale

### Step 2: Toggle MagicDNS
1. Open Tailscale app on iPhone
2. Go to Settings (gear icon)
3. Toggle "Use Tailscale DNS" OFF
4. Wait 5 seconds
5. Toggle it back ON

### Step 3: Restart Tailscale Connection
1. In Tailscale app, tap the toggle to disconnect
2. Wait 5 seconds
3. Tap to reconnect

### Step 4: Test DNS Resolution
Open Safari and try:
```
http://your-hostname.tailXXXX.ts.net:50880/ping
```

Or use the Tailscale IP directly:
```
http://100.x.x.x:50880/ping
```

## Solution 3: Update TypingMind Configuration

### Option A: Use IP Address (Immediate fix)
In TypingMind iOS app:
- **Connector URL**: `http://100.x.x.x:50880`
- **Auth Token**: (same as before)

### Option B: Add Both URLs
Configure multiple MCP connectors:
1. One for Mac: `https://your-hostname.tailXXXX.ts.net/mcp-connector`
2. One for iPhone: `http://100.x.x.x:50880`

## Why This Happens

iOS has strict DNS handling that sometimes conflicts with Tailscale MagicDNS:
- iOS uses "DNS over HTTPS" (DoH) from the ISP by default
- Some carriers block or intercept DNS queries
- iOS may prioritize cellular DNS over VPN DNS
- MagicDNS can take time to sync on mobile devices

## Testing Connectivity

From your iPhone (with Tailscale connected):

1. **Test with Safari:**
   ```
   http://100.x.x.x:50880/ping
   ```
   Should return: `{"status":"ok"}`

2. **Test in Tailscale App:**
   - Open Tailscale app
   - Tap on your Mac (ingos-macbook-air)
   - Try to ping it

3. **Check iPhone Tailscale IP:**
   - In Tailscale app, your iPhone should show an IP like `100.94.x.x`
   - If no IP shown, you're not connected

## Persistent Fix

If you want hostnames to work reliably:

1. Use **Solution 1 (IP addresses)** for now
2. File a bug with Tailscale support about iOS MagicDNS issues
3. Consider using a **custom domain** with Tailscale Funnel (requires paid plan)

## Summary

**For immediate use on iPhone:**
- Connector URL: `http://100.x.x.x:50880`
- Auth Token: (from `docker logs typingmind-mcp-connector`)

This bypasses DNS entirely and connects directly via Tailscale's encrypted tunnel.
