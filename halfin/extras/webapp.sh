#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# GHOSTNODES — SOVEREIGN DASHBOARD SETUP
# ══════════════════════════════════════════════════════════════════════════════
# Script para instalação automática das dependências e criação do serviço systemd.
# Chamado pelo fluxo pre_install.sh do Halfin.

# Cores e Helpers (herdado do ambiente pre_install)
[ -f "/tmp/gn_lib.sh" ] && source "/tmp/gn_lib.sh"

WEB_DIR="${GN_ROOT}/web"
WEB_SERVICE="ghostnodes-web.service"
BACKEND_DIR="${WEB_DIR}/backend"

step_info "Iniciando configuração do Sovereignty Dashboard..."

# 1. Instalar Uvicorn e dependências
if [ -f "${BACKEND_DIR}/requirements.txt" ]; then
    step_info "Instalando dependências via pip3..."
    pip3 install --upgrade pip >/dev/null 2>&1
    pip3 install -r "${BACKEND_DIR}/requirements.txt" >/dev/null 2>&1
    step_ok "Dependências instaladas."
else
    step_warn "Arquivo requirements.txt não encontrado em ${BACKEND_DIR}."
fi

# 2. Criar serviço Systemd
step_info "Registrando serviço systemd: ${WEB_SERVICE}"
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

[Install]
WantedBy=multi-user.target
SVCEOF

# 3. Habilitar e Iniciar
systemctl daemon-reload
systemctl enable "$WEB_SERVICE" >/dev/null 2>&1
systemctl start "$WEB_SERVICE" >/dev/null 2>&1

if systemctl is-active "$WEB_SERVICE" >/dev/null 2>&1; then
    step_ok "Dashboard ativo e rodando na porta 80."
else
    step_err "Falha ao iniciar o serviço. Verifique logs: journalctl -u $WEB_SERVICE"
fi

exit 0
