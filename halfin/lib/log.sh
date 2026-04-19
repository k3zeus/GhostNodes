#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  lib/log.sh — Sistema de Log Centralizado                  ║
# ║  Ghost Node Nation / Halfin                                 ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Uso:
#   source ${HALFIN_DIR}/lib/log.sh
#   log_init "nome_do_script"   # chama uma vez no início
#   log_ok   "mensagem"
#   log_warn "mensagem"
#   log_err  "mensagem"
#
[ -n "${_GN_LOG_LOADED:-}" ] && return 0
_GN_LOG_LOADED=1

# ── Configuração de caminhos ──────────────────────────────────────────────────
_GN_HALFIN_DIR="${HALFIN_DIR:-/home/pleb/nodenation/halfin}"
_GN_LOG_DIR="${LOG_DIR:-${_GN_HALFIN_DIR}/logs}"
_GN_LOG_FILE=""          # definido por log_init
_GN_LOG_CONTEXT="ghost"  # nome do script/contexto atual

# ══════════════════════════════════════════════════════════════════════════════
# log_init — inicializa o sistema de log para o script atual
# Uso: log_init "wifi_scan"
# ══════════════════════════════════════════════════════════════════════════════
log_init() {
    _GN_LOG_CONTEXT="${1:-ghost}"
    _GN_LOG_FILE="${_GN_LOG_DIR}/${_GN_LOG_CONTEXT}_$(date +%Y%m%d).log"
    mkdir -p "$_GN_LOG_DIR" 2>/dev/null || true
    log_msg "INIT" "=== $_GN_LOG_CONTEXT iniciado por ${SUDO_USER:-$(whoami 2>/dev/null || echo root)} ==="
}

# ══════════════════════════════════════════════════════════════════════════════
# log_msg — grava uma linha no arquivo de log
# Uso: log_msg "LEVEL" "mensagem"
# ══════════════════════════════════════════════════════════════════════════════
log_msg() {
    local LEVEL="$1"; shift
    # Se log_init não foi chamado ainda, usa arquivo padrão
    if [ -z "$_GN_LOG_FILE" ]; then
        _GN_LOG_FILE="${_GN_LOG_DIR}/ghostnode_$(date +%Y%m%d).log"
        mkdir -p "$_GN_LOG_DIR" 2>/dev/null || true
    fi
    printf "[%s] [%-5s] %s\n" \
        "$(date '+%F %T')" "$LEVEL" "$*" \
        >> "$_GN_LOG_FILE" 2>/dev/null || true
}

# ── Atalhos de nível ──────────────────────────────────────────────────────────
log_ok()      { log_msg "OK"   "$*"; }
log_warn()    { log_msg "WARN" "$*"; }
log_err()     { log_msg "ERR"  "$*"; }
log_info()    { log_msg "INFO" "$*"; }
log_section() { log_msg "---"  "════ $* ════"; }
log_debug()   {
    # Só grava se GN_DEBUG=1
    [ "${GN_DEBUG:-0}" = "1" ] && log_msg "DEBUG" "$*" || true
}

# ══════════════════════════════════════════════════════════════════════════════
# log_cmd — executa um comando e loga stdout+stderr
# Uso: log_cmd "descrição" comando arg1 arg2
# Retorna o exit code do comando
# ══════════════════════════════════════════════════════════════════════════════
log_cmd() {
    local DESC="$1"; shift
    log_msg "RUN" "$DESC: $*"
    local OUTPUT RC
    OUTPUT=$("$@" 2>&1)
    RC=$?
    # Grava cada linha do output no log
    echo "$OUTPUT" | while IFS= read -r LINE; do
        log_msg "OUT" "$LINE"
    done
    if [ $RC -eq 0 ]; then
        log_ok "$DESC: concluído (RC=0)"
    else
        log_err "$DESC: falhou (RC=$RC)"
    fi
    return $RC
}

# ══════════════════════════════════════════════════════════════════════════════
# log_show — exibe o log atual na tela (últimas N linhas)
# Uso: log_show [N_linhas]
# ══════════════════════════════════════════════════════════════════════════════
log_show() {
    local N="${1:-30}"
    if [ -f "$_GN_LOG_FILE" ]; then
        echo ""
        printf "  ${DIM}Log: %s (últimas %s linhas)${RESET}\n\n" "$_GN_LOG_FILE" "$N"
        tail -n "$N" "$_GN_LOG_FILE" | while IFS= read -r LINE; do
            # Colore por nível
            case "$LINE" in
                *\[OK\]*)    printf "  ${GREEN}%s${RESET}\n" "$LINE" ;;
                *\[WARN\]*)  printf "  ${YELLOW}%s${RESET}\n" "$LINE" ;;
                *\[ERR\]*)   printf "  ${RED}%s${RESET}\n" "$LINE" ;;
                *\[DEBUG\]*)  printf "  ${DIM}%s${RESET}\n" "$LINE" ;;
                *)           printf "  ${DIM}%s${RESET}\n" "$LINE" ;;
            esac
        done
    else
        printf "  ${DIM}Nenhum log disponível ainda.${RESET}\n"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# log_rotate — mantém apenas os últimos N dias de logs
# Uso: log_rotate [dias=7]
# ══════════════════════════════════════════════════════════════════════════════
log_rotate() {
    local DAYS="${1:-7}"
    find "$_GN_LOG_DIR" -name "*.log" -mtime +"$DAYS" -delete 2>/dev/null || true
    log_info "Logs anteriores a $DAYS dias removidos"
}
