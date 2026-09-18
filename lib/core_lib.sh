#!/bin/bash
#
# ╔══════════════════════════════════════════════════════════════╗
# ║       Ghost Nodes - NodeNation — Core Library                ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Biblioteca central com funções de UI, estado e utilitários.
# Importe este arquivo nos outros scripts com:
# source /caminho/para/lib/core_lib.sh

# ─── Módulo de Variáveis ​​Globais ──────────────────────────────────────────────
if [ -f "$(dirname "${BASH_SOURCE[0]}")/../var/globals.env" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../var/globals.env"
fi

# ─── Cores e símbolos ─────────────────────────────────────────────────────────
BOLD="\e[1m"
RESET="\e[0m"
DIM="\e[2m"
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
CYAN="\e[36m"
MAGENTA="\e[35m"
WHITE="\e[97m"
BG_DARK="\e[40m"
CHECK="${GREEN}✔${RESET}"
CROSS="${RED}✘${RESET}"
ARROW="${CYAN}▶${RESET}"
WARN="${YELLOW}⚠${RESET}"

# ─── Arquivo de estado (persiste entre execuções) ─────────────────────────────
STATE_FILE="/var/lib/ghostnodes_state.env"

# ─── Funções de UI ────────────────────────────────────────────────────────────

# ══════════════════════════════════════════════════════════════════════════════
# BARRA DE STATUS GLOBAL — temperatura + data/hora alinhada
# ══════════════════════════════════════════════════════════════════════════════
ui_center_pad() {
    local width="${1:-66}" cols
    cols="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
    case "$cols" in ''|*[!0-9]*) cols=80 ;; esac
    [ "$cols" -gt "$width" ] && printf '%*s' "$(( (cols - width) / 2 ))" ''
}
status_bar() {
    local TEMP="N/A" DATETIME PAD
    DATETIME=$(date '+%d/%m/%Y  %H:%M:%S')
    PAD=$(ui_center_pad 66)
    for TFILE in /sys/class/thermal/thermal_zone0/temp /sys/devices/virtual/thermal/thermal_zone0/temp; do
        if [ -f "$TFILE" ]; then
            local R
            R=$(cat "$TFILE" 2>/dev/null)
            [ "$R" -gt 1000 ] 2>/dev/null && TEMP="$(( R/1000 ))C" || TEMP="${R}C"
            break
        fi
    done
    printf "%s${DIM}┌────────────────────────────────────────────────────────────┐${RESET}\n" "$PAD"
    printf "%s${DIM}│${RESET}  ${YELLOW}🌡  %-10s${RESET}  ${DIM}│${RESET}  ${CYAN}📅  %-36s${RESET}  ${DIM}│${RESET}\n" "$PAD" "$TEMP" "$DATETIME"
    printf "%s${DIM}└────────────────────────────────────────────────────────────┘${RESET}\n" "$PAD"
}

