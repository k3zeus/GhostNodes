#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║   GhostNodes — Tailscale Module Installer                   ║
# ║   Mesh VPN + Subnet Router                                  ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Usage: sudo bash tailscale/install.sh [--yolo]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="${SCRIPT_DIR}/docker"
ENV_FILE="${DOCKER_DIR}/.env"
ENV_EXAMPLE="${DOCKER_DIR}/.env.example"

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
echo "  ║          GhostNode — Tailscale Module Installer              ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
printf "\033[0m\n"

# ── Root check ────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    step_err "Execute como root: sudo bash tailscale/install.sh"
    exit 1
fi

# ── Docker check ──────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
    step_err "Docker not found. Install Docker first."
    exit 1
fi

# ── Verify TUN device ────────────────────────────────────────
step_info "Checking /dev/net/tun..."
if [ ! -c /dev/net/tun ]; then
    step_info "Creating TUN device..."
    mkdir -p /dev/net
    mknod /dev/net/tun c 10 200
    chmod 0666 /dev/net/tun
    step_ok "TUN device created"
else
    step_ok "TUN device exists"
fi

# ── Enable IP forwarding (persistent) ────────────────────────
step_info "Enabling IP forwarding..."
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
fi
sysctl -w net.ipv4.ip_forward=1 >/dev/null
sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null
step_ok "IP forwarding enabled"

# ── Copy .env ─────────────────────────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    step_warn ".env created from example"
    if [ "$YOLO" = false ]; then
        printf "\n  \033[2mOptional:\033[0m Set \033[1mTS_AUTHKEY\033[0m for automated auth\n"
        printf "  \033[2mOr leave empty to authenticate via URL\033[0m\n\n"
        printf "  Edit: \033[1m%s\033[0m\n\n" "$ENV_FILE"
        read -p "  Press Enter to continue..."
    fi
fi

# ── Bring up Tailscale ───────────────────────────────────────
step_info "Starting Tailscale..."
cd "$DOCKER_DIR"
docker compose up -d

# ── Check auth status ────────────────────────────────────────
sleep 3
step_info "Checking Tailscale authentication status..."

AUTH_STATUS=$(docker exec ghostnode-tailscale tailscale status 2>&1 || true)
if echo "$AUTH_STATUS" | grep -q "NeedsLogin"; then
    echo ""
    step_warn "Tailscale needs authentication!"
    echo ""
    docker exec ghostnode-tailscale tailscale up \
        --advertise-routes="$(grep -oP 'TS_ROUTES=\K.*' "$ENV_FILE" 2>/dev/null || echo '10.21.21.0/24')" \
        --hostname=ghostnode \
        --accept-routes 2>&1 | grep -oP 'https://.*' || true
    echo ""
    step_info "Open the URL above to authenticate."
    step_info "Then approve subnet routes in Tailscale Admin Console."
else
    step_ok "Tailscale is connected"
fi

# ── Summary ───────────────────────────────────────────────────
echo ""
printf "\033[1m\033[0;32m"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Tailscale Module Installed!"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "\033[0m"
printf "\n"
printf "  \033[2mPost-install:\033[0m\n"
printf "    1. Go to \033[1mhttps://login.tailscale.com/admin/machines\033[0m\n"
printf "    2. Find 'ghostnode' and \033[1mapprove subnet routes\033[0m\n"
printf "    3. Install Tailscale on your PC/phone\n"
printf "    4. Access GhostNode services via Tailscale IP\n"
printf "\n"
printf "  \033[2mUseful commands:\033[0m\n"
printf "    \033[1mdocker exec ghostnode-tailscale tailscale status\033[0m\n"
printf "    \033[1mdocker exec ghostnode-tailscale tailscale ip\033[0m\n"
printf "\n"
