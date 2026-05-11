# Tailscale Module — Mesh VPN 🌐

## Overview
Tailscale creates a secure, zero-config mesh network between your GhostNode and all your devices. It runs as a **subnet router**, making every service on the node accessible from any device on your Tailscale network — without opening any ports.

## Architecture
```
┌──────────────────────────────────────────────────────┐
│   Your Devices (Tailscale installed)                  │
│                                                       │
│   PC ─────────┐                                       │
│   Phone ──────┤── Tailscale Network (WireGuard) ──┐  │
│   Laptop ─────┘                                    │  │
│                                                    ▼  │
│                              ┌─────────────────────┐  │
│                              │   GhostNode          │  │
│                              │   (Subnet Router)    │  │
│                              │                      │  │
│                              │   10.21.21.0/24 (AP) │  │
│                              │   172.17.0.0/16 (Docker)│
│                              │                      │  │
│                              │   Services:          │  │
│                              │   ├─ Vaultwarden     │  │
│                              │   ├─ Open WebUI      │  │
│                              │   ├─ Nostr Relay     │  │
│                              │   ├─ Dashboard       │  │
│                              │   └─ All containers  │  │
│                              └─────────────────────┘  │
└──────────────────────────────────────────────────────┘
```

## Quick Start
```bash
sudo bash tailscale/install.sh        # Interactive
sudo bash tailscale/install.sh --yolo  # Automated
```

## Prerequisites
1. **Tailscale Account** — Sign up at [tailscale.com](https://tailscale.com) (free for personal use, up to 100 devices)
2. **Auth Key** (optional) — Generate at [Admin Console → Settings → Keys](https://login.tailscale.com/admin/settings/keys)

## Post-Install Steps

### 1. Approve Subnet Routes
1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/machines)
2. Find the `ghostnode` machine
3. Click the `...` menu → Edit route settings
4. **Approve** the advertised subnets:
   - `10.21.21.0/24` (GhostNode AP network)
   - `172.17.0.0/16` (Docker containers)

### 2. Install Tailscale on Other Devices
- **Windows/Mac/Linux:** [tailscale.com/download](https://tailscale.com/download)
- **Android/iOS:** App Store / Play Store
- **Other servers:** `curl -fsSL https://tailscale.com/install.sh | sh`

### 3. Access Services
Once connected, access GhostNode services using the Tailscale IP:
```
http://<ghostnode-tailscale-ip>:3000   → Open WebUI (Hermes)
http://<ghostnode-tailscale-ip>:8812   → Vaultwarden
http://<ghostnode-tailscale-ip>:7700   → Nostr Relay
http://<ghostnode-tailscale-ip>:9090   → Cockpit
```

## ACL Recommendations
In your Tailscale Admin → Access Controls, add:
```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["tag:ghostnode:*"]
    }
  ],
  "tagOwners": {
    "tag:ghostnode": ["autogroup:admin"]
  }
}
```

## Useful Commands
```bash
# Check status
docker exec ghostnode-tailscale tailscale status

# Get Tailscale IP
docker exec ghostnode-tailscale tailscale ip

# Check advertised routes
docker exec ghostnode-tailscale tailscale status --json | jq '.Self.AllowedIPs'

# Re-authenticate
docker exec ghostnode-tailscale tailscale up --reset
```

---
*GhostNodes Tailscale — Your network, invisible.*
