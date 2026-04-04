#!/bin/bash
#
# ╔══════════════════════════════════════════════════════════════╗
# ║  satoshi/install.sh — Bitcoin Node Setup                     ║
# ║  Ghost Node Nation - Satoshi Node                      ║
# ╚══════════════════════════════════════════════════════════════╝
# v.02 - 22032026
#
# Chamado por: nodenation → opção [2] Satoshi Node
# Recebe via export: GN_HW_ARCH, GN_HW_RAM_GB, GN_INSTALL_MODE
#

# ── Biblioteca modular ────────────────────────────────────────────────────────
_GN_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_GN_FIND="$_GN_SELF"
while [ ! -d "${_GN_FIND}/lib" ] && [ "$_GN_FIND" != "/" ]; do
    _GN_FIND="$(dirname "$_GN_FIND")"
done
source "${_GN_FIND}/halfin/lib/init.sh" 2>/dev/null || {
    echo "[ERRO] lib/init.sh não encontrado. Execute via menu nodenation."
    exit 1
}

log_init "satoshi_install"
require_root

# ── Variáveis locais ──────────────────────────────────────────────────────────
SATOSHI_DIR="${GN_ROOT}/satoshi"
SATOSHI_LOG_DIR="${SATOSHI_DIR}/logs"
INSTALL_MODE="${GN_INSTALL_MODE:-standard}"  # full | pruned | standard
BITCOIN_USER="bitcoin"
BITCOIN_DIR="/home/${BITCOIN_USER}/.bitcoin"
BITCOIN_VERSION="26.0"   # atualizar conforme release

mkdir -p "$SATOSHI_LOG_DIR"

# ══════════════════════════════════════════════════════════════════════════════
# MENU PRINCIPAL DO SATOSHI INSTALL
# ══════════════════════════════════════════════════════════════════════════════
banner() {
    main_banner "  ◈  S A T O S H I   N O D E   —   I N S T A L L  ◈"
}

main() {
    banner

    echo ""
    # Exibe modo de instalação definido pelo pre-install
    case "$INSTALL_MODE" in
        full)
            step_ok "Modo detectado: ${BOLD}Full Node${RESET} (blockchain completa)"
            ;;
        pruned)
            step_warn "Modo detectado: ${BOLD}Pruned Node${RESET}"
            printf "  ${DIM}  Disco insuficiente para Full Node — será instalado como Pruned.${RESET}\n"
            printf "  ${DIM}  Um Pruned Node valida transações mas não armazena histórico completo.${RESET}\n"
            ;;
        *)
            step_info "Modo: padrão (será definido na configuração)"
            ;;
    esac

    echo ""
    sep

    while true; do
        echo ""
        printf "  ${BOLD}${CYAN}[1]${RESET}  Instalar Bitcoin Core (bitcoind)\n"
        printf "  ${BOLD}${CYAN}[2]${RESET}  Configurar bitcoin.conf\n"
        printf "  ${BOLD}${CYAN}[3]${RESET}  Verificar instalação\n"
        printf "  ${BOLD}[0]${RESET}  Voltar\n"
        echo ""
        printf "  Opção: "
        read -r OPT
        case "$OPT" in
            1) instalar_bitcoind ;;
            2) configurar_bitcoin ;;
            3) verificar_bitcoin ;;
            0|"") return ;;
            *) step_warn "Opção inválida" ;;
        esac
    done
}

