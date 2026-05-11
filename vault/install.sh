#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║   GhostNodes — Vault Module Installer                        ║
# ║   Vaultwarden + SSH Gateway                                  ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Usage: sudo bash vault/install.sh [--yolo]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="${SCRIPT_DIR}/docker"
ENV_FILE="${DOCKER_DIR}/.env"
ENV_EXAMPLE="${DOCKER_DIR}/.env.example"

# ── Source GhostNode lib if available ─────────────────────────
_GN_ROOT="$(dirname "$SCRIPT_DIR")"
[ -f "${_GN_ROOT}/lib/init.sh" ] && source "${_GN_ROOT}/lib/init.sh" 2>/dev/null || {
    # Fallback minimal output functions
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
echo "  ║          GhostNode — Vault Module Installer                  ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
printf "\033[0m\n"

# ── Root check ────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    step_err "Execute como root: sudo bash vault/install.sh"
    exit 1
fi

# ── Docker check ──────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
    step_err "Docker not found. Install Docker first."
    exit 1
fi

if ! command -v docker compose &>/dev/null && ! command -v docker-compose &>/dev/null; then
    step_err "Docker Compose not found."
    exit 1
fi

# ── Create shared Docker network ─────────────────────────────
step_info "Ensuring 'ghostnet' Docker network exists..."
docker network inspect ghostnet &>/dev/null || {
    docker network create ghostnet
    step_ok "Network 'ghostnet' created"
}

# ── Copy .env ─────────────────────────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    step_warn ".env created from example — EDIT IT BEFORE CONTINUING"
    if [ "$YOLO" = false ]; then
        printf "\n  Edit: \033[1m%s\033[0m\n\n" "$ENV_FILE"
        read -p "  Press Enter after editing .env, or Ctrl+C to abort..."
    fi
fi

# ── Create data directory ────────────────────────────────────
VW_DATA=$(grep -oP 'VW_DATA_DIR=\K.*' "$ENV_FILE" 2>/dev/null || echo "./vw-data")
VW_DATA="${VW_DATA:-./vw-data}"
mkdir -p "${DOCKER_DIR}/${VW_DATA}"
step_ok "Data directory ready: ${VW_DATA}"

# ── Bring up containers ──────────────────────────────────────
step_info "Starting Vaultwarden..."
cd "$DOCKER_DIR"
docker compose up -d

# ── Wait for healthcheck ──────────────────────────────────────
step_info "Waiting for Vaultwarden to be healthy..."
for i in $(seq 1 30); do
    if docker inspect --format='{{.State.Health.Status}}' vaultwarden 2>/dev/null | grep -q "healthy"; then
        step_ok "Vaultwarden is healthy!"
        break
    fi
    sleep 2
done

# ── SSH Gateway Setup ────────────────────────────────────────
echo ""
step_info "Setting up SSH Gateway..."
if [ "$YOLO" = true ]; then
    bash "${SCRIPT_DIR}/ssh/setup-ssh-gateway.sh"
else
    read -p "  Setup SSH Gateway now? (Y/n): " DO_SSH
    [[ "$DO_SSH" != "n" && "$DO_SSH" != "N" ]] && bash "${SCRIPT_DIR}/ssh/setup-ssh-gateway.sh"
fi

# ── Summary ───────────────────────────────────────────────────
echo ""
printf "\033[1m\033[0;32m"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Vault Module Installed!"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "\033[0m"
printf "  \033[2mVaultwarden:\033[0m   \033[1mhttp://localhost:80 (internal)\033[0m\n"
printf "  \033[2mCloudflare:\033[0m    \033[1mConfigure tunnel → http://vaultwarden:80\033[0m\n"
printf "  \033[2mSSH Master:\033[0m    \033[1m/home/pleb/.ssh/ghostnode_master\033[0m\n"
printf "\n"
printf "  \033[2mNext:\033[0m\n"
printf "    1. \033[1mEdit Cloudflare Tunnel\033[0m to route your domain to vaultwarden:80\n"
printf "    2. \033[1mCreate your admin account\033[0m at the Vaultwarden URL\n"
printf "    3. \033[1mSet VW_SIGNUPS=false\033[0m in .env and restart\n"
printf "    4. \033[1mRun backup-keys.sh\033[0m to store SSH keys in Vaultwarden\n"
printf "\n"
