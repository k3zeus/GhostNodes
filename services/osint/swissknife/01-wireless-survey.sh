#!/usr/bin/env bash
# Fase 1/6 - Survey wireless passivo
#
# Requer um adaptador Wi-Fi USB externo com suporte a modo monitor
# (ex.: MT7612U/MT7601U). O Wi-Fi onboard do Orange Pi Zero 3
# (Unisoc UWE5622 / AW859A) NAO suporta modo monitor/injeção de forma
# confiável — não tente apontar esta fase para ele.
set -uo pipefail
REPORT="${1:?Uso: $0 <pasta_do_relatorio>}"
IFACE_WLAN=${IFACE_WLAN:-}

log()  { echo -e "\n[*] $(date +%H:%M:%S) $*"; }
warn() { echo -e "[!] $*"; }

if [[ -z "$IFACE_WLAN" ]]; then
  # autodetecta um adaptador USB (nomeado wlx<MAC> pela udev)
  IFACE_WLAN="$(iw dev | awk '/Interface wlx/{print $2; exit}')"
fi

if [[ -z "$IFACE_WLAN" ]]; then
  warn "Nenhum adaptador wlx* (USB externo) encontrado."
  warn "Rode 'iw dev' e exporte IFACE_WLAN=<nome> manualmente antes de rodar de novo."
  warn "Lembrete: o Wi-Fi onboard (geralmente wlan0) não faz modo monitor neste hardware."
  exit 0
fi

log "Fase 1/6 - Survey wireless em $IFACE_WLAN (130s)"

# Não precisamos de 'airmon-ng check kill' aqui: o install.sh já marcou
# interfaces wlx* como não-gerenciadas pelo NetworkManager, então o wlan0
# de gerência não é afetado ao colocarmos o adaptador USB em modo monitor.
sudo airmon-ng start "$IFACE_WLAN" >/dev/null 2>&1

MON="$(iw dev | awk '/Interface/{i=$2} /type monitor/{print i; exit}')"
if [[ -z "$MON" ]]; then
  warn "Adaptador não entrou em modo monitor (driver/firmware pode não suportar). Pulando fase 1."
  exit 0
fi

sudo timeout 130 airodump-ng "$MON" --output-format csv --write "$REPORT/wifi" >/dev/null 2>&1
timeout 45 sudo wash -i "$MON" 2>/dev/null | tee "$REPORT/wps.txt" || true

sudo airmon-ng stop "$MON" >/dev/null 2>&1
log "Fase 1 concluída."
