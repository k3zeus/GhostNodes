#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/init.sh"
require_root
WEB_DIR="${GN_ROOT}/web"
BACKEND_DIR="${WEB_DIR}/backend"
FRONTEND_DIR="${WEB_DIR}/frontend"
WEB_PORT="${GN_WEB_PORT:-8088}"
[[ "$WEB_PORT" =~ ^[0-9]+$ ]] && [ "$WEB_PORT" -ge 1024 ] && [ "$WEB_PORT" -le 65535 ] || {
    step_err 'GN_WEB_PORT deve estar entre 1024 e 65535.'; exit 1;
}
test -f "${BACKEND_DIR}/requirements.txt"
test -f "${FRONTEND_DIR}/package.json"
id "$GN_USER" >/dev/null
DEBIAN_FRONTEND=noninteractive apt-get install -y python3-venv python3-dev build-essential npm
python3 -m venv "${WEB_DIR}/.venv"
"${WEB_DIR}/.venv/bin/python" -m pip install -r "${BACKEND_DIR}/requirements.txt"
(cd "$FRONTEND_DIR" && npm install --no-audit --no-fund && npm run build)
test -s "${FRONTEND_DIR}/dist/index.html"
cat > /etc/systemd/system/ghostnodes-web.service <<EOF
[Unit]
Description=GhostNodes Dashboard
After=network.target

[Service]
Type=simple
User=${GN_USER}
WorkingDirectory=${BACKEND_DIR}
ExecStart=${WEB_DIR}/.venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port ${WEB_PORT}
Restart=on-failure
RestartSec=5
Environment=GN_ROOT=${GN_ROOT}
EnvironmentFile=-${GN_ROOT}/var/bitcoin-rpc.env
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable ghostnodes-web.service
systemctl restart ghostnodes-web.service
for attempt in {1..30}; do
    if curl -fsS "http://127.0.0.1:${WEB_PORT}/api/health" >/dev/null &&
        curl -fsS "http://127.0.0.1:${WEB_PORT}/" | grep -q '<html'; then
        step_ok "Dashboard respondendo na porta ${WEB_PORT}"
        exit 0
    fi
    sleep 1
done
step_err 'Dashboard nao ficou pronto; consulte journalctl -u ghostnodes-web.'
exit 1
