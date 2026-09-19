#!/usr/bin/env bash
# Publica reports/ via Caddy — SÓ na interface de GERÊNCIA, nunca na LAN auditada.
set -euo pipefail
BASE="$HOME/swissknife"

echo "Interfaces de rede disponíveis:"
ip -4 -o addr show | awk '{print $2, $4}'
echo ""
read -rp "Em qual IP de GERÊNCIA (NÃO a LAN auditada!) o painel deve escutar? " MGMT_IP

if [[ -z "$MGMT_IP" ]]; then
  echo "[!] IP vazio, abortando."
  exit 1
fi

echo "[*] Gere a senha (será pedida interativamente):"
HASH="$(caddy hash-password)"

sudo tee /etc/caddy/Caddyfile >/dev/null <<EOF
# Escuta SÓ no IP de gerência informado — nunca exposto na rede auditada.
http://${MGMT_IP}:8080 {
    basic_auth {
        auditor ${HASH}
    }
    root * ${BASE}/reports
    file_server browse
}
EOF

sudo systemctl restart caddy

echo ""
echo "[+] Relatórios disponíveis em: http://${MGMT_IP}:8080"
echo "[!] Isso é HTTP puro (sem TLS) — a senha do basic_auth trafega em texto claro"
echo "    nessa interface de gerência. Se você tiver Tailscale configurado, prefira"
echo "    publicar via 'tailscale cert' + TLS no Caddyfile em vez deste HTTP simples."
