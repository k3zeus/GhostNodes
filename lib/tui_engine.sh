#!/bin/bash
# Ghost Nodes TUI engine ? renderer and keyboard controller without external runtime dependencies.
[ -n "${_GN_TUI_ENGINE_LOADED:-}" ] && return 0
_GN_TUI_ENGINE_LOADED=1

: "${RESET:=\e[0m}" "${BOLD:=\e[1m}" "${DIM:=\e[2m}"
: "${CYAN:=\e[36m}" "${WHITE:=\e[97m}" "${YELLOW:=\e[33m}" "${GREEN:=\e[32m}" "${RED:=\e[31m}"
TUI_BLUE="${TUI_BLUE:-\e[34m}"
TUI_ORANGE="${TUI_ORANGE:-\e[33m}"
TUI_BRIGHT_CYAN="${TUI_BRIGHT_CYAN:-\e[96m}"
TUI_BRIGHT_BLUE="${TUI_BRIGHT_BLUE:-\e[94m}"
TUI_BRIGHT_YELLOW="${TUI_BRIGHT_YELLOW:-\e[93m}"
TUI_BRIGHT_GREEN="${TUI_BRIGHT_GREEN:-\e[92m}"
TUI_BRIGHT_RED="${TUI_BRIGHT_RED:-\e[91m}"

_tui_cols() { printf '%s\n' "${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"; }
_tui_rows() { printf '%s\n' "${LINES:-$(tput lines 2>/dev/null || echo 24)}"; }

tui_begin_frame() {
    if [ "${GN_TUI_NO_CLEAR:-0}" = 1 ]; then
        GN_TUI_REDRAW=0
    elif [ "${TUI_RENDERED:-0}" = 1 ]; then
        GN_TUI_REDRAW=1
    else
        GN_TUI_REDRAW=0
    fi
    TUI_RENDERED=1
    export GN_TUI_REDRAW
}

tui_capability() {
    local cols rows
    cols="$(_tui_cols)"; rows="$(_tui_rows)"
    if [ "${TERM:-dumb}" = dumb ] || [ "$cols" -lt 80 ] || [ "$rows" -lt 24 ]; then echo safe
    elif [ "$cols" -ge 80 ] && [ "$rows" -ge 35 ]; then echo wide
    else echo compact; fi
}

tui_tone_focus_color() {
    case "${1:-identity}" in
        identity) printf '%b' "$TUI_BRIGHT_CYAN" ;; bitcoin) printf '%b' "$TUI_BRIGHT_YELLOW" ;;
        success) printf '%b' "$TUI_BRIGHT_GREEN" ;; danger|critical) printf '%b' "$TUI_BRIGHT_RED" ;;
        warning) printf '%b' "$TUI_BRIGHT_YELLOW" ;; *) printf '%b' "$WHITE" ;;
    esac
}

tui_tone_color() {
    case "${1:-identity}" in
        identity) printf '%b' "$CYAN" ;; bitcoin) printf '%b' "$TUI_ORANGE" ;;
        success) printf '%b' "$GREEN" ;; danger|critical) printf '%b' "$RED" ;;
        warning) printf '%b' "$YELLOW" ;; *) printf '%b' "$WHITE" ;;
    esac
}

tui_read_key() {
    local key first second rest
    IFS= read -rsn1 key || return 1
    case "$key" in
        $'\x1b')
            # ANSI CSI: ESC [ A/B/C/D; SS3: ESC O A/B/C/D.
            IFS= read -rsn1 -t 0.25 first || { echo ESC; return 0; }
            IFS= read -rsn1 -t 0.25 second || { echo ESC; return 0; }
            case "$first$second" in
                '[A'|'OA') echo UP ;; '[B'|'OB') echo DOWN ;;
                '[C'|'OC') echo RIGHT ;; '[D'|'OD') echo LEFT ;;
                *)
                    # Consome par?metros modificadores como ESC [ 1 ; 5 A.
                    rest="$first$second"
                    while IFS= read -rsn1 -t 0.02 key; do
                        rest+="$key"
                        [[ "$key" =~ [A-Za-z~] ]] && break
                    done
                    case "$rest" in *A) echo UP ;; *B) echo DOWN ;; *C) echo RIGHT ;; *D) echo LEFT ;; *) echo ESC ;; esac ;;
            esac ;;
        '') echo ENTER ;;
        *) printf '%s\n' "$key" ;;
    esac
}