instalar_bitcoind() {
    banner
    section "⬇  Download Daemon Bitcoin"
    section "⬇  Download Bitcoin Core ${BITCOIN_VERSION}"
    echo ""

    step_info "Arquitetura: ${GN_HW_ARCH:-desconhecida}"

    echo ""
    printf "  ${BOLD}Qual implementação você deseja instalar?${RESET}\n"
    printf "  ${CYAN}[1]${RESET} Bitcoin Core (Oficial, Recomendado)\n"
    printf "  ${CYAN}[2]${RESET} Bitcoin Knots (Avançado)\n"
    printf "  ${DIM}[0] Voltar${RESET}\n"
    printf "\n  Opção: "
    read -r VARIANT_OPT

    local BTC_VARIANT="Core"
    local URL=""
    
    if [ "$VARIANT_OPT" = "1" ]; then
        BITCOIN_VERSION="28.1"
        case "${GN_HW_ARCH:-unknown}" in
            arm64)  URL="https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-aarch64-linux-gnu.tar.gz" ;;
            x86_64) URL="https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz" ;;
            armhf)  URL="https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-arm-linux-gnueabihf.tar.gz" ;;
            *) step_err "Arquitetura não suportada para Core: ${GN_HW_ARCH:-?}"; press_enter_or_back; return ;;
        esac
    elif [ "$VARIANT_OPT" = "2" ]; then
        BITCOIN_VERSION="25.1.knots20231115"
        BTC_VARIANT="Knots"
        case "${GN_HW_ARCH:-unknown}" in
            arm64)  URL="https://bitcoinknots.org/files/25.x/${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-aarch64-linux-gnu.tar.gz" ;;
            x86_64) URL="https://bitcoinknots.org/files/25.x/${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz" ;;
            armhf)  URL="https://bitcoinknots.org/files/25.x/${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-arm-linux-gnueabihf.tar.gz" ;;
            *) step_err "Arquitetura não suportada para Knots: ${GN_HW_ARCH:-?}"; press_enter_or_back; return ;;
        esac
    elif [ "$VARIANT_OPT" = "0" ]; then
        return
    else
        step_warn "Opção inválida"
        press_enter_or_back; return
    fi

    step_info "URL de download: $URL"
    echo ""

    if ! confirm "Confirma o download de Bitcoin ${BTC_VARIANT} ${BITCOIN_VERSION}?"; then
        return
    fi

    local TARBALL="/tmp/bitcoin-${BITCOIN_VERSION}.tar.gz"

    step_info "Baixando Bitcoin ${BTC_VARIANT}..."
    wget -q --show-progress -O "$TARBALL" "$URL" || {
        step_err "Falha no download"; press_enter_or_back; return
    }
    step_ok "Download concluído"

    step_info "Extraindo..."
    tar -xzf "$TARBALL" -C /tmp/
    step_ok "Extraído"

    step_info "Instalando binários..."
    local BIN_DIR="/tmp/bitcoin-${BITCOIN_VERSION}/bin"
    install -m 0755 "${BIN_DIR}/bitcoind"   /usr/local/bin/
    install -m 0755 "${BIN_DIR}/bitcoin-cli" /usr/local/bin/
    rm -rf "$TARBALL" "/tmp/bitcoin-${BITCOIN_VERSION}"

    # Cria usuário bitcoin se não existir
    if ! id "$BITCOIN_USER" &>/dev/null; then
        adduser --disabled-password --gecos "" "$BITCOIN_USER"
        step_ok "Usuário '$BITCOIN_USER' criado"
    fi

    mkdir -p "$BITCOIN_DIR"
    chown -R "${BITCOIN_USER}:${BITCOIN_USER}" "$BITCOIN_DIR"

    step_ok "Bitcoin Core ${BITCOIN_VERSION} instalado"
    log_ok "bitcoind ${BITCOIN_VERSION} instalado — arch=${GN_HW_ARCH}"
    press_enter_or_back
}

configurar_bitcoin() {
    banner
    section "⚙  Gerar bitcoin.conf"
    echo ""

    local CONF_FILE="${BITCOIN_DIR}/bitcoin.conf"
    local PRUNE_VAL=0

    # Modo pruned
    if [ "$INSTALL_MODE" = "pruned" ]; then
        PRUNE_VAL=550   # ~550MB mínimo exigido pelo Core
        step_info "Modo Pruned ativo — prune=${PRUNE_VAL}"
    fi

    step_info "Criando: $CONF_FILE"
    mkdir -p "$BITCOIN_DIR"

    cat > "$CONF_FILE" << CONF
# bitcoin.conf — Ghost Node Nation / Satoshi Node
# Gerado em: $(date '+%F %T')
# Modo: ${INSTALL_MODE}

server=1
daemon=1
txindex=$([ "$INSTALL_MODE" = "full" ] && echo "1" || echo "0")
$([ "$PRUNE_VAL" -gt 0 ] && echo "prune=${PRUNE_VAL}" || echo "# prune=0")

# Rede
listen=1
maxconnections=40

# RPC
rpcallowip=127.0.0.1
rpcuser=satoshi
rpcpassword=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32 2>/dev/null || echo "changeme")

# Log
debuglogfile=${SATOSHI_DIR}/logs/bitcoin.log
CONF

    chown "${BITCOIN_USER}:${BITCOIN_USER}" "$CONF_FILE"
    chmod 600 "$CONF_FILE"

    step_ok "Configuração salva em: $CONF_FILE"
    log_ok "bitcoin.conf gerado — modo=${INSTALL_MODE}"
    press_enter_or_back
}

verificar_bitcoin() {
    banner
    section "✔  Status do Bitcoin Node"
    echo ""

    command -v bitcoind &>/dev/null \
        && step_ok "bitcoind: $(bitcoind --version 2>/dev/null | head -1)" \
        || step_err "bitcoind não instalado"

    command -v bitcoin-cli &>/dev/null \
        && step_ok "bitcoin-cli: disponível" \
        || step_err "bitcoin-cli não instalado"

    if bitcoin-cli getblockchaininfo &>/dev/null; then
        step_ok "Node respondendo"
        bitcoin-cli getblockchaininfo 2>/dev/null \
            | while IFS= read -r L; do printf "  ${DIM}%s${RESET}\n" "$L"; done
    else
        step_warn "Node não está rodando ou ainda sincronizando"
    fi

    press_enter_or_back
}

main