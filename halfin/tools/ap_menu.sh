#!/bin/bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../lib/init.sh"
while true; do
    section 'AP Halfin: acesso local e recuperacao'
    printf '[1] Diagnostico (radio, bridge, DHCP, DNS)\n[2] Reparar falhas locais\n[3] Logs do AP e recuperacao\n[4] Ativar protecao no boot (preserva senha)\n[0] Voltar\n[q] Sair\nOpcao: '
    read -r choice || exit 0
    case "$choice" in
        0|'') exit 0 ;;
        q|Q) [ "${GN_TUI_CHILD:-0}" = 1 ] && exit 200; exit 0 ;;
        1) sudo python3 "$HERE/ap_health.py" check ;;
        2) if confirm 'Reparar apenas AP/bridge/DHCP? Clientes Wi-Fi podem desconectar.' n; then
               sudo python3 "$HERE/ap_health.py" repair
           fi ;;
        3) sudo journalctl -b -u hostapd -u halfin-ap-prepare -u halfin-ap-health -n 80 --no-pager ;;
        4) if confirm 'Aplicar perfil WPA2 compativel e monitoramento? AP tera breve interrupcao.' n; then
               sudo python3 "$HERE/ap_health.py" install
           fi ;;
        *) step_warn 'Opcao invalida'; continue ;;
    esac
    printf '\nENTER para voltar; q para sair: '
    read -r choice || exit 0
    if [[ "$choice" = q || "$choice" = Q ]]; then
        [ "${GN_TUI_CHILD:-0}" = 1 ] && exit 200
        exit 0
    fi
done
