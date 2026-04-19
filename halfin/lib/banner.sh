#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  lib/banner.sh — Banner, Header e Status Bar                 ║
# ║  Ghost Node Nation / Halfin                                  ║
# ╚══════════════════════════════════════════════════════════════╝
# v.02 - 22032026
#
# Uso:
#   source ${HALFIN_DIR}/lib/banner.sh
#
# Depende de: lib/colors.sh, lib/ui.sh
#
[ -n "${_GN_BANNER_LOADED:-}" ] && return 0
_GN_BANNER_LOADED=1

_GN_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_GN_LIB_DIR}/colors.sh"
source "${_GN_LIB_DIR}/ui.sh"

# ══════════════════════════════════════════════════════════════════════════════
# STATUS BAR — temperatura + data/hora (topo de cada tela)
# ══════════════════════════════════════════════════════════════════════════════
status_bar() {
    local TEMP="N/A"
    local DATETIME
    DATETIME=$(date '+%d/%m/%Y  %H:%M:%S')

    # Tenta lm-sensors
    if command -v sensors &>/dev/null; then
        TEMP=$(sensors 2>/dev/null \
            | awk '/^(CPU|temp1|cpu_thermal|Package|Tdie|Tctl)/{
                match($0, /[0-9]+(\.[0-9]+)?/)
                if(RSTART>0) { print substr($0, RSTART, RLENGTH)"°C"; exit }
            }')
    fi

    # Fallback sysfs (OrangePi, RPi, etc)
    if [ -z "$TEMP" ] || [ "$TEMP" = "N/A" ]; then
        local TFILE
        for TFILE in \
            /sys/class/thermal/thermal_zone0/temp \
            /sys/devices/virtual/thermal/thermal_zone0/temp; do
            if [ -f "$TFILE" ]; then
                local RAW
                RAW=$(cat "$TFILE" 2>/dev/null)
                [ "$RAW" -gt 1000 ] 2>/dev/null \
                    && TEMP="$(( RAW / 1000 ))°C" \
                    || TEMP="${RAW}°C"
                break
            fi
        done
    fi

    # Cor da temperatura
    local TC="$GREEN"
    local TNUM
    TNUM=$(echo "$TEMP" | tr -d '°C' | cut -d. -f1)
    [ "$TNUM" -ge 80 ] 2>/dev/null && TC="$RED"
    [ "$TNUM" -ge 70 ] 2>/dev/null && TC="$YELLOW"

    printf "${DIM}  ┌────────────────────────────────────────────────────────────┐${RESET}\n"
    printf "  ${DIM}│${RESET}  ${YELLOW}🌡  %-10s${RESET}  ${DIM}│${RESET}  ${CYAN}📅  %-36s${RESET}  ${DIM}│${RESET}\n" \
           "$(printf "${TC}${BOLD}%s${RESET}" "$TEMP")" "$DATETIME"
    printf "${DIM}  └────────────────────────────────────────────────────────────┘${RESET}\n"
}

