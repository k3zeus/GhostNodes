#!/usr/bin/env bash
# Fase 3/6 - Descoberta de hosts
set -uo pipefail
REPORT="${1:?Uso: $0 <pasta_do_relatorio>}"
IFACE_LAN=${IFACE_LAN:-eth0}

# Filtra pela interface certa em vez de pegar a primeira rota "proto kernel"
# (evita escanear a rede errada quando há mais de uma interface ativa —
# por exemplo o wlan0 de gerência ao lado do eth0 da LAN auditada).
SCAN_RANGE=${SCAN_RANGE:-$(ip -4 route | awk -v ifc="$IFACE_LAN" '$0 ~ ("dev "ifc" ") && /proto kernel/{print $1; exit}')}

if [[ -z "$SCAN_RANGE" ]]; then
  echo "[!] Não consegui inferir o range de $IFACE_LAN. Exporte SCAN_RANGE=192.168.x.0/24 manualmente."
  exit 1
fi

echo "[*] Fase 3/6 - Descoberta de hosts em $SCAN_RANGE (via $IFACE_LAN)"
sudo arp-scan --localnet -I "$IFACE_LAN" | tee "$REPORT/arp_scan.txt" || true
sudo nmap -sn -PE -PS21,22,25,53,80,135,443,445,3389 -oX "$REPORT/discovery.xml" "$SCAN_RANGE" >/dev/null 2>&1

# Lista simples de IPs vivos, para a Fase 4 não precisar reescanear a faixa toda
python3 - "$REPORT/discovery.xml" > "$REPORT/live_hosts.txt" <<'PY'
import sys, xml.etree.ElementTree as ET
t = ET.parse(sys.argv[1])
for h in t.getroot().iter('host'):
    a = h.find("address[@addrtype='ipv4']")
    if a is not None:
        print(a.get('addr'))
PY

echo "SCAN_RANGE=$SCAN_RANGE" > "$REPORT/.scan_range"
echo "[+] Fase 3 concluída: $(wc -l < "$REPORT/live_hosts.txt") hosts vivos."
