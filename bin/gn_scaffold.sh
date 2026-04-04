#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Ghost Nodes — Scaffold / Gerador de Suporte de Hardware     ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

# Obtém a raiz do monorepo (onde quer que este script esteja executando)
GN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." &> /dev/null && pwd)"
AUTO_FILE="${GN_ROOT}/var/auto.sh"
CORE_LIB="${GN_ROOT}/lib/core_lib.sh"

if [ -f "$CORE_LIB" ]; then
    source "$CORE_LIB"
else
    echo -e "\e[31mErro: core_lib.sh não encontrado em $CORE_LIB\e[0m"
    exit 1
fi

main_banner "  ◈  G E R A D O R   D E   S C A F F O L D  ◈"
section "Adicionar novo suporte a Hardware (var/auto.sh)"

echo ""
printf "  ${BOLD}1. Qual subprojeto deseja configurar?${RESET} (ex: halfin, satoshi)\n"
printf "  ${CYAN}Subprojeto:${RESET} "; read -r SUBPROJ
SUBPROJ=$(echo "$SUBPROJ" | xargs)

printf "\n  ${BOLD}2. Nome flexível do Hardware (expressão regular)?${RESET} (ex: Raspberry Pi 5|RPI5)\n"
printf "  ${CYAN}Modelo (Regex):${RESET} "; read -r HW_REGEX

printf "\n  ${BOLD}3. Arquitetura exigida?${RESET} (ex: arm64, x86_64, any)\n"
printf "  ${DIM}[ arm64 / x86_64 / armhf / any ]${RESET}\n"
printf "  ${CYAN}Arquitetura:${RESET} "; read -r ARCH
ARCH=${ARCH:-any}

printf "\n  ${BOLD}4. Sistema Operacional exigido (Regex)?${RESET} (ex: Debian.*bookworm|Ubuntu)\n"
printf "  ${CYAN}SO (Regex):${RESET} "; read -r OS_REGEX

printf "\n  ${BOLD}5. Caminho do script de instalação?${RESET} (ex: halfin/pre_install_rpi5.sh)\n"
printf "  ${CYAN}Script Path:${RESET} "; read -r SCRIPT_PATH

printf "\n  ${BOLD}6. Qual a descrição amigável?${RESET} (ex: Raspberry Pi 5 — Debian Bookworm arm64)\n"
printf "  ${CYAN}Descrição:${RESET} "; read -r DESC

echo ""
sep

# Validação curta
if [ -z "$SUBPROJ" ] || [ -z "$HW_REGEX" ] || [ -z "$OS_REGEX" ] || [ -z "$SCRIPT_PATH" ]; then
    step_err "Faltam argumentos exigidos. Cancelado."
    exit 1
fi

# Visualização
printf "  ${YELLOW}O bloco abaixo será inserido em var/auto.sh:${RESET}\n\n"

CAT_BLOCK=$(cat <<EOF
# Gerado via gn_scaffold ($(date +%Y-%m-%d))
gn_register_preinstall \\
    "$SUBPROJ" \\
    "$HW_REGEX" \\
    "$ARCH" \\
    "$OS_REGEX" \\
    "$SCRIPT_PATH" \\
    "$DESC"
EOF
)

echo "$CAT_BLOCK" | while read -r line; do printf "    ${DIM}%s${RESET}\n" "$line"; done

if confirm "Adicionar ao var/auto.sh e CRIAR script template na pasta respectiva?"; then
    echo "" >> "$AUTO_FILE"
    echo "$CAT_BLOCK" >> "$AUTO_FILE"
    
    # ── Criação do Arquivo Físico do Script ──
    # Garante que o diretório exista
    TARGET_DIR="$(dirname "${GN_ROOT}/${SCRIPT_PATH}")"
    mkdir -p "$TARGET_DIR"

    if [ ! -f "${GN_ROOT}/${SCRIPT_PATH}" ]; then
        cat << 'EOF_TEMPLATE' > "${GN_ROOT}/${SCRIPT_PATH}"
#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  pre_install.sh — Template Autogerado (Ghost Nodes)          ║
# ╚══════════════════════════════════════════════════════════════╝
#
# !! ATENÇÃO DESENVOLVEDOR (Customização de SO) !!
# Dependendo do projeto alvo (Ex: Halfin), a rede deve ser meticulosa:
# - Se o seu SO não utilizar 'hostapd', você DEVE adaptar a rotina AP.
# - É OBRIGATÓRIO não utilizar serviços de DNS nativos em portas conflitantes
#   (ex: ubuntu's systemd-resolved ou Dnsmasq) caso o projeto vá orquestrá-los 
#   usando Docker (ex: Pi-Hole precisa da porta 53/TCP livre).
#
# Este script DEVE terminar garantindo a preparação para a extração do repositório
# para GN_ROOT e configuração de credenciais base via GN_USER.
# ────────────────────────────────────────────────────────────────

set -euo pipefail

# Dependência Essencial: core_lib.sh já deve estar importado via bootstrap
export DEBIAN_FRONTEND=noninteractive

header "Instalação Automática Pré-Configurada"
section "Atualização de Recursos Nativos e Resolução de Conflitos"

step_run "Desativando DNS nativos divergentes (Placeholder)..."
# TODO: systemctl stop systemd-resolved || true

step_run "Instalando pré-requisitos do Subprojeto (Ex: curl, hostapd, wireguard-tools)..."
# TODO: apt-get install -y curl

step_ok "Pré-instalação e Limpeza finalizadas com sucesso."
EOF_TEMPLATE
        chmod +x "${GN_ROOT}/${SCRIPT_PATH}"
        step_ok "Template de script gerado e com permissões dadas em: ${GN_ROOT}/${SCRIPT_PATH}"
    else
        step_warn "O script ${GN_ROOT}/${SCRIPT_PATH} já existia. Nenhuma substituição de código feita, registro adicionado ao auto.sh."
    fi

    step_ok "Suporte de Hardware registrado com sucesso em 'var/auto.sh'!"
else
    step_warn "Cancelado pelo usuário."
fi
