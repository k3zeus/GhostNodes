#!/bin/bash

[ -n "${_GN_LOG_LOADED:-}" ] && return 0
_GN_LOG_LOADED=1

_GN_HALFIN_DIR="${HALFIN_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
_GN_LOG_DIR="${LOG_DIR:-${_GN_HALFIN_DIR}/logs}"
_GN_LOG_FILE=""
_GN_LOG_CONTEXT="ghost"

log_msg() {
    local level="$1"
    shift

    if [ -z "$_GN_LOG_FILE" ]; then
        mkdir -p "$_GN_LOG_DIR" 2>/dev/null || true
        _GN_LOG_FILE="${_GN_LOG_DIR}/ghostnode_$(date +%Y%m%d).log"
    fi

    printf "[%s] [%-5s] %s\n" "$(date '+%F %T')" "$level" "$*" >> "$_GN_LOG_FILE" 2>/dev/null || true
}

log_init() {
    _GN_LOG_CONTEXT="${1:-ghost}"
    mkdir -p "$_GN_LOG_DIR" 2>/dev/null || true
    _GN_LOG_FILE="${_GN_LOG_DIR}/${_GN_LOG_CONTEXT}_$(date +%Y%m%d).log"
    log_msg "INIT" "=== ${_GN_LOG_CONTEXT} iniciado ==="
}

log_ok()      { log_msg "OK" "$*"; }
log_warn()    { log_msg "WARN" "$*"; }
log_err()     { log_msg "ERR" "$*"; }
log_info()    { log_msg "INFO" "$*"; }
log_section() { log_msg "----" "$*"; }
log_debug()   { [ "${GN_DEBUG:-0}" = "1" ] && log_msg "DEBUG" "$*" || true; }

log_cmd() {
    local description="$1"
    shift
    log_msg "RUN" "${description}: $*"
    "$@"
}

log_show() {
    local lines="${1:-30}"
    [ -f "$_GN_LOG_FILE" ] && tail -n "$lines" "$_GN_LOG_FILE" || true
}

log_rotate() {
    local days="${1:-7}"
    find "$_GN_LOG_DIR" -name "*.log" -mtime +"$days" -delete 2>/dev/null || true
}
