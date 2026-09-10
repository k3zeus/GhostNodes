# GhostNodes Architecture 👻🛰️

## Overview
GhostNodes is a sovereign node orchestration system designed for ARM hardware (primarily OrangePi Zero 3). It focuses on network privacy, Bitcoin self-sovereignty, AI assistance, and local-first management.

---

## 1. Networking Infrastructure
The core of GhostNodes is its multi-layer network isolation strategy.

- **`wlan0` (Access Point - Private):**
  - SSID: `GHOST_NODE_XXXX`
  - Subnet: `10.21.21.0/24`
  - Purpose: Internal management interface. Only trusted devices connect here to access the Dashboard and Node services.
- **`wlan1` (Client - Gateway):**
  - Purpose: Internet egress. Connects to the home Wi-Fi or public hotspot.
  - Hardening: No incoming ports allowed on this interface except through established tunnels.
- **`end0` (Wired - Emergency):**
  - Purpose: Direct connection via Ethernet for setup or headless recovery.
- **Tailscale (Mesh VPN):**
  - Purpose: Zero-config secure mesh network for remote access to all services.
  - Mode: Subnet Router — advertises AP network (10.21.21.0/24) and Docker network (172.17.0.0/16).
- **Cloudflare Tunnel (External Access):**
  - Purpose: Zero-port external access via Cloudflare's edge network.
  - Services: Vaultwarden, Open WebUI (optional), Nostr Relay (optional).

---

## 2. System Components
GhostNodes is composed of several specialized layers:

### A. NodeNation (The Core)
- **Role:** The main shell-based CLI orchestrator.
- **Features:** Updates, repository synchronization, and service management.
- **Repository:** Synchronized with `k3zeus/GhostNodes/beta`.

### B. Satoshi Node (Bitcoin Tier)
- **Engine:** Bitcoin Core (`bitcoind`).
- **Integration:** Managed via RPC. Provides the verification status to the Web Dashboard.

### C. Guardian & HoneyPot (Security Layer)
- **Integrity:** Periodic checks of system binaries.
- **HoneyPot:** Simulated open ports (e.g., 2222) to trap and block malicious actors on the local network.
- **Logs:** Real-time event streaming to the Dashboard.

### D. Vault (Credentials & SSH Gateway) 🔐
- **Engine:** Vaultwarden (Bitwarden-compatible).
- **SSH Gateway:** ed25519 master key + hardened sshd for all homelab access.
- **Backup:** AES-256-CBC encrypted key archives stored in Vaultwarden.
- **Access:** Internal via Nginx (port 8812) | External via Cloudflare Tunnel.

### E. Hermes (AI Assistant) 🤖
- **Engine:** Open WebUI (API-only mode — no local LLM).
- **Providers:** OpenRouter (200+ models), OpenAI, Google AI.
- **Telegram Bridge:** Custom bot that forwards messages to Open WebUI API.
- **Access:** Internal via Nginx (port 8813) | Telegram Bot.

### F. Nostr Relay 📡
- **Engine:** nostr-rs-relay (Rust, SQLite).
- **Mode:** Private relay with pubkey whitelist.
- **Bridge Pattern:** Client-side federation — phone connects to both private + public relays.
- **Access:** Internal via Nginx WebSocket (port 8814) | Optional Cloudflare Tunnel.

---

## 3. Web Dashboard Orchestration
Modern glassmorphism interface for decentralized monitoring.

- **Frontend:** React (Vite) + Framer Motion + Lucide Icons.
- **Backend:** FastAPI (Python 3.14+) + JWT Authentication.
- **Service Discovery:** Dynamic port checking for tools like Cockpit (9090), Pi-hole v6 (80), Syncthing (8384), Vaultwarden (8812), Open WebUI (8813).

---

## 4. Docker Network Architecture
All Dockerized modules share a common `ghostnet` external network:

```
                    ┌─── ghostnet (Docker bridge) ───┐
                    │                                 │
  Nginx ◄──────────┼── Vaultwarden (port 80)         │
    │               │── Open WebUI (port 8080)        │
    │               │── Nostr Relay (port 8080)       │
    │               │── Cloudflared                   │
    │               └─────────────────────────────────┘
    │
    └── Halfin services (Heimdall, Syncthing, etc.)

  Tailscale (host network) ── advertises all subnets
```

---

## 5. Environment Adaptation (Hardware Agnostic)
The system is designed to be "Hardware Aware":
1. **Sensors:** Adaptive path hunting for `thermal_zone` and `hwmon`.
2. **Interfaces:** Dynamic mapping of network names (`end0`, `eth0`, `wlan0`, etc.).
3. **Mocks:** Smart fallbacks when running in dev environments (Windows/macOS).

---

## 6. Directory Structure
```text
GhostNodes/
├── nodenation           # Main CLI Binary/Script
├── modules-install.sh   # Master module orchestrator
├── web/                 # Dashboard (React/FastAPI)
├── halfin/              # Networking, Tools & Nginx
│   └── docker/nginx/    # Reverse proxy configs for all modules
├── satoshi/             # Bitcoin Core Layer
├── vault/               # 🔐 SSH Gateway + Vaultwarden
│   ├── docker/          # Compose + .env
│   └── ssh/             # Key generation & backup scripts
├── hermes/              # 🤖 AI Assistant
│   └── docker/          # Open WebUI + Telegram bridge
│       └── telegram/    # Bot source + Dockerfile
├── tailscale/           # 🌐 Mesh VPN Subnet Router
│   └── docker/          # Compose + .env
├── nostr/               # 📡 Private Nostr Relay
│   └── docker/          # Compose + config.toml
├── docs/                # Technical Docs
└── var/                 # Persistence and Logs
```

---

## 7. Service Port Map

| Service | Internal Port | Nginx SSL Port | Protocol |
|---------|--------------|----------------|----------|
| Vaultwarden | 80 | 8812 | HTTPS |
| Open WebUI | 8080 | 8813 | HTTPS |
| Nostr Relay | 8080 | 8814 | WSS |
| Dashboard | 5173 | — | HTTP |
| Cockpit | 9090 | — | HTTPS |
| Syncthing | 8384 | — | HTTPS |

---

## 8. Language Policy
GhostNodes follows an **Open-Source English-First** policy.
- Documentation: English (Primary), Portuguese (Summary/Bilingual).
- Codebase: English.
- User Interface: English (Standard), Multi-lang planned.

---

*Last Updated: May 2026 — v2.0 Expansion Modules*
