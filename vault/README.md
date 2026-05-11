# Vault Module — SSH Gateway + Vaultwarden 🔐

## Overview
The Vault module provides two critical functions:
1. **SSH Key Gateway** — Centralized ed25519 master key for accessing all homelab devices
2. **Vaultwarden** — Self-hosted Bitwarden-compatible password manager for storing credentials, SSH keys, and secrets

## Architecture
```
Internet ──→ Cloudflare Tunnel ──→ vaultwarden:80
                                       │
Tailscale ──→ Nginx ──→───────────────→─┘
                │
LAN (wlan0) ───┘
```

## Quick Start
```bash
sudo bash vault/install.sh        # Interactive mode
sudo bash vault/install.sh --yolo  # Automated mode
```

## Components

### Vaultwarden (Docker)
- **Image:** `vaultwarden/server:latest`
- **Internal Port:** 80 (HTTP), 3012 (WebSocket)
- **Data:** `./vw-data/` (SQLite database + attachments)
- **Network:** `ghostnet` (shared with Nginx/Cloudflared)

### SSH Gateway
- **Key Type:** ed25519 (modern, secure, fast)
- **Location:** `/home/pleb/.ssh/ghostnode_master`
- **Hardening:** Password auth disabled, root login restricted, max 3 auth tries

## Security Checklist
- [ ] Set a strong `VW_ADMIN_TOKEN` (use `openssl rand -base64 48`)
- [ ] Create your account, then set `VW_SIGNUPS=false`
- [ ] Enable 2FA on your Vaultwarden account
- [ ] Configure Cloudflare Tunnel in Zero Trust dashboard
- [ ] Run `backup-keys.sh` to encrypt and store SSH keys
- [ ] Test SSH login with master key before disabling password auth

## Disaster Recovery
1. SSH keys are encrypted with AES-256-CBC and stored in `vault/ssh/backups/`
2. Upload encrypted backup to Vaultwarden as a Secure Note attachment
3. To restore: `openssl enc -d -aes-256-cbc -pbkdf2 -in backup.tar.gz.enc -out backup.tar.gz`

## Cloudflare Tunnel Configuration
In your Cloudflare Zero Trust dashboard:
1. Go to **Networks → Tunnels → your tunnel → Public Hostname**
2. Add hostname: `vault.yourdomain.com`
3. Service: `http://vaultwarden:80`
4. Save and deploy

---
*GhostNodes Vault — Your keys, your rules.*
