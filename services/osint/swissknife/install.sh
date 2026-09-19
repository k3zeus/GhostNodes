#!/usr/bin/env bash
set -euo pipefail
BASE=${SWISS_LOG_ROOT:-"$HOME/logs/osint/swissknife"}; RUN="$BASE/install/$(date +%Y%m%d-%H%M%S)"; mkdir -p "$RUN" "$BASE/reports" "$BASE/captures"; LOG="$RUN/install.log"; : > "$LOG"
packages=(nmap arp-scan netdiscover nbtscan avahi-utils smbclient snmp aircrack-ng reaver iw wireless-tools tcpdump tshark p0f sslscan ssh-audit whatweb jq xmlstarlet tmux git curl python3-pip python3-venv ieee-data lynis)
printf 'mode=%s\n' "${SWISSKNIFE_APPLY:-0}" | tee -a "$LOG"; printf '%s\n' "${packages[@]}" > "$RUN/packages.txt"
if [[ ${SWISSKNIFE_APPLY:-0} != 1 ]]; then printf 'Pré-verificação concluída. Para instalar dependências, execute com SWISSKNIFE_APPLY=1.\n' | tee -a "$LOG"; exit 0; fi
sudo apt update | tee -a "$LOG"; sudo apt install -y --no-install-recommends "${packages[@]}" | tee -a "$LOG"; printf 'Dependências instaladas sem alterar rotas, interfaces ou configuração de rede.\n' | tee -a "$LOG"