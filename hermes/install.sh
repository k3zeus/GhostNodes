#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║   GhostNodes — Hermes Module Installer                       ║
# ║   Open WebUI (API-only) + Telegram Bridge                   ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Usage: sudo bash hermes/install.sh [--yolo]
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
echo "  ║          GhostNode — Hermes Module Installer                 ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
printf "\033[0m\n"

# ── Root check ────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    step_err "Execute como root: sudo bash hermes/install.sh"
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

# ── Copy .env ─────────────────────────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    step_warn ".env created from example — EDIT IT BEFORE CONTINUING"
    if [ "$YOLO" = false ]; then
        printf "\n  Required keys:\n"
        printf "    - \033[1mHERMES_SECRET_KEY\033[0m (openssl rand -base64 48)\n"
        printf "    - \033[1mOPENROUTER_API_KEY\033[0m (from openrouter.ai)\n"
        printf "    - \033[1mTELEGRAM_BOT_TOKEN\033[0m (from @BotFather)\n"
        printf "\n  Edit: \033[1m%s\033[0m\n\n" "$ENV_FILE"
        read -p "  Press Enter after editing .env, or Ctrl+C to abort..."
    fi
fi

# ── Build Telegram bridge image ──────────────────────────────
step_info "Building Telegram bridge image..."
cd "${DOCKER_DIR}/telegram"
docker build -t hermes-telegram:latest . --quiet
step_ok "Telegram bridge image built"

# ── Bring up containers ──────────────────────────────────────
step_info "Starting Hermes (Open WebUI + Telegram Bridge)..."
cd "$DOCKER_DIR"
docker compose up -d

# ── Wait for healthcheck ──────────────────────────────────────
step_info "Waiting for Open WebUI to be healthy..."
for i in $(seq 1 60); do
    if docker inspect --format='{{.State.Health.Status}}' hermes-webui 2>/dev/null | grep -q "healthy"; then
        step_ok "Open WebUI is healthy!"
        break
    fi
    [ "$i" -eq 60 ] && step_warn "Timeout waiting for healthcheck — check logs"
    sleep 2
done

# ── Summary ───────────────────────────────────────────────────
echo ""
printf "\033[1m\033[0;32m"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Hermes Module Installed!"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "\033[0m"
printf "  \033[2mOpen WebUI:\033[0m     \033[1mhttp://localhost:8080 (internal)\033[0m\n"
printf "  \033[2mTelegram Bot:\033[0m   \033[1mSearch your bot on Telegram and /start\033[0m\n"
printf "\n"
printf "  \033[2mPost-install:\033[0m\n"
printf "    1. Access Open WebUI and \033[1mcreate your admin account\033[0m\n"
printf "    2. Go to Settings → Connections → add \033[1mOpenAI/OpenRouter\033[0m keys\n"
printf "    3. Go to Settings → Account → generate \033[1mAPI Key\033[0m for Telegram\n"
printf "    4. Update \033[1mHERMES_API_KEY\033[0m in .env and restart telegram-bridge\n"
printf "\n"
