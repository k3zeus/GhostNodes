#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  lib/init.sh — Ponto Único de Entrada da Biblioteca        ║
# ║  Ghost Node Nation / nodenation                            ║
# ╚══════════════════════════════════════════════════════════════╝
[ -n "${_GN_INIT_LOADED:-}" ] && return 0
_GN_INIT_LOADED=1

_GN_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_GN_HALFIN_ROOT="$(dirname "${_GN_LIB_DIR}")"
_GN_NODENATION_ROOT="$(dirname "${_GN_HALFIN_ROOT}")"

source "${_GN_LIB_DIR}/colors.sh"
source "${_GN_LIB_DIR}/ui.sh"
source "${_GN_LIB_DIR}/banner.sh"
source "${_GN_LIB_DIR}/log.sh"

# Carrega globals.env
for _GN_G in \
    "${_GN_HALFIN_ROOT}/var/globals.env" \
    "${_GN_NODENATION_ROOT}/var/globals.env" \
    "${_GN_LIB_DIR}/../var/globals.env"; do
    [ -f "$_GN_G" ] && { source "$_GN_G"; break; }
done

# Fallbacks
GN_USER="${GN_USER:-pleb}"
GN_ROOT="${GN_ROOT:-/home/${GN_USER}/nodenation}"
HALFIN_DIR="${HALFIN_DIR:-${_GN_HALFIN_ROOT}}"
TOOLS_DIR="${TOOLS_DIR:-${HALFIN_DIR}/tools}"
DOCKER_DIR="${DOCKER_DIR:-${HALFIN_DIR}/docker}"
LOG_DIR="${LOG_DIR:-${HALFIN_DIR}/logs}"
LIB_DIR="${LIB_DIR:-${_GN_LIB_DIR}}"
VAR_DIR="${VAR_DIR:-${HALFIN_DIR}/var}"
GN_DB_DIR="${GN_DB_DIR:-${VAR_DIR}}"
GN_DB_FILE="${GN_DB_FILE:-${GN_DB_DIR}/wifi_scan.db}"
GN_WIFI_LOG="${GN_WIFI_LOG:-${GN_DB_DIR}/log_scan_wifi.log}"

require_root() {
    if [ "$EUID" -ne 0 ]; then
        printf "\n  ${RED}[ERRO]${RESET} Execute como root: ${BOLD}sudo bash %s${RESET}\n\n" "$0"
        exit 1
    fi
}

require_cmd() {
    local CMD="$1" MSG="${2:-Comando '$1' não encontrado}"
    command -v "$CMD" &>/dev/null || { step_err "$MSG"; log_err "ausente: $CMD"; exit 1; }
}

load_hw_compat() {
    local HW="${GN_HW_COMPAT_FILE:-${GN_ROOT}/var/hardware.env}"
    [ -f "$HW" ] && source "$HW" || true
}
