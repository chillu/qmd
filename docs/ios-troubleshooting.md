# iOS Troubleshooting Guide

## Problem: iPhone Can't Connect to Tailscale Services

Even though Tailscale is enabled on iOS, you may not be able to connect to services on your tailnet from iPhone/iPad.

## Most Common Cause: iCloud Private Relay

**iCloud Private Relay** is the #1 cause of Tailscale connectivity issues on iOS.

### How to Check and Fix

1. **Open Settings** on your iPhone
2. Tap your **name/Apple ID** at the top
3. Tap **iCloud**
4. Tap **Private Relay**
5. **Turn it OFF**

**Alternative path:**
- Settings → Apple ID → iCloud → Private Relay → **Off**

### Why This Happens

iCloud Private Relay:
- Routes your DNS queries through Apple's servers
- Can override Tailscale's MagicDNS
- May block connections to Tailscale IPs (100.x.x.x)
- Can prevent Safari from resolving .ts.net domains

### Test After Disabling

After turning off Private Relay:

1. **Wait 10-30 seconds** for network to reconfigure
2. **Open Safari**
3. Navigate to: `https://your-hostname.tailXXXX.ts.net/mcp-connector/ping`
4. Should show: `{"status":"ok"}`

## Other iOS Issues

### Safari Content Blockers

Content blockers (like AdGuard, 1Blocker) may block .ts.net domains:

1. Settings → Safari → Extensions
2. Turn off all content blockers temporarily
3. Test connection
4. Re-enable one by one to find the culprit

### Screen Time Web Restrictions

If Screen Time is enabled with web restrictions:

1. Settings → Screen Time → Content & Privacy Restrictions
2. Content Restrictions → Web Content
3. If set to "Limit Adult Websites", try "Unrestricted"
4. Or add `.ts.net` to allowed sites

### DNS Over HTTPS (DoH) from Carrier

Some cellular carriers enable DoH which conflicts with Tailscale:

1. Settings → Wi-Fi → [Your Network] → Configure DNS
2. Set to "Automatic" (not Manual)
3. Or try: Settings → General → VPN & Device Management → DNS
4. Delete any custom DNS profiles

### Tailscale App Issues

If Tailscale app shows "Active" but connections fail:

1. **Force quit** Tailscale app (swipe up, find Tailscale, swipe up)
2. **Reopen** Tailscale app
3. Wait for "Active" status
4. Try connection again

### MagicDNS Not Resolving

If DNS works for some services (like homeassistant) but not others:

**Different services may use different exposure methods:**
- **Home Assistant** might use Tailscale Funnel (public HTTPS)
- **Your services** use Tailscale Serve (tailnet-only)
- Funnel works differently than Serve

**Check your service URL format:**
- ✅ `https://hostname.ts.net/path` (Tailscale Serve/Funnel)
- ❌ `http://100.x.x.x:port` (raw IP - often blocked by iOS)

## Quick Diagnostic Checklist

- [ ] iCloud Private Relay: **OFF**
- [ ] Tailscale app: **Active** (green)
- [ ] Safari content blockers: **Disabled** (for testing)
- [ ] Screen Time web restrictions: **Unrestricted** (for testing)
- [ ] Connected to WiFi or cellular with data

## If Nothing Works

Try using **Chrome or Firefox** on iOS instead of Safari:

1. Download Chrome from App Store
2. Try accessing: `https://your-hostname.tailXXXX.ts.net/mcp-connector/ping`
3. Some browsers handle Tailscale differently

## Related Issues

### Can Resolve DNS But Not Connect

If Safari shows "Cannot Open Page" but you can ping the hostname:
- Likely Private Relay or content blocker
- Try the fixes above

### Works on WiFi But Not Cellular

Cellular carriers sometimes block Tailscale:
- Toggle airplane mode on/off
- Check if carrier has "VPN" restrictions
- Some business/corporate plans block Tailscale

### Works on Mac But Not iPhone

iOS has stricter network policies than macOS:
- All the above iOS-specific restrictions apply
- macOS doesn't have Private Relay in the same way

## Summary

**For iPhone access to work:**
1. ✅ Tailscale enabled and Active
2. ✅ **iCloud Private Relay: OFF**
3. ✅ No content blockers interfering
4. ✅ Using MagicDNS hostname (not raw IP)
5. ✅ HTTPS URLs work better than HTTP on iOS

**The most common fix:** Just turn off iCloud Private Relay.
