#!/usr/bin/env bash
# Orquestrador - roda as 6 fases em sequência.
# Rode dentro de uma sessão tmux: tmux new -s audit && ./audit-all.sh
set -uo pipefail

BASE="$HOME/swissknife"
REPORT="$BASE/reports/$(date +%Y%m%d-%H%M)"
mkdir -p "$REPORT"

export IFACE_LAN=${IFACE_LAN:-eth0}
export IFACE_WLAN=${IFACE_WLAN:-}
export SCAN_RANGE=${SCAN_RANGE:-}
export VULN=${VULN:-0}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[*] Relatório desta rodada: $REPORT"
echo "[*] IFACE_LAN=$IFACE_LAN | IFACE_WLAN=${IFACE_WLAN:-<autodetectar>} | VULN=$VULN"

"$SCRIPT_DIR/services/01-wireless-survey.sh" "$REPORT"
"$SCRIPT_DIR/services/02-passive-listen.sh"  "$REPORT"
"$SCRIPT_DIR/services/03-discovery.sh"       "$REPORT"
"$SCRIPT_DIR/services/04-deep-scan.sh"       "$REPORT"
"$SCRIPT_DIR/services/05-service-checks.sh"  "$REPORT"
python3 "$SCRIPT_DIR/services/06-generate-report.py" "$REPORT"

echo ""
echo "[+] Concluído: $REPORT/report.md | report.html"
echo "[+] Para publicar: ./serve-reports.sh"
