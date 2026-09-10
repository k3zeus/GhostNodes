# Nostr Module — Private Sovereign Relay 📡

## Overview
A private Nostr relay running `nostr-rs-relay` (Rust, SQLite) on your GhostNode. It acts as your **personal relay** — a private bridge between your devices and the Nostr network.

## How Privacy Bridging Works

> **"Access other relays, but keep connected clients private"**

This is achieved through **client-side federation** (the standard Nostr architecture):

```
┌────────────────────────────────────────────────────────────┐
│                        YOUR PHONE                           │
│                    (Amethyst/Damus/Primal)                   │
│                                                              │
│            ┌──────────────┐    ┌──────────────────┐         │
│            │ GhostNode    │    │ Public Relays     │         │
│            │ Relay (WSS)  │    │ relay.damus.io    │         │
│            │ PRIVATE      │    │ nos.lol           │         │
│            │ Whitelist    │    │ relay.nostr.band   │         │
│            └──────┬───────┘    └────────┬─────────┘         │
│                   │                      │                    │
│                   ▼                      ▼                    │
│            ┌──────────────────────────────────┐              │
│            │       Merged Event Feed          │              │
│            │  (your client shows all events)  │              │
│            └──────────────────────────────────┘              │
└────────────────────────────────────────────────────────────┘
```

### How it works:
1. **Your GhostNode relay** stores YOUR events privately (whitelist mode)
2. **Your Nostr client** connects to BOTH your private relay AND public relays
3. **Publishing:** Your client sends events to all configured relays
4. **Reading:** Your client merges events from all relays into one feed
5. **Privacy:** Public relays see your events but never see your private relay's IP — they only see your phone's IP (or Tailscale IP if tunneled)

### What this gives you:
- ✅ **Private backup** of all your Nostr events on your own hardware
- ✅ **Offline access** to your notes/DMs when public relays are down
- ✅ **Full federation** with the public Nostr network via your client
- ✅ **No metadata leakage** from your home server to public relays
- ✅ **Fast local access** via Tailscale (no internet latency)

## Quick Start
```bash
sudo bash nostr/install.sh        # Interactive
sudo bash nostr/install.sh --yolo  # Automated
```

## Configuration

### 1. Add Your Pubkey to Whitelist
Edit `docker/config.toml`:
```toml
[authorization]
pubkey_whitelist = [
    "your_hex_pubkey_here"
]
```

To convert npub to hex:
```bash
# Using nak CLI tool
nak decode npub1your_npub_here

# Or visit https://nostr.guru/
```

### 2. Connect Your Mobile Client

#### Amethyst (Android)
1. Settings → Relays
2. Add: `ws://<ghostnode-tailscale-ip>:7700`
3. Set as "Read + Write"
4. Keep public relays active for federation

#### Damus (iOS)
1. Settings → Relays
2. Add: `ws://<ghostnode-tailscale-ip>:7700`

#### Primal
1. Settings → Network → Relays
2. Add your relay URL

### 3. External Access (Optional)
For access outside Tailscale, configure Cloudflare Tunnel:
1. In CF Zero Trust → Tunnels → Public Hostname
2. Add: `nostr.yourdomain.com`
3. Service: `http://ghostnode-nostr:8080`
4. Add response header: `Upgrade: websocket`
5. Use `wss://nostr.yourdomain.com` in your client

## Storage Management
```bash
# Check relay database size
docker exec ghostnode-nostr du -sh /usr/src/app/db/

# Backup relay data
docker run --rm -v nostr_nostr_data:/data -v $(pwd):/backup alpine \
    tar czf /backup/nostr-backup.tar.gz -C /data .
```

## Useful Commands
```bash
# View relay logs
docker logs -f ghostnode-nostr

# Test WebSocket connection
websocat ws://localhost:7700

# Check relay info (NIP-11)
curl -H "Accept: application/nostr+json" http://localhost:7700
```

---
*GhostNodes Nostr — Your voice, your relay, your sovereignty.*
