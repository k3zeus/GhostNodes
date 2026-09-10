#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║   GhostNodes v2.0 — Master Module Installer                 ║
# ║   Orchestrates: Tailscale → Vault → Hermes → Nostr          ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Usage:
#   sudo bash modules-install.sh               # Interactive (all)
#   sudo bash modules-install.sh --yolo         # Automated (all)
#   sudo bash modules-install.sh vault          # Single module
#   sudo bash modules-install.sh hermes --yolo  # Single + automated
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Parse args ────────────────────────────────────────────────
MODULE="${1:-all}"
YOLO_FLAG=""
[[ "${1:-}" == "--yolo" ]] && MODULE="all" && YOLO_FLAG="--yolo"
[[ "${2:-}" == "--yolo" ]] && YOLO_FLAG="--yolo"

# ── Source GhostNode lib if available ─────────────────────────
[ -f "${SCRIPT_DIR}/lib/init.sh" ] && source "${SCRIPT_DIR}/lib/init.sh" 2>/dev/null || {
    info()  { printf "\033[0;36m[INFO]\033[0m  %s\n" "$1"; }
    ok()    { printf "\033[0;32m[OK]\033[0m    %s\n" "$1"; }
    err()   { printf "\033[0;31m[ERR]\033[0m   %s\n" "$1"; }
    warn()  { printf "\033[2m[WARN]\033[0m  %s\n" "$1"; }
    step_info() { info "$1"; }
    step_ok()   { ok "$1"; }
    step_err()  { err "$1"; }
    step_warn() { warn "$1"; }
}

# ── Root check ────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    err "Execute como root: sudo bash modules-install.sh [module] [--yolo]"
    exit 1
fi

echo ""
printf "\033[1m\033[0;36m"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║          GhostNodes v2.0 — Module Installer                  ║"
echo "  ║                                                              ║"
echo "  ║    🔐 Vault    🤖 Hermes    🌐 Tailscale    📡 Nostr        ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
printf "\033[0m\n"

# ── Docker check ──────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
    step_err "Docker not found. Install Docker first."
    exit 1
fi

# ── Create shared network ────────────────────────────────────
step_info "Creating shared Docker network 'ghostnet'..."
docker network inspect ghostnet &>/dev/null || docker network create ghostnet
step_ok "Network 'ghostnet' ready"

# ── Generate self-signed SSL cert for Nginx ──────────────────
SSL_DIR="${SCRIPT_DIR}/halfin/docker/nginx/ssl"
if [ ! -f "${SSL_DIR}/ghostnode.crt" ]; then
    step_info "Generating self-signed SSL certificate for internal Nginx..."
    mkdir -p "$SSL_DIR"
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
        -keyout "${SSL_DIR}/ghostnode.key" \
        -out "${SSL_DIR}/ghostnode.crt" \
        -subj "/C=BR/ST=RJ/L=Local/O=GhostNodes/CN=ghostnode.local" \
        -addext "subjectAltName=DNS:*.ghostnode.local,DNS:ghostnode.local" \
        2>/dev/null
    step_ok "SSL cert generated: ${SSL_DIR}/ghostnode.crt (valid 10 years)"
fi

# ── Connect existing Nginx to ghostnet ───────────────────────
step_info "Connecting existing Nginx container to ghostnet..."
docker network connect ghostnet nginx 2>/dev/null && step_ok "Nginx joined ghostnet" || step_warn "Nginx already on ghostnet or not running"

# ── Install modules ──────────────────────────────────────────
install_module() {
    local name="$1"
    local dir="$2"

    echo ""
    printf "\033[1m═══ Installing: %s ═══\033[0m\n\n" "$name"

    if [ -f "${dir}/install.sh" ]; then
        bash "${dir}/install.sh" $YOLO_FLAG
        step_ok "${name} installation complete"
    else
        step_err "Installer not found: ${dir}/install.sh"
    fi
}

case "$MODULE" in
    all)
        # Order matters: Tailscale first (provides network access)
        install_module "Tailscale (Mesh VPN)"      "${SCRIPT_DIR}/tailscale"
        install_module "Vault (SSH + Passwords)"    "${SCRIPT_DIR}/vault"
        install_module "Hermes (AI Assistant)"      "${SCRIPT_DIR}/hermes"
        install_module "Nostr (Relay)"              "${SCRIPT_DIR}/nostr"
        ;;
    tailscale) install_module "Tailscale" "${SCRIPT_DIR}/tailscale" ;;
    vault)     install_module "Vault"     "${SCRIPT_DIR}/vault" ;;
    hermes)    install_module "Hermes"    "${SCRIPT_DIR}/hermes" ;;
    nostr)     install_module "Nostr"     "${SCRIPT_DIR}/nostr" ;;
    *)
        err "Unknown module: $MODULE"
        echo "  Available: all, tailscale, vault, hermes, nostr"
        exit 1
        ;;
esac

# ── Final Summary ────────────────────────────────────────────
echo ""
printf "\033[1m\033[0;32m"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║           GhostNodes v2.0 — Installation Complete!           ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
printf "\033[0m\n"

echo "  Running containers:"
docker ps --format "    {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "vaultwarden|hermes|tailscale|nostr" || echo "    (none from new modules)"
echo ""

printf "\033[2m  Service Map (Internal — via Tailscale):\033[0m\n"
printf "    🔐 Vaultwarden:    https://<tailscale-ip>:8812\n"
printf "    🤖 Open WebUI:     https://<tailscale-ip>:8813\n"
printf "    📡 Nostr Relay:    wss://<tailscale-ip>:8814\n"
printf "    🌐 Tailscale IP:   docker exec ghostnode-tailscale tailscale ip\n"
echo ""

printf "\033[2m  Service Map (External — via Cloudflare Tunnel):\033[0m\n"
printf "    🔐 Vaultwarden:    https://vault.yourdomain.com\n"
printf "    🤖 Open WebUI:     https://hermes.yourdomain.com (optional)\n"
printf "    📡 Nostr Relay:    wss://nostr.yourdomain.com (optional)\n"
echo ""

printf "\033[1m  Next steps:\033[0m\n"
printf "    1. Configure Cloudflare Tunnel routes in Zero Trust dashboard\n"
printf "    2. Approve Tailscale subnet routes in admin console\n"
printf "    3. Create accounts in Vaultwarden and Open WebUI\n"
printf "    4. Set up Telegram bot with @BotFather\n"
printf "    5. Add Nostr relay to your mobile client\n"
echo ""
