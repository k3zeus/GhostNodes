#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$SCRIPT_DIR/network_discovery.sh"; REPORT=${1:?Uso: $0 <pasta_do_relatorio>}; IFACE_LAN=$(select_lan_interface); RANGE=$(select_scan_range "$IFACE_LAN" "${SCAN_RANGE:-}"); record_interface_selection "$REPORT" "$IFACE_LAN" "$RANGE"; [[ -s "$REPORT/deep.xml" ]] || { fail 'deep.xml ausente'; exit 1; }; mkdir -p "$REPORT/services"; python3 - "$REPORT/deep.xml" <<'PY' > "$REPORT/services_targets.txt"
import sys, xml.etree.ElementTree as ET
for h in ET.parse(sys.argv[1]).getroot().iter('host'):
 a=h.find("address[@addrtype='ipv4']"); ports=[p.get('portid') for p in h.iter('port') if p.find('state') is not None and p.find('state').get('state')=='open']
 if a is not None and ports: print(a.get('addr'), ','.join(ports))
PY
while read -r ip ports; do IFS=, read -ra P <<< "$ports"; for p in "${P[@]}"; do case "$p" in 443|8443|4443) sslscan "$ip:$p" > "$REPORT/services/tls_${ip}_${p}.txt";; 22) ssh-audit "$ip" > "$REPORT/services/ssh_${ip}.txt";; 80|8000|8080) whatweb -a 1 "http://$ip:$p" > "$REPORT/services/web_${ip}_${p}.txt";; esac; done; done < "$REPORT/services_targets.txt"; test -s "$REPORT/services_targets.txt"