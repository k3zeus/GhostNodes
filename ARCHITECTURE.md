# GhostNodes Architecture 👻🛰️

## Overview
GhostNodes is a sovereign node orchestration system designed for ARM hardware (primarily OrangePi Zero 3). It focuses on network privacy, Bitcoin self-sovereignty, and local-first management.

---

## 1. Networking Infrastructure
The core of GhostNodes is its dual-interface network isolation strategy.

- **`wlan0` (Access Point - Private):**
  - SSID: `GHOST_NODE_XXXX`
  - Subnet: `10.21.21.0/24`
  - Purpose: Internal management interface. Only trusted devices connect here to access the Dashboard and Node services.
- **`wlan1` (Client - Gateway):**
  - Purpose: Internet egress. Connects to the home Wi-Fi or public hotspot.
  - Hardening: No incoming ports allowed on this interface except through established tunnels (optional).
- **`end0` (Wired - Emergency):**
  - Purpose: Direct connection via Ethernet for setup or headless recovery.

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

---

## 3. Web Dashboard Orchestration
Modern glassmorphism interface for decentralized monitoring.

- **Frontend:** React (Vite) + Framer Motion + Lucide Icons.
- **Backend:** FastAPI (Python 3.14+) + JWT Authentication.
- **Service Discovery:** Dynamic port checking for tools like Cockpit (9090), Pi-hole v6 (80), and Syncthing (8384).

---

## 4. Environment Adaptation (Hardware Agnostic)
The system is designed to be "Hardware Aware":
1. **Sensors:** Adaptive path hunting for `thermal_zone` and `hwmon`.
2. **Interfaces:** Dynamic mapping of network names (`end0`, `eth0`, `wlan0`, etc.).
3. **Mocks:** Smart fallbacks when running in dev environments (Windows/macOS).

---

## 5. Directory Structure
```text
GhostNodes/
├── nodenation       # Main CLI Binary/Script
├── web/             # Dashboard (React/FastAPI)
├── halfin/          # Networking & Tools
├── satoshi/         # Bitcoin Core Layer
├── docs/            # Technical Docs (this folder)
└── var/             # Persistence and Logs
```

---

## 6. Language Policy
GhostNodes follows an **Open-Source English-First** policy.
- Documentation: English (Primary), Portuguese (Summary/Bilingual).
- Codebase: English.
- User Interface: English (Standard), Multi-lang planned.

---

*Last Updated: April 2026*
