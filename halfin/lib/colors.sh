#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  lib/ui.sh — Funções de Interface                           ║
# ║  Ghost Node Nation / Halfin                                 ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Uso:
#   source ${HALFIN_DIR}/lib/ui.sh
#
# Depende de: lib/colors.sh (carregado automaticamente)
#
[ -n "${_GN_UI_LOADED:-}" ] && return 0
_GN_UI_LOADED=1

# Garante que colors.sh está carregado
_GN_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=colors.sh
source "${_GN_LIB_DIR}/colors.sh"

# ══════════════════════════════════════════════════════════════════════════════
# SEPARADORES
# ══════════════════════════════════════════════════════════════════════════════

# Linha pesada
sep() {
    printf "${DIM}  ──────────────────────────────────────────────────────────────${RESET}\n"
}

# Linha pontilhada leve
sep_thin() {
    printf "${DIM}  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${RESET}\n"
}

# Linha dupla (para rodapé/cabeçalho de seção importante)
sep_double() {
    printf "${CYAN}${DIM}  ══════════════════════════════════════════════════════════════${RESET}\n"
}

# ══════════════════════════════════════════════════════════════════════════════
# CABEÇALHOS DE SEÇÃO
# ══════════════════════════════════════════════════════════════════════════════

# Seção com ícone opcional
# Uso: section "Título"  ou  section "🌐" "Título da Rede"
section() {
    echo ""
    if [ $# -ge 2 ]; then
        printf "${BOLD}${MAGENTA}  ┌─ %s  %s${RESET}\n" "$1" "$2"
    else
        printf "${BOLD}${MAGENTA}  ┌─ %s${RESET}\n" "$1"
    fi
    sep_thin
}

# Subsection — nível abaixo de section
subsection() {
    echo ""
    printf "${BOLD}${CYAN}  │  %s${RESET}\n" "$1"
    printf "${DIM}  │  %s${RESET}\n" "$(printf '%.0s─' {1..55})"
}

# ══════════════════════════════════════════════════════════════════════════════
# STEPS — mensagens de progresso padronizadas
# ══════════════════════════════════════════════════════════════════════════════

step_ok()   { printf "  ${CHECK} ${WHITE}%s${RESET}\n"        "$1"; }
step_warn() { printf "  ${WARN}  ${YELLOW}%s${RESET}\n"       "$1"; }
step_err()  { printf "  ${CROSS} ${RED}%s${RESET}\n"          "$1"; }
step_info() { printf "  ${ARROW} ${DIM}%s${RESET}\n"          "$1"; }
step_run()  { printf "  ${CYAN}⟳${RESET}  ${DIM}%s${RESET}\n" "$1"; }

# ══════════════════════════════════════════════════════════════════════════════
# LINHAS DE DADOS — label + valor com alinhamento
# ══════════════════════════════════════════════════════════════════════════════

# row "Label:" "Valor"  [cor_opcional]
row() {
    local COLOR="${3:-$WHITE}"
    printf "  ${DIM}%-24s${RESET} ${COLOR}${BOLD}%s${RESET}\n" "$1" "$2"
}

# row_status "Label:" "Valor" "ok|warn|err"
row_status() {
    local BADGE COLOR
    case "${3:-ok}" in
        ok)   BADGE="$CHECK"; COLOR="$GREEN"  ;;
        warn) BADGE="$WARN";  COLOR="$YELLOW" ;;
        err)  BADGE="$CROSS"; COLOR="$RED"    ;;
        *)    BADGE="$BULLET"; COLOR="$WHITE" ;;
    esac
    printf "  %-24s ${COLOR}%s${RESET}  %b\n" "$1" "$2" "$BADGE"
}

# ══════════════════════════════════════════════════════════════════════════════
# BARRA DE USO PERCENTUAL
# ══════════════════════════════════════════════════════════════════════════════

