#!/usr/bin/env bash
# Fase 2/6 - Escuta passiva: p0f + mDNS/SSDP/DNS-SD + NetBIOS
set -uo pipefail
REPORT="${1:?Uso: $0 <pasta_do_relatorio>}"
IFACE_LAN=${IFACE_LAN:-eth0}

log() { echo -e "\n[*] $(date +%H:%M:%S) $*"; }

log "Fase 2/6 - Escuta passiva (60s) em $IFACE_LAN"

( sudo timeout 60 p0f -i "$IFACE_LAN" -o "$REPORT/p0f.log" >/dev/null 2>&1 ) &

# Nomes de script NSE conferidos contra a documentação oficial do nmap:
#   - broadcast-ssdp-discover        (existe)
#   - broadcast-dns-service-discovery (nome correto; "dns-service-discover" NÃO existe)
sudo nmap -sn -e "$IFACE_LAN" \
     --script broadcast-ssdp-discover,broadcast-dns-service-discovery \
     -oN "$REPORT/broadcast.nmap" >/dev/null 2>&1

# Não existe script NSE "broadcast-netbios-discover" — usamos a ferramenta
# dedicada (nbtscan), que já varre a rede local via broadcast NetBIOS.
LAN_CIDR="$(ip -4 -o addr show "$IFACE_LAN" 2>/dev/null | awk '{print $4}')"
if [[ -n "$LAN_CIDR" ]]; then
  sudo nbtscan -r "$LAN_CIDR" > "$REPORT/netbios.txt" 2>/dev/null || true
fi

avahi-browse -at --terminate 2>/dev/null > "$REPORT/mdns.txt" || true

wait
log "Fase 2 concluída."
