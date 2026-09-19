#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$SCRIPT_DIR/network_discovery.sh"; REPORT=${1:?Uso: $0 <pasta_do_relatorio>}; mkdir -p "$REPORT"; IFACE_LAN=$(select_lan_interface); SCAN_RANGE=$(select_scan_range "$IFACE_LAN" "${SCAN_RANGE:-}"); record_interface_selection "$REPORT" "$IFACE_LAN" "$SCAN_RANGE"; sudo arp-scan --localnet -I "$IFACE_LAN" | tee "$REPORT/arp_scan.txt"; sudo nmap -sn -PE -PS21,22,25,53,80,135,443,445,3389 -oX "$REPORT/discovery.xml" "$SCAN_RANGE"; python3 - "$REPORT/discovery.xml" > "$REPORT/live_hosts.txt" <<'PY'
import sys, xml.etree.ElementTree as ET
for host in ET.parse(sys.argv[1]).getroot().iter('host'):
 a=host.find("address[@addrtype='ipv4']")
 if a is not None: print(a.get('addr'))
PY
printf 'SCAN_RANGE=%s\n' "$SCAN_RANGE" > "$REPORT/.scan_range"; test -s "$REPORT/discovery.xml"