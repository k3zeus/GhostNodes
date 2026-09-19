#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$SCRIPT_DIR/network_discovery.sh"; RUN="${SWISS_LOG_ROOT}/reports/$(date +%Y%m%d-%H%M%S)"; mkdir -p "$RUN"
IFACE_LAN=$(select_lan_interface); SCAN_RANGE=$(select_scan_range "$IFACE_LAN" "${SCAN_RANGE:-}"); export IFACE_LAN SCAN_RANGE IFACE_WLAN=${IFACE_WLAN:-} SWISS_LOG_ROOT; record_interface_selection "$RUN" "$IFACE_LAN" "$SCAN_RANGE"
for phase in 01-wireless-survey.sh 02-passive-listen.sh 03-discovery.sh 04-deep-scan.sh 05-service-checks.sh; do bash "$SCRIPT_DIR/$phase" "$RUN"; done
python3 "$SCRIPT_DIR/06-generate-report.py" "$RUN"; printf 'Concluído: %s/report.md e report.html\n' "$RUN"