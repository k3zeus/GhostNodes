#!/bin/bash

[ -n "${_GN_BANNER_LOADED:-}" ] && [ -n "${BOLD:-}" ] && declare -F banner >/dev/null 2>&1 && return 0
_GN_BANNER_LOADED=1

_GN_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_GN_LIB_DIR}/colors.sh"
source "${_GN_LIB_DIR}/ui.sh"

status_bar() {
    local datetime
    datetime="$(date '+%d/%m/%Y %H:%M:%S')"
    printf "${DIM}  Host: %s  |  Time: %s${RESET}\n" "$(hostname 2>/dev/null || echo n/a)" "$datetime"
}

main_banner() {
    local title="${1:-GHOSTNODES}"
    clear
    printf "${BOLD}${CYAN}\n"
    printf "  ============================================================\n"
    printf "  %s\n" "$title"
    printf "  ============================================================\n"
    printf "${RESET}"
    status_bar
    echo ""
}

banner() {
    main_banner "  GHOSTNODES - HALFIN  "
}

header_compact() {
    main_banner "${1:-GHOSTNODES}"
}

header_install() {
    main_banner "  GHOSTNODES INSTALL ${1:-}  "
}

footer() {
    echo ""
    sep
    printf "  ${DIM}%s - %s${RESET}\n" "${1:-Operacao concluida}" "$(date '+%d/%m/%Y %H:%M:%S')"
    echo ""
}

print_motd() {
    printf "\n${BOLD}${CYAN}GhostNodes / Halfin${RESET}\n"
    printf "${DIM}Host:${RESET} %s  ${DIM}User:${RESET} %s  ${DIM}Time:${RESET} %s\n\n" \
        "$(hostname 2>/dev/null || echo n/a)" \
        "$(whoami 2>/dev/null || echo n/a)" \
        "$(date '+%d/%m/%Y %H:%M:%S')"
}