# ══════════════════════════════════════════════════════════════════════════════
# BANNER PRINCIPAL — Ghost Nodes / Halfin
# Arte ASCII com efeito de sombra — padrão canônico do projeto
# ══════════════════════════════════════════════════════════════════════════════
banner() {
    clear
    printf "${BOLD}${CYAN}"
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║                                                              ║"
    echo "  ║   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   ║"
    echo "  ║   ░  ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗         ░  ║"
    echo "  ║   ░ ██╔════╝ ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝         ░  ║"
    echo "  ║   ░ ██║  ███╗███████║██║   ██║███████╗   ██║             ░  ║"
    echo "  ║   ░ ██║   ██║██╔══██║██║   ██║╚════██║   ██║             ░  ║"
    echo "  ║   ░ ╚██████╔╝██║  ██║╚██████╔╝███████║   ██║             ░  ║"
    echo "  ║   ░  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝  ╚═╝             ░  ║"
    echo "  ║   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   ║"
    echo "  ║      ███╗   ██╗ ██████╗ ██████╗ ███████╗███████╗           ║"
    echo "  ║      ████╗  ██║██╔═══██╗██╔══██╗██╔════╝██╔════╝           ║"
    echo "  ║      ██╔██╗ ██║██║   ██║██║  ██║█████╗  ███████╗           ║"
    echo "  ║      ██║╚██╗██║██║   ██║██║  ██║██╔══╝  ╚════██║           ║"
    echo "  ║      ██║ ╚████║╚██████╔╝██████╔╝███████╗███████║           ║"
    echo "  ║      ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝╚══════╝           ║"
    echo "  ║                                                              ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    printf "${RESET}\n"
    status_bar
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# HEADER COMPACTO — para scripts de ferramentas (sem arte ASCII completa)
# Uso: header_compact "Título do Script"
# ══════════════════════════════════════════════════════════════════════════════
header_compact() {
    local TITLE="${1:-Ghost Node Nation}"
    local SUBTITLE="${2:-Halfin}"
    clear
    printf "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    printf "  ║  %-60s║\n" " GHOST NODES  —  HALFIN"
    printf "  ║  ${RESET}${DIM}%-60b${RESET}${BOLD}${CYAN}║\n" " $TITLE"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    printf "${RESET}\n"
    status_bar
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# HEADER INSTALL — para o script de instalação
# ══════════════════════════════════════════════════════════════════════════════
header_install() {
    local VERSION="${1:-v0.3}"
    clear
    printf "${BOLD}${CYAN}"
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║                                                              ║"
    echo "  ║   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   ║"
    echo "  ║   ░  ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗         ░  ║"
    echo "  ║   ░ ██╔════╝ ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝         ░  ║"
    echo "  ║   ░ ██║  ███╗███████║██║   ██║███████╗   ██║             ░  ║"
    echo "  ║   ░ ██║   ██║██╔══██║██║   ██║╚════██║   ██║             ░  ║"
    echo "  ║   ░ ╚██████╔╝██║  ██║╚██████╔╝███████║   ██║             ░  ║"
    echo "  ║   ░  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝  ╚═╝             ░  ║"
    echo "  ║   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   ║"
    echo "  ║      ███╗   ██╗ ██████╗ ██████╗ ███████╗███████╗           ║"
    echo "  ║      ████╗  ██║██╔═══██╗██╔══██╗██╔════╝██╔════╝           ║"
    echo "  ║      ██╔██╗ ██║██║   ██║██║  ██║█████╗  ███████╗           ║"
    echo "  ║      ██║╚██╗██║██║   ██║██║  ██║██╔══╝  ╚════██║           ║"
    echo "  ║      ██║ ╚████║╚██████╔╝██████╔╝███████╗███████║           ║"
    echo "  ║      ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝╚══════╝           ║"
    echo "  ║                                                              ║"
    printf "  ║  ${RESET}${WHITE}${BOLD}  Install ${VERSION} — OrangePi Zero 3 / Debian Bookworm${RESET}${BOLD}${CYAN}          ║\n"
    echo "  ║                                                              ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    printf "${RESET}\n"
}

# ══════════════════════════════════════════════════════════════════════════════
# FOOTER — rodapé padronizado para scripts de ferramenta
# ══════════════════════════════════════════════════════════════════════════════
footer() {
    local MSG="${1:-Operação concluída}"
    echo ""
    printf "${DIM}  ──────────────────────────────────────────────────────────────${RESET}\n"
    printf "  ${DIM}%s — %s${RESET}\n" "$MSG" "$(date '+%d/%m/%Y %H:%M:%S')"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# MOTD INLINE — bloco de boas-vindas para profile.d
# Exportável para uso em /etc/profile.d/ghostnode-motd.sh
# ══════════════════════════════════════════════════════════════════════════════
print_motd() {
    local TEMP="N/A"
    for TFILE in /sys/class/thermal/thermal_zone0/temp \
                 /sys/devices/virtual/thermal/thermal_zone0/temp; do
        [ -f "$TFILE" ] && {
            R=$(cat "$TFILE" 2>/dev/null)
            [ "$R" -gt 1000 ] 2>/dev/null \
                && TEMP="$(( R / 1000 ))°C" \
                || TEMP="${R}°C"
            break
        }
    done

    printf "\n${BOLD}${CYAN}"
    printf "  ╔══════════════════════════════════════════════════════════════╗\n"
    printf "  ║                                                              ║\n"
    printf "  ║         G H O S T   N O D E S  —  H A L F I N              ║\n"
    printf "  ║                                                              ║\n"
    printf "  ╠══════════════════════════════════════════════════════════════╣\n"
    printf "${RESET}"
    printf "  ${DIM}║${RESET}  ${YELLOW}🌡  %-10s${RESET}  ${DIM}│${RESET}  ${CYAN}📅  %-34s${RESET}  ${DIM}║${RESET}\n" \
           "$TEMP" "$(date '+%d/%m/%Y  %H:%M:%S')"
    printf "  ${DIM}║${RESET}  ${WHITE}💻  %-10s${RESET}  ${DIM}│${RESET}  ${GREEN}⏱   %-34s${RESET}  ${DIM}║${RESET}\n" \
           "$(hostname)" "$(uptime -p 2>/dev/null | sed 's/up //' | cut -c1-34)"
    printf "  ${DIM}║${RESET}  ${WHITE}👤  %-10s${RESET}  ${DIM}│${RESET}  ${CYAN}💾  %-34s${RESET}  ${DIM}║${RESET}\n" \
           "$(whoami)" "$(df -h / 2>/dev/null | awk 'NR==2{print $3"/"$2" ("$5")"}')"
    printf "${BOLD}${CYAN}"
    printf "  ╠══════════════════════════════════════════════════════════════╣\n"
    printf "  ║  ${RESET}${BOLD}${WHITE}Execute ${CYAN}ghostnode${WHITE} para abrir o painel de controle.${RESET}${BOLD}${CYAN}         ║\n"
    printf "  ║  ${RESET}${DIM}Use ${WHITE}ghostnode --help${RESET}${DIM} para ver os comandos disponíveis.${RESET}${BOLD}${CYAN}    ║\n"
    printf "  ║                                                              ║\n"
    printf "  ╚══════════════════════════════════════════════════════════════╝\n"
    printf "${RESET}\n"
}