tui_move_focus() {
    local current="$1" event="$2" layout="$3" next="$current"
    case "$layout:$event" in
        wide:LEFT|medium:LEFT) next=$(( current == 1 ? 6 : current - 1 )) ;;
        wide:RIGHT|medium:RIGHT) next=$(( current == 6 ? 1 : current + 1 )) ;;
        wide:UP) next=$(( current <= 3 ? current + 3 : current - 3 )) ;;
        wide:DOWN) next=$(( current > 3 ? current - 3 : current + 3 )) ;;
        medium:UP) next=$(( current <= 2 ? current + 4 : current - 2 )) ;;
        medium:DOWN) next=$(( current > 4 ? current - 4 : current + 2 )) ;;
        compact:UP|safe:UP) next=$(( current == 1 ? 6 : current - 1 )) ;;
        compact:DOWN|safe:DOWN) next=$(( current == 6 ? 1 : current + 1 )) ;;
    esac
    printf '%s\n' "$next"
}

tui_main_header() {
    local host="$1" uptime="$2" user="$3"
    printf "  ${DIM}Node:${RESET} ${WHITE}%-16s${RESET}  ${DIM}Up:${RESET} %-25s  ${DIM}User:${RESET} %s\n\n" "$host" "$uptime" "$user"
    printf "  ${CYAN}???????????????${RESET} ${BOLD}${CYAN}[ MENU PRINCIPAL ]${RESET} ${CYAN}???????????????${RESET}\n"
}

