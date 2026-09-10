#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║   GhostNodes — Nostr Module Installer                       ║
# ║   nostr-rs-relay (Private Sovereign Relay)                  ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Usage: sudo bash nostr/install.sh [--yolo]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="${SCRIPT_DIR}/docker"
ENV_FILE="${DOCKER_DIR}/.env"
ENV_EXAMPLE="${DOCKER_DIR}/.env.example"
CONFIG_FILE="${DOCKER_DIR}/config.toml"
CONFIG_EXAMPLE="${DOCKER_DIR}/config.toml.example"

# ── Source GhostNode lib if available ─────────────────────────
_GN_ROOT="$(dirname "$SCRIPT_DIR")"
[ -f "${_GN_ROOT}/lib/init.sh" ] && source "${_GN_ROOT}/lib/init.sh" 2>/dev/null || {
    info()  { printf "\033[0;36m[INFO]\033[0m  %s\n" "$1"; }
    ok()    { printf "\033[0;32m[OK]\033[0m    %s\n" "$1"; }
    err()   { printf "\033[0;31m[ERR]\033[0m   %s\n" "$1"; }
    warn()  { printf "\033[2m[WARN]\033[0m  %s\n" "$1"; }
    step_info() { info "$1"; }
    step_ok()   { ok "$1"; }
    step_err()  { err "$1"; }
    step_warn() { warn "$1"; }
}

YOLO=false
[[ "${1:-}" == "--yolo" ]] && YOLO=true

echo ""
printf "\033[1m\033[0;36m"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║          GhostNode — Nostr Module Installer                  ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
printf "\033[0m\n"

# ── Root check ────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    step_err "Execute como root: sudo bash nostr/install.sh"
    exit 1
fi

# ── Docker check ──────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
    step_err "Docker not found. Install Docker first."
    exit 1
fi

# ── Create shared Docker network ─────────────────────────────
step_info "Ensuring 'ghostnet' Docker network exists..."
docker network inspect ghostnet &>/dev/null || {
    docker network create ghostnet
    step_ok "Network 'ghostnet' created"
}

# ── Copy configs ─────────────────────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    step_ok ".env created"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_EXAMPLE" "$CONFIG_FILE"
    step_warn "config.toml created from example."
    step_warn "IMPORTANT: Add your pubkey to pubkey_whitelist!"
    if [ "$YOLO" = false ]; then
        printf "\n  Edit: \033[1m%s\033[0m\n" "$CONFIG_FILE"
        printf "  Add your hex pubkey to the whitelist to publish events.\n\n"
        read -p "  Press Enter after editing config.toml..."
    fi
fi

# ── Create data directory with correct permissions ───────────
step_info "Setting up data directory..."
DATA_DIR="${DOCKER_DIR}/nostr-data"
mkdir -p "$DATA_DIR"
chown 100:100 "$DATA_DIR"
chmod 755 "$DATA_DIR"
step_ok "Data directory ready"

# ── Bring up containers ──────────────────────────────────────
step_info "Starting Nostr Relay..."
cd "$DOCKER_DIR"
docker compose up -d

# ── Verify ───────────────────────────────────────────────────
sleep 3
if docker ps --format '{{.Names}}' | grep -q "ghostnode-nostr"; then
    step_ok "Nostr relay is running"
else
    step_err "Nostr relay failed to start — check: docker logs ghostnode-nostr"
fi

# ── Summary ───────────────────────────────────────────────────
echo ""
printf "\033[1m\033[0;32m"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Nostr Module Installed!"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "\033[0m"
printf "  \033[2mRelay WS:\033[0m     \033[1mws://localhost:7700 (internal)\033[0m\n"
printf "  \033[2mTailscale:\033[0m    \033[1mws://<tailscale-ip>:7700\033[0m\n"
printf "\n"
printf "  \033[2mPost-install:\033[0m\n"
printf "    1. Edit \033[1mconfig.toml\033[0m and add your hex pubkey to whitelist\n"
printf "    2. Add relay in your Nostr client:\n"
printf "       - Amethyst (Android): Settings → Relays → ws://<ip>:7700\n"
printf "       - Damus (iOS): Settings → Relays → ws://<ip>:7700\n"
printf "    3. Optional: Configure Cloudflare Tunnel for external WSS access\n"
printf "\n"