# bar_usage "Label:" 75 "texto extra"
bar_usage() {
    local LABEL="$1"
    local PCT="${2:-0}"
    local EXTRA="${3:-}"
    local FILLED=$(( PCT * 20 / 100 ))
    local EMPTY=$(( 20 - FILLED ))
    local BAR="" COLOR i=0

    if   [ "$PCT" -ge 90 ]; then COLOR="$RED"
    elif [ "$PCT" -ge 70 ]; then COLOR="$YELLOW"
    else                          COLOR="$GREEN"
    fi

    while [ $i -lt $FILLED ]; do BAR="${BAR}█"; i=$((i+1)); done
    while [ $i -lt 20 ];      do BAR="${BAR}░"; i=$((i+1)); done

    printf "  ${DIM}%-24s${RESET} ${COLOR}%s${RESET} ${BOLD}%3d%%${RESET}  ${DIM}%s${RESET}\n" \
           "$LABEL" "$BAR" "$PCT" "$EXTRA"
}

# ══════════════════════════════════════════════════════════════════════════════
# INTERATIVIDADE
# ══════════════════════════════════════════════════════════════════════════════

# Pausa simples
press_enter() {
    echo ""
    printf "  ${DIM}[ ENTER para continuar ]${RESET}"
    read -r
}

# Pausa com instrução de voltar
press_enter_or_back() {
    echo ""
    printf "  ${DIM}[ ENTER para voltar ao menu ]${RESET}"
    read -r
}

# Confirmação S/N
# confirm "Mensagem" [default: s|n]
# Retorna 0 se confirmado, 1 se negado
confirm() {
    local MSG="$1"
    local DEFAULT="${2:-s}"
    local OPTS

    [ "$DEFAULT" = "s" ] \
        && OPTS="${GREEN}${BOLD}S${RESET}/${DIM}n${RESET}" \
        || OPTS="${DIM}s${RESET}/${GREEN}${BOLD}N${RESET}"

    printf "\n  ${YELLOW}?${RESET} %s [%b]: " "$MSG" "$OPTS"
    read -r REPLY
    REPLY="${REPLY:-$DEFAULT}"
    [[ "$REPLY" =~ ^[sS]$ ]]
}

# ══════════════════════════════════════════════════════════════════════════════
# OPÇÃO INVÁLIDA — mensagem padrão para menus
# ══════════════════════════════════════════════════════════════════════════════
invalid_option() {
    step_warn "Opção inválida — tente novamente"
    sleep 1
}

# ══════════════════════════════════════════════════════════════════════════════
# SPINNER — animação de progresso para comandos longos
# Uso: algum_comando & spinner $! "Mensagem de progresso"
# ══════════════════════════════════════════════════════════════════════════════
spinner() {
    local PID=$1
    local MSG="${2:-Processando...}"
    local FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    while kill -0 "$PID" 2>/dev/null; do
        printf "\r  ${CYAN}%s${RESET}  %s " "${FRAMES[$((i % 10))]}" "$MSG"
        sleep 0.1
        i=$((i + 1))
    done
    printf "\r  ${CHECK}  %-60s\n" "$MSG"
}

# ══════════════════════════════════════════════════════════════════════════════
# EXECUTA SCRIPT EXTERNO — com fallback e log
# ══════════════════════════════════════════════════════════════════════════════
# Uso: run_script "/caminho/script.sh" "Descrição"
run_script() {
    local SCRIPT="$1"
    local DESC="${2:-Script}"

    if [ ! -f "$SCRIPT" ]; then
        step_err "Script não encontrado: $SCRIPT"
        return 1
    fi
    if [ ! -x "$SCRIPT" ]; then
        step_warn "Sem permissão de execução — corrigindo: $SCRIPT"
        chmod +x "$SCRIPT"
    fi

    echo ""
    sep
    bash "$SCRIPT"
    local RC=$?
    sep
    echo ""

    [ $RC -ne 0 ] && step_warn "Script finalizado com código: $RC"
    return $RC
}
