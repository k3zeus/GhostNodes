#!/usr/bin/env bash
# Fase 4/6 - Scan profundo (OS + versões + scripts)
set -uo pipefail
REPORT="${1:?Uso: $0 <pasta_do_relatorio>}"
VULN=${VULN:-0}   # 1 = scripts --script vuln do nmap (SÓ com autorização por escrito)

SCRIPTS="default,safe"
[[ "$VULN" == "1" ]] && SCRIPTS="default,vuln"

TARGETS="$REPORT/live_hosts.txt"

if [[ -s "$TARGETS" ]]; then
  echo "[*] Fase 4/6 - Scan profundo nos $(wc -l < "$TARGETS") hosts já descobertos (mais leve num quad-core de 1,5GB)"
  sudo nmap -sS -sV -O --osscan-guess --version-intensity 5 \
       --script "$SCRIPTS" --max-retries 2 --host-timeout 120s \
       -oA "$REPORT/deep" -iL "$TARGETS" | tee "$REPORT/deep.console"
else
  SCAN_RANGE="$(cut -d= -f2 "$REPORT/.scan_range" 2>/dev/null)"
  echo "[!] live_hosts.txt vazio ou ausente — caindo de volta para escanear $SCAN_RANGE inteiro"
  sudo nmap -sS -sV -O --osscan-guess --version-intensity 5 \
       --script "$SCRIPTS" --max-retries 2 --host-timeout 120s \
       -oA "$REPORT/deep" "$SCAN_RANGE" | tee "$REPORT/deep.console"
fi

echo "[+] Fase 4 concluída."
