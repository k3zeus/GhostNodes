#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$SCRIPT_DIR/network_discovery.sh"; IFACE_MGMT=${MGMT_INTERFACE:-$(select_lan_interface)}; interface_is_real_up "$IFACE_MGMT" || { fail "Interface de gerência inválida: $IFACE_MGMT"; exit 1; }; is_halfin_ap "$IFACE_MGMT" && { fail "AP Halfin não pode publicar relatórios: $IFACE_MGMT"; exit 1; }; IP=$(interface_ipv4_cidr "$IFACE_MGMT"); [[ -n "$IP" ]] || { fail "Interface de gerência sem IPv4: $IFACE_MGMT"; exit 1; }
OUT="${SWISS_LOG_ROOT}/serve"; mkdir -p "$OUT"; cat > "$OUT/serve-command.sh" <<EOF
#!/usr/bin/env bash
cd "${SWISS_LOG_ROOT}/reports"
exec python3 -m http.server 8080 --bind "${IP%/*}"
EOF
chmod 0700 "$OUT/serve-command.sh"; printf 'interface=%s\naddress=%s\ncommand=%s\n' "$IFACE_MGMT" "${IP%/*}:8080" "$OUT/serve-command.sh" > "$OUT/serve-instructions.txt"; printf 'Instruções salvas em %s/serve-instructions.txt\n' "$OUT"