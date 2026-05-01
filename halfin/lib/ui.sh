#!/bin/bash

[ -n "${_GN_UI_LOADED:-}" ] && declare -F sep >/dev/null 2>&1 && return 0
_GN_UI_LOADED=1

_GN_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_GN_LIB_DIR}/colors.sh"

sep() {
    printf "${DIM}  ------------------------------------------------------------${RESET}\n"
}

sep_thin() {
    printf "${DIM}  ............................................................${RESET}\n"
}

sep_double() {
    printf "${CYAN}${DIM}  ============================================================${RESET}\n"
}

section() {
    echo ""
    printf "${BOLD}${MAGENTA}  %s${RESET}\n" "$1"
    sep_thin
}

subsection() {
    echo ""
    printf "${BOLD}${CYAN}  %s${RESET}\n" "$1"
}

step_ok()   { printf "  ${CHECK} ${WHITE}%s${RESET}\n" "$1"; }
step_warn() { printf "  ${WARN} ${YELLOW}%s${RESET}\n" "$1"; }
step_err()  { printf "  ${CROSS} ${RED}%s${RESET}\n" "$1"; }
step_info() { printf "  ${ARROW} ${DIM}%s${RESET}\n" "$1"; }
step_run()  { printf "  ${CYAN}...${RESET} ${DIM}%s${RESET}\n" "$1"; }

row() {
    local color="${3:-$WHITE}"
    printf "  ${DIM}%-24s${RESET} ${color}${BOLD}%s${RESET}\n" "$1" "$2"
}

row_status() {
    local badge color
    case "${3:-ok}" in
        ok) badge="$CHECK"; color="$GREEN" ;;
        warn) badge="$WARN"; color="$YELLOW" ;;
        err) badge="$CROSS"; color="$RED" ;;
        *) badge="$BULLET"; color="$WHITE" ;;
    esac
    printf "  ${DIM}%-24s${RESET} ${color}%s${RESET} %b\n" "$1" "$2" "$badge"
}

bar_usage() {
    local label="$1"
    local pct="${2:-0}"
    local extra="${3:-}"
    local filled=$(( pct * 20 / 100 ))
    local bar=""
    local i
    local color="$GREEN"

    [ "$pct" -ge 70 ] && color="$YELLOW"
    [ "$pct" -ge 90 ] && color="$RED"

    for ((i = 0; i < 20; i++)); do
        if [ "$i" -lt "$filled" ]; then
            bar="${bar}#"
        else
            bar="${bar}-"
        fi
    done

    printf "  ${DIM}%-24s${RESET} ${color}%s${RESET} ${BOLD}%3d%%${RESET} ${DIM}%s${RESET}\n" "$label" "$bar" "$pct" "$extra"
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
    local message="$1"
    local default="${2:-s}"
    local options
    local reply

    if [ "$default" = "s" ]; then
        options="${GREEN}${BOLD}S${RESET}/${DIM}n${RESET}"
    else
        options="${DIM}s${RESET}/${GREEN}${BOLD}N${RESET}"
    fi

    printf "\n  ${YELLOW}?${RESET} %s [%b]: " "$message" "$options"
    read -r reply
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[sS]$ ]]
}

invalid_option() {
    step_warn "Opcao invalida - tente novamente"
    sleep 1
}

spinner() {
    local pid="$1"
    local message="${2:-Processando...}"
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${CYAN}...${RESET} %s" "$message"
        sleep 0.2
    done
    printf "\r  ${CHECK} %s\n" "$message"
}

run_script() {
    local script="$1"
    local description="${2:-Script}"

    if [ ! -f "$script" ]; then
        step_err "Script nao encontrado: $script"
        return 1
    fi

    if [ ! -x "$script" ]; then
        chmod +x "$script" 2>/dev/null || true
    fi

    echo ""
    sep
    bash "$script"
    local rc=$?
    sep
    echo ""
    [ "$rc" -ne 0 ] && step_warn "${description} finalizado com codigo ${rc}"
    return "$rc"
}
