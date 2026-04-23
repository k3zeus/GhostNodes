#!/bin/bash
# ============================================================================
# GHOSTNODES - SOVEREIGN DASHBOARD SETUP
# ============================================================================

set -euo pipefail

_GN_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_GN_FIND="$_GN_SELF"
while [ ! -d "${_GN_FIND}/halfin/lib" ] && [ "$_GN_FIND" != "/" ]; do
    _GN_FIND="$(dirname "$_GN_FIND")"
done

if [ -f "${_GN_FIND}/halfin/lib/init.sh" ]; then
    source "${_GN_FIND}/halfin/lib/init.sh"
else
    BOLD="\e[1m"; RESET="\e[0m"; DIM="\e[2m"
    GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; CYAN="\e[36m"
    CHECK="${GREEN}OK${RESET}"; CROSS="${RED}ERR${RESET}"; ARROW="${CYAN}>${RESET}"
    step_ok() { printf "  ${CHECK} %s\n" "$1"; }
    step_warn() { printf "  ${YELLOW}WARN${RESET} %s\n" "$1"; }
    step_err() { printf "  ${CROSS} %s\n" "$1"; }
    step_info() { printf "  ${ARROW} %s\n" "$1"; }
fi

GN_ROOT="${GN_ROOT:-${_GN_FIND}}"
WEB_DIR="${GN_ROOT}/web"
WEB_SERVICE="ghostnodes-web.service"
BACKEND_DIR="${WEB_DIR}/backend"
FRONTEND_DIR="${WEB_DIR}/frontend"
RPC_ENV_FILE="${GN_ROOT}/var/bitcoin-rpc.env"

step_info "Iniciando configuracao do Sovereignty Dashboard..."

if [ ! -d "$BACKEND_DIR" ]; then
    step_err "Backend nao encontrado em ${BACKEND_DIR}"
    exit 1
fi

if [ -f "${BACKEND_DIR}/requirements.txt" ]; then
    step_info "Instalando dependencias Python..."
    python3 -m pip install --upgrade pip >/dev/null 2>&1
    python3 -m pip install -r "${BACKEND_DIR}/requirements.txt" >/dev/null 2>&1
    step_ok "Dependencias Python instaladas"
else
    step_warn "requirements.txt nao encontrado em ${BACKEND_DIR}"
fi

if [ -f "${FRONTEND_DIR}/package.json" ]; then
    if command -v npm >/dev/null 2>&1; then
        step_info "Construindo frontend React..."
        (
            cd "$FRONTEND_DIR"
            npm install >/dev/null 2>&1
            npm run build >/dev/null 2>&1
        )
        step_ok "Frontend compilado em ${FRONTEND_DIR}/dist"
    else
        step_warn "npm nao encontrado - frontend nao foi compilado"
    fi
else
    step_warn "package.json nao encontrado em ${FRONTEND_DIR}"
fi

step_info "Registrando servico systemd: ${WEB_SERVICE}"
cat > "/etc/systemd/system/${WEB_SERVICE}" << SVCEOF
[Unit]
Description=GhostNodes Sovereign Dashboard
After=network.target

[Service]
Type=simple
User=${GN_USER:-root}
WorkingDirectory=${BACKEND_DIR}
ExecStart=/usr/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 80
Restart=on-failure
RestartSec=5
Environment=GN_ROOT=${GN_ROOT}
EnvironmentFile=-${RPC_ENV_FILE}
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable "$WEB_SERVICE" >/dev/null 2>&1
systemctl start "$WEB_SERVICE" >/dev/null 2>&1

if systemctl is-active "$WEB_SERVICE" >/dev/null 2>&1; then
    step_ok "Dashboard ativo e rodando na porta 80"
else
    step_err "Falha ao iniciar o servico. Verifique logs: journalctl -u $WEB_SERVICE"
fi

exit 0