tui_repeat() {
    local count="$1" char="$2" out=""
    while [ "$count" -gt 0 ]; do out+="$char"; count=$((count - 1)); done
    printf '%s' "$out"
}
tui_pad() {
    local text="$1" width="$2" count
    text="${text:0:$width}"
    printf '%s' "$text"
    count=$((width - ${#text}))
    [ "$count" -gt 0 ] && tui_repeat "$count" ' '
}
tui_card_border_color() {
    local focused="$1" tone="$2"
    if [ "$focused" = 1 ]; then printf '%b%b' "$BOLD" "$(tui_tone_focus_color "$tone")"
    else printf '%b' "$DIM$WHITE"; fi
}
tui_card_text_color() {
    local focused="$1" tone="$2" role="$3"
    if [ "$focused" = 1 ] && [ "$role" = title ]; then tui_tone_focus_color "$tone"
    else printf '%b' "$WHITE"; fi
}
tui_card_border() {
    local focused="$1" width="$2" edge="$3" tone="$4" left right fill
    if [ "$edge" = top ]; then left='╔'; right='╗'; else left='╚'; right='╝'; fi
    fill='═'
    printf '%b%s' "$(tui_card_border_color "$focused" "$tone")" "$left"
    tui_repeat "$((width - 2))" "$fill"
    printf '%s%b' "$right" "$RESET"
}
tui_card_line() {
    local focused="$1" width="$2" tone="$3" role="$4" text="$5" border text_color
    border="$(tui_card_border_color "$focused" "$tone")"
    text_color="$(tui_card_text_color "$focused" "$tone" "$role")"
    printf '%b║%b ' "$border" "$text_color"
    tui_pad "$text" "$((width - 4))"
    printf ' %b║%b' "$border" "$RESET"
}
tui_card_id_line() {
    local focused="$1" width="$2" tone="$3" id="$4" icon="$5" border gap
    border="$(tui_card_border_color "$focused" "$tone")"
    gap=$((width - 4 - 3 - ${#icon}))
    printf '%b║%b [%s]' "$border" "$WHITE" "$id"
    tui_repeat "$gap" ' '
    printf '%s %b║%b' "$icon" "$border" "$RESET"
}
tui_card_rows() {
    local id="$1" focused="$2" width="$3" tone="$4" icon="$5" title="$6" desc1="$7" desc2="$8"
    TUI_CARD=()
    TUI_CARD+=("$(tui_card_border "$focused" "$width" top "$tone")")
    TUI_CARD+=("$(tui_card_id_line "$focused" "$width" "$tone" "$id" "$icon")")
    TUI_CARD+=("$(tui_card_line "$focused" "$width" "$tone" title "$title")")
    TUI_CARD+=("$(tui_card_line "$focused" "$width" "$tone" normal "$desc1")")
    TUI_CARD+=("$(tui_card_line "$focused" "$width" "$tone" normal "$desc2")")
    TUI_CARD+=("$(tui_card_border "$focused" "$width" bottom "$tone")")
}
tui_menu_pad() { local width="${1:-80}" cols; cols="$(_tui_cols)"; case "$cols" in ''|*[!0-9]*) cols=80;; esac; [ "$cols" -gt "$width" ] && printf '%*s' "$(( (cols - width) / 2 ))" ''; }
tui_main_header() { local host="$1" uptime="$2" user="$3" pad; pad="$(tui_menu_pad 80)"; printf "%s${DIM}Node:${RESET} ${WHITE}%-16s${RESET}  ${DIM}Up:${RESET} %-25s  ${DIM}User:${RESET} %s\n\n" "$pad" "$host" "$uptime" "$user"; printf "%s${CYAN}-------------------- [ MENU PRINCIPAL ] --------------------${RESET}\n" "$pad"; }
tui_main_cards() {
    local selected="$1" layout="$2" width=23 gap=3 row col idx line card_line card_name pad
    local ids=(1 2 3 4 5 6) tones=(identity identity identity bitcoin success danger) icons=(⚙ ⌁ ▣ ₿ ↻ ⏻)
    local titles=('Sistema' 'Conexoes de Rede' 'Docker' 'Satoshi Node' 'Reiniciar o Node' 'Desligar o Node')
    local d1=('Servicos e' 'Wi-Fi e conexoes' 'Instalacao e' 'Bitcoin Core' 'Reinicia com' 'Desliga com')
    local d2=('atualizacoes' 'diagnostico' 'containers' 'monitoramento' 'confirmacao' 'confirmacao')
    [ "$layout" = wide ] || { tui_main_list "$selected"; return; }
    pad="$(tui_menu_pad 80)"; [ "$(_tui_cols)" -lt 100 ] && gap=2
    for row in 0 1; do
        for col in 0 1 2; do
            idx=$((row * 3 + col)); tui_card_rows "${ids[$idx]}" "$([ "${ids[$idx]}" = "$selected" ] && echo 1 || echo 0)" "$width" "${tones[$idx]}" "${icons[$idx]}" "${titles[$idx]}" "${d1[$idx]}" "${d2[$idx]}"
            case "$col" in 0) CARD_0=("${TUI_CARD[@]}");; 1) CARD_1=("${TUI_CARD[@]}");; 2) CARD_2=("${TUI_CARD[@]}");; esac
        done
        for line in 0 1 2 3 4 5; do
            printf '%s  ' "$pad"
            for col in 0 1 2; do card_name="CARD_${col}[$line]"; card_line="${!card_name}"; printf '%s' "$card_line"; [ "$col" -lt 2 ] && printf '%*s' "$gap" ''; done
            printf '\n'
        done
        printf '\n'
    done
}
tui_main_list() {
    local selected="$1" i focus title
    local titles=('Sistema' 'Conexoes de Rede' 'Docker' 'Satoshi Node' 'Reiniciar o Node' 'Desligar o Node')
    local desc=('Servicos e atualizacoes' 'Wi-Fi e conexoes e diagnostico' 'Instalacao e containers' 'Bitcoin Core e monitoramento' 'Reinicia com confirmacao' 'Desliga com confirmacao')
    for i in 1 2 3 4 5 6; do
        title="${titles[$((i - 1))]}"
        if [ "$i" = "$selected" ]; then focus="$BOLD$(tui_tone_focus_color identity)"; else focus="$WHITE"; fi
        printf "  %b[%s] %s%b\n      %b%s%b\n" "$focus" "$i" "$title" "$RESET" "$WHITE" "${desc[$((i - 1))]}" "$RESET"
    done
    printf '\n'
}
tui_footer() {
    local pad
    pad="$(tui_menu_pad 80)"
    printf "%s${DIM}┌────────────────────────────────────────────────────────────────────────────┐${RESET}\n" "$pad"
    printf "%s${DIM}│${RESET} ${CYAN}↑ UP  ↓ DOWN  ← LEFT  → RIGHT${RESET}  ${BOLD}ENTER${RESET} ou digite o numero da opcao. ${DIM}│${RESET}\n" "$pad"
    printf "%s${DIM}└────────────────────────────────────────────────────────────────────────────┘${RESET}\n" "$pad"
    printf "%s${DIM}┌────────────────────────────────────────────────────────────────────────────┐${RESET}\n" "$pad"
    printf "%s${DIM}│${RESET} ${RED}${BOLD}[q]${RESET} Sair do sistema                                                        ${DIM}│${RESET}\n" "$pad"
    printf "%s${DIM}└────────────────────────────────────────────────────────────────────────────┘${RESET}\n\n" "$pad"
    printf "%s${BOLD}Selecione uma opcao:${RESET} " "$pad"
}
tui_render_main() {
    local selected="${1:-1}" host="$2" uptime="$3" user="$4" layout
    tui_begin_frame
    layout="$(tui_capability)"
    tui_main_header "$host" "$uptime" "$user"
    tui_main_cards "$selected" "$layout"
    tui_footer
}
