#!/usr/bin/env bash
# Fase 5/6 - Checagens por serviço (TLS/SSH/WEB)
set -uo pipefail
REPORT="${1:?Uso: $0 <pasta_do_relatorio>}"
mkdir -p "$REPORT/services"

echo "[*] Fase 5/6 - Checagens por serviço"

python3 - "$REPORT/deep.xml" <<'PY' > "$REPORT/services_targets.txt"
import sys, xml.etree.ElementTree as ET
t = ET.parse(sys.argv[1])
for h in t.getroot().iter('host'):
    a = h.find("address[@addrtype='ipv4']")
    if a is None: continue
    ports = []
    for p in h.iter('port'):
        st = p.find('state')
        if st is None or st.get('state') != 'open': continue
        ports.append(p.get('portid'))
    if ports: print(a.get('addr'), ','.join(ports))
PY

while read -r ip ports; do
  IFS=, read -ra P <<< "$ports"
  for p in "${P[@]}"; do
    case "$p" in
      443|8443|4443) sslscan "$ip:$p"            > "$REPORT/services/tls_${ip}_${p}.txt" 2>/dev/null ;;
      22)            ssh-audit "$ip"              > "$REPORT/services/ssh_${ip}.txt"      2>/dev/null ;;
      80|8000|8080)  whatweb -a 1 "http://$ip:$p" > "$REPORT/services/web_${ip}_${p}.txt" 2>/dev/null ;;
    esac
  done
done < "$REPORT/services_targets.txt"

echo "[+] Fase 5 concluída."