# ══════════════════════════════════════════════════════════════════════════════
# BANNER PRINCIPAL GLOBAL — GHOST NODES (Layout Atualizado)
# ══════════════════════════════════════════════════════════════════════════════
main_banner() {
    local TITLE="${1:-}" PAD
    PAD=$(ui_center_pad 66)
    if [ "${GN_TUI_NO_CLEAR:-0}" = 1 ]; then
        :
    else
        # Escape nativo: elimina res?duos sem invocar clear externo.
        printf '\033[2J\033[H'
    fi
    printf "${BOLD}${CYAN}"
    echo "${PAD}╔══════════════════════════════════════════════════════════════╗"
    echo "${PAD}║                                                              ║"
    echo "${PAD}║   ██████╗ ██╗  ██╗ ██████╗  ██████╗ ████████╗                ║"
    echo "${PAD}║  ██╔════╝ ██║  ██║██╔═══██╗██╔════╝ ╚══██╔══╝                ║"
    echo "${PAD}║  ██║  ███╗███████║██║   ██║╚█████╗     ██║                   ║"
    echo "${PAD}║  ██║   ██║██╔══██║██║   ██║ ╚═══██╗    ██║                   ║"
    echo "${PAD}║  ╚██████╔╝██║  ██║╚██████╔╝██████╔╝    ██║                   ║"
    echo "${PAD}║   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝     ╚═╝                   ║"
    echo "${PAD}║                                                              ║"
    echo "${PAD}║      ███╗   ██╗ ██████╗ ██████╗ ███████╗███████╗             ║"
    echo "${PAD}║      ████╗  ██║██╔═══██╗██╔══██╗██╔════╝██╔════╝             ║"
    echo "${PAD}║      ██╔██╗ ██║██║   ██║██║  ██║█████╗  ███████╗             ║"
    echo "${PAD}║      ██║╚██╗██║██║   ██║██║  ██║██╔══╝  ╚════██║             ║"
    echo "${PAD}║      ██║ ╚████║╚██████╔╝██████╔╝███████╗███████║             ║"
    echo "${PAD}║      ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝╚══════╝             ║"
    echo "${PAD}║                                                              ║"
    if [ -n "$TITLE" ]; then
        local T_LEN=${#TITLE}
        local P_LEFT=$(( (62 - T_LEN) / 2 ))
        local P_RIGHT=$(( 62 - T_LEN - P_LEFT ))
        local PAD_L=$(printf "%*s" "$P_LEFT" "")
        local PAD_R=$(printf "%*s" "$P_RIGHT" "")
        printf "%s║${RESET}${BOLD}${WHITE}%s%s%s${RESET}${BOLD}${CYAN}║\n" "$PAD" "$PAD_L" "$TITLE" "$PAD_R"
    fi
    echo "${PAD}╚══════════════════════════════════════════════════════════════╝"
    printf "${RESET}\n"
    
    status_bar
    echo ""
}

# Wrapper de retrocompatibilidade para scripts mais antigos
header() {
    main_banner "$1"
}

section() {
    echo ""
    printf "${BOLD}${MAGENTA}  ┌─ %s${RESET}\n" "$1"
    sep_thin
}

step_ok()   { printf "  ${CHECK} ${WHITE}%s${RESET}\n" "$1"; }
step_warn() { printf "  ${WARN}  ${YELLOW}%s${RESET}\n" "$1"; }
step_err()  { printf "  ${CROSS} ${RED}%s${RESET}\n" "$1"; }
step_info() { printf "  ${ARROW} ${DIM}%s${RESET}\n" "$1"; }

sep() {
    printf "${DIM}  ──────────────────────────────────────────────────────────────${RESET}\n"
}

sep_thin() {
    printf "${DIM}  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${RESET}\n"
}

press_enter() {
    echo ""
    printf "  ${DIM}[ ENTER para continuar ]${RESET}"
    read -r
}

press_enter_or_back() {
    echo ""
    printf "  ${DIM}[ ENTER para voltar ao menu ]${RESET}"
    read -r
}

confirm() {
    local MSG="$1"
    local DEFAULT="${2:-s}"
    if [ "$DEFAULT" = "s" ]; then
        local OPTS="${GREEN}S${RESET}/${DIM}n${RESET}"
    else
        local OPTS="${DIM}s${RESET}/${GREEN}N${RESET}"
    fi
    printf "\n  ${YELLOW}?${RESET} %s [%b]: " "$MSG" "$OPTS"
    read -r REPLY || return 1
    REPLY="${REPLY:-$DEFAULT}"
    [[ "$REPLY" =~ ^[sS]$ ]]
}

spinner() {
    local PID=$1
    local MSG="$2"
    local FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    while kill -0 "$PID" 2>/dev/null; do
        printf "\r  ${CYAN}%s${RESET}  %s " "${FRAMES[$((i % 10))]}" "$MSG"
        sleep 0.1
        i=$((i + 1))
    done
    printf "\r  ${CHECK}  %-55s\n" "$MSG"
}

# ─── Estado de instalação ─────────────────────────────────────────────────────

state_get() {
    grep -m1 "^${1}=" "$STATE_FILE" 2>/dev/null | cut -d= -f2 || echo "0"
}

state_set() {
    if grep -q "^${1}=" "$STATE_FILE" 2>/dev/null; then
        sed -i "s/^${1}=.*/${1}=${2}/" "$STATE_FILE"
    else
        echo "${1}=${2}" >> "$STATE_FILE"
    fi
}

init_state() {
    mkdir -p "$(dirname "$STATE_FILE")"
    [ -f "$STATE_FILE" ] || touch "$STATE_FILE"
}

# ─── Funções de Recuperação de Pacotes (Apt/Dpkg) ─────────────────────────
apt_run() {
    local DESC="$1"; shift
    local RC=0
    set +e
    DEBIAN_FRONTEND=noninteractive "$@" 2>&1 | while IFS= read -r line; do
        if echo "$line" | grep -qiE "^E:|error|fatal"; then
            printf "  ${RED}%s${RESET}\n" "$line"
        elif echo "$line" | grep -qiE "^W:|warning"; then
            printf "  ${YELLOW}%s${RESET}\n" "$line"
        else
            printf "  ${DIM}%s${RESET}\n" "$line"
        fi
    done
    RC=${PIPESTATUS[0]}
    set -e
    return $RC
}

dpkg_recover() {
    echo ""
    step_warn "Tentando recuperar estado do dpkg (Possível falha de SD/Luz)..."
    set +e
    dpkg --configure -a 2>&1 | while IFS= read -r line; do
        printf "  ${DIM}%s${RESET}\n" "$line"
    done
    DEBIAN_FRONTEND=noninteractive apt-get install -f -y 2>&1 | while IFS= read -r line; do
        printf "  ${DIM}%s${RESET}\n" "$line"
    done
    set -e
    if dpkg --audit 2>&1 | grep -q "packages"; then
        step_err "dpkg ainda reporta inconsistências."
        return 1
    else
        step_ok "dpkg recuperado com sucesso"
        return 0
    fi
}

# ─── Tratamento de Erro Seguro (set -euo pipefail) ────────────────────────────
# Recomendado rodar 'set -euo pipefail' no inicio de cada script.
