#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║        Ghost Node Nation — Main Menu                         ║
# ╚══════════════════════════════════════════════════════════════╝

# ─── Inicialização e Imports ──────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
CORE_LIB="${SCRIPT_DIR}/lib/core_lib.sh"
GLOBALS="${SCRIPT_DIR}/var/globals.env"

if [ -f "$CORE_LIB" ]; then
    source "$CORE_LIB"
else
    echo -e "\e[31mErro: Não foi possível carregar $CORE_LIB\e[0m"
    exit 1
fi

if [ -f "$GLOBALS" ]; then
    source "$GLOBALS"
fi



# ══════════════════════════════════════════════════════════════════════════════
# MENU DE PROJETOS
# ══════════════════════════════════════════════════════════════════════════════
show_menu() {
    while true; do
        main_banner "◈ MAIN INSTALLER MENU ◈"
        section "Escolha o Projeto para Instalar / Gerenciar"
        echo ""
        
        printf "  ${BOLD}[1]${RESET}  Instalar ${CYAN}Halfin Node${RESET}\n"
        printf "  ${BOLD}[2]${RESET}  Instalar ${CYAN}Satoshi Node${RESET}\n"
        printf "  ${BOLD}[3]${RESET}  Instalar ${CYAN}Nick Node${RESET}\n"
        printf "  ${BOLD}[4]${RESET}  Instalar ${CYAN}Nash Node${RESET}\n"
        printf "  ${BOLD}[5]${RESET}  Instalar ${CYAN}Adam Node${RESET}\n"
        printf "  ${BOLD}[6]${RESET}  Instalar ${CYAN}Fiatjaf Node${RESET}\n"
        printf "  ${BOLD}[7]${RESET}  Instalar ${CYAN}Craig Node${RESET}\n"
        echo ""
        sep
        printf "  ${BOLD}[0]${RESET}  Sair\n"
        sep
        echo ""
        
        printf "  Opção: "
        read -r OPT
        
        case "$OPT" in
            1) 
               step_info "Chamando Halfin Node..."
               if [ -f "${HALFIN_DIR}/install.sh" ]; then
                   bash "${HALFIN_DIR}/install.sh"
               else
                   step_err "Halfin Node (install.sh) não encontrado na pasta ${HALFIN_DIR}"
                   press_enter
               fi
               ;;
            2) 
               step_info "Chamando Satoshi Node..."
               if [ -f "${SATOSHI_DIR}/install.sh" ]; then
                   bash "${SATOSHI_DIR}/install.sh"
               else
                   step_err "Satoshi Node (install.sh) não encontrado na pasta ${SATOSHI_DIR}"
                   press_enter
               fi
               ;;
            3) 
               step_info "Chamando Nick Node..."
               if [ -f "${NICK_DIR}/install.sh" ]; then
                   bash "${NICK_DIR}/install.sh"
               else
                   step_err "Nick Node não disponível ou pasta ausente (${NICK_DIR})"
                   press_enter
               fi
               ;;
            4) 
               step_warn "Nash Node — em breve"
               press_enter
               ;;
            5) 
               step_warn "Adam Node — em breve"
               press_enter
               ;;
            6) 
               step_warn "Fiatjaf Node — em breve"
               press_enter
               ;;
            7) 
               step_info "Fooling Craig Node..."
               if [ -f "${CRAIG_DIR}/install.sh" ]; then
                   bash "${CRAIG_DIR}/install.sh"
               else
                   step_err "Craig Node não disponível ou pasta ausente (${CRAIG_DIR})"
                   press_enter
               fi
               ;;
            0) 
               printf "\n  ${DIM}Saindo...${RESET}\n\n"
               exit 0 
               ;;
            *) 
               step_warn "Opção inválida"
               sleep 1 
               ;;
        esac
    done
}

# Inicializa banco de dados de estado (se necessário para a navegação raiz)
init_state

show_menu