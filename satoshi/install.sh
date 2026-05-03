#!/bin/bash
#
# SATOSHI NODE - Bitcoin Core / Knots installer
#

set -euo pipefail

_GN_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_GN_FIND="$_GN_SELF"
while [ ! -d "${_GN_FIND}/halfin/lib" ] && [ "$_GN_FIND" != "/" ]; do
    _GN_FIND="$(dirname "$_GN_FIND")"
done

source "${_GN_FIND}/halfin/lib/init.sh" 2>/dev/null || {
    echo "[ERRO] halfin/lib/init.sh nao encontrado. Execute via nodenation."
    exit 1
}

log_init "satoshi_install"
require_root

GN_USER="${GN_USER:-pleb}"
GN_ROOT="${GN_ROOT:-/home/${GN_USER}/nodenation}"
SATOSHI_DIR="${GN_ROOT}/satoshi"
SATOSHI_LOG_DIR="${SATOSHI_DIR}/logs"
SATOSHI_VAR_DIR="${GN_ROOT}/var"
SATOSHI_ENV_FILE="${SATOSHI_VAR_DIR}/bitcoin-rpc.env"
INSTALL_MODE="${GN_INSTALL_MODE:-standard}"
AUTO_MODE="${GN_AUTO_INSTALL:-false}"
BITCOIN_USER="bitcoin"
BITCOIN_GROUP="${BITCOIN_USER}"
BITCOIN_DIR="/home/${BITCOIN_USER}/.bitcoin"
BITCOIN_CONF="${BITCOIN_DIR}/bitcoin.conf"
BITCOIN_SERVICE="satoshi-bitcoind.service"
BITCOIN_VARIANT="${SATOSHI_VARIANT:-core}"
BITCOIN_VERSION="${SATOSHI_VERSION:-}"
BITCOIN_URL=""
SATOSHI_PRUNE_GB="${SATOSHI_PRUNE_GB:-}"

mkdir -p "$SATOSHI_LOG_DIR" "$SATOSHI_VAR_DIR"

banner() {
    main_banner "  SATOSHI NODE - BITCOIN INSTALL  "
}

download_file() {
    local url="$1"
    local output="$2"

    if command -v wget >/dev/null 2>&1; then
        wget -q --show-progress -O "$output" "$url"
    elif command -v curl >/dev/null 2>&1; then
        curl -fL --progress-bar -o "$output" "$url"
    else
        step_err "wget ou curl nao encontrado"
        return 1
    fi
}

normalize_arch() {
    case "${GN_HW_ARCH:-unknown}" in
        aarch64|arm64) echo "arm64" ;;
        amd64|x86_64)  echo "x86_64" ;;
        armv7l|armv7|armhf) echo "armhf" ;;
        *) echo "${GN_HW_ARCH:-unknown}" ;;
    esac
}

default_version_for_variant() {
    case "${1:-core}" in
        core) echo "29.1" ;;
        knots) echo "29.3.knots20260210" ;;
        *) echo "" ;;
    esac
}

ensure_bitcoin_user() {
    if ! id "$BITCOIN_USER" >/dev/null 2>&1; then
        adduser --disabled-password --gecos "" "$BITCOIN_USER"
        step_ok "Usuario '${BITCOIN_USER}' criado"
    fi
    mkdir -p "$BITCOIN_DIR" "$SATOSHI_LOG_DIR"
    chown -R "${BITCOIN_USER}:${BITCOIN_GROUP}" "$BITCOIN_DIR" "$SATOSHI_LOG_DIR"
}

resolve_release() {
    local ARCH
    ARCH="$(normalize_arch)"

    case "$BITCOIN_VARIANT" in
        core)
            BITCOIN_VERSION="${BITCOIN_VERSION:-$(default_version_for_variant core)}"
            case "$ARCH" in
                arm64)  BITCOIN_URL="https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-aarch64-linux-gnu.tar.gz" ;;
                x86_64) BITCOIN_URL="https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz" ;;
                armhf)  BITCOIN_URL="https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-arm-linux-gnueabihf.tar.gz" ;;
                *) step_err "Arquitetura nao suportada para Bitcoin Core: ${GN_HW_ARCH:-?}"; return 1 ;;
            esac
            ;;
        knots)
            BITCOIN_VERSION="${BITCOIN_VERSION:-$(default_version_for_variant knots)}"
            case "$ARCH" in
                arm64)  BITCOIN_URL="https://bitcoinknots.org/files/29.x/${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-aarch64-linux-gnu.tar.gz" ;;
                x86_64) BITCOIN_URL="https://bitcoinknots.org/files/29.x/${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz" ;;
                armhf)  BITCOIN_URL="https://bitcoinknots.org/files/29.x/${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-arm-linux-gnueabihf.tar.gz" ;;
                *) step_err "Arquitetura nao suportada para Bitcoin Knots: ${GN_HW_ARCH:-?}"; return 1 ;;
            esac
            ;;
        *)
            step_err "Implementacao invalida: ${BITCOIN_VARIANT}"
            return 1
            ;;
    esac
}

choose_variant() {
    if [ -n "${SATOSHI_VARIANT:-}" ]; then
        BITCOIN_VARIANT="$SATOSHI_VARIANT"
        return 0
    fi

    if [ "$AUTO_MODE" = "true" ]; then
        return 0
    fi

    echo ""
    printf "  ${BOLD}Qual implementacao deseja instalar?${RESET}\n"
    printf "  ${CYAN}[1]${RESET} Bitcoin Core\n"
    printf "  ${CYAN}[2]${RESET} Bitcoin Knots\n"
    printf "  ${BOLD}[0]${RESET} Voltar  ${BOLD}[q]${RESET} Sair\n"
    printf "\n  ${BOLD}Opcao:${RESET} "
    read -r variant_opt

    case "$variant_opt" in
        1) BITCOIN_VARIANT="core" ;;
        2) BITCOIN_VARIANT="knots" ;;
        0|"") return 1 ;;
        q|Q) exit 0 ;;
        *) step_warn "Opcao invalida"; return 1 ;;
    esac

    return 0
}

choose_version() {
    local default_version version_input

    default_version="$(default_version_for_variant "$BITCOIN_VARIANT")"

    if [ -n "${SATOSHI_VERSION:-}" ]; then
        BITCOIN_VERSION="$SATOSHI_VERSION"
        return 0
    fi

    BITCOIN_VERSION="${BITCOIN_VERSION:-$default_version}"

    if [ "$AUTO_MODE" = "true" ]; then
        return 0
    fi

    echo ""
    printf "  ${DIM}Versao padrao para %s:${RESET} ${BOLD}%s${RESET}\n" "$BITCOIN_VARIANT" "$default_version"
    printf "  Digite a versao desejada ou pressione ENTER para usar a padrao: "
    read -r version_input
    BITCOIN_VERSION="${version_input:-$default_version}"
}

choose_storage_mode() {
    local disk_gb="${GN_HW_DISK_GB:-0}"
    local prune_opt custom_prune

    if [ -n "${GN_INSTALL_MODE:-}" ] && [ "${GN_INSTALL_MODE}" != "standard" ]; then
        INSTALL_MODE="$GN_INSTALL_MODE"
    fi

    if [ "$INSTALL_MODE" = "pruned" ] && [ -z "$SATOSHI_PRUNE_GB" ]; then
        SATOSHI_PRUNE_GB="30"
    fi

    if [ "$AUTO_MODE" = "true" ]; then
        if [ "$INSTALL_MODE" = "standard" ]; then
            if [ "${GN_HW_DISK_GB:-0}" -ge 1024 ] 2>/dev/null; then
                INSTALL_MODE="full"
            else
                INSTALL_MODE="pruned"
                SATOSHI_PRUNE_GB="${SATOSHI_PRUNE_GB:-30}"
            fi
        fi
        return 0
    fi

    while true; do
        echo ""
        printf "  ${BOLD}Qual modo deseja usar?${RESET}\n"
        printf "  ${CYAN}[1]${RESET} Full Node\n"
        if [ "$disk_gb" -lt 1024 ] 2>/dev/null; then
            printf "      ${YELLOW}Aviso:${RESET} menos de 1TB livre detectado\n"
        fi
        printf "  ${CYAN}[2]${RESET} Pruned Node\n"
        printf "  ${BOLD}[0]${RESET} Voltar  ${BOLD}[q]${RESET} Sair\n"
        printf "\n  ${BOLD}Opcao:${RESET} "
        read -r prune_opt

        case "$prune_opt" in
            1)
                INSTALL_MODE="full"
                if [ "$disk_gb" -lt 1024 ] 2>/dev/null; then
                    confirm "Menos de 1TB livre. Continuar mesmo assim com Full Node?" "n" || continue
                fi
                SATOSHI_PRUNE_GB=""
                return 0
                ;;
            2)
                INSTALL_MODE="pruned"
                echo ""
                printf "  ${BOLD}Tamanho do prune:${RESET}\n"
                printf "  ${CYAN}[1]${RESET} 10 GB\n"
                printf "  ${CYAN}[2]${RESET} 30 GB\n"
                printf "  ${CYAN}[3]${RESET} Escolher manualmente\n"
                printf "\n  ${BOLD}Opcao:${RESET} "
                read -r prune_opt
                case "$prune_opt" in
                    1) SATOSHI_PRUNE_GB="10"; return 0 ;;
                    2) SATOSHI_PRUNE_GB="30"; return 0 ;;
                    3)
                        printf "  Espaço maximo do pruned em GB (minimo 10): "
                        read -r custom_prune
                        if ! [[ "$custom_prune" =~ ^[0-9]+$ ]] || [ "$custom_prune" -lt 10 ]; then
                            step_warn "Valor invalido para prune"
                            continue
                        fi
                        SATOSHI_PRUNE_GB="$custom_prune"
                        return 0
                        ;;
                    *) step_warn "Opcao invalida" ;;
                esac
                ;;
            0|"") return 1 ;;
            q|Q) exit 0 ;;
            *) step_warn "Opcao invalida" ;;
        esac
    done
}

write_rpc_env() {
    mkdir -p "$SATOSHI_VAR_DIR"
    cat > "$SATOSHI_ENV_FILE" <<EOF
BITCOIN_RPC_URL=http://127.0.0.1:8332
BITCOIN_RPC_USER=${BITCOIN_RPC_USER}
BITCOIN_RPC_PASS=${BITCOIN_RPC_PASS}
BITCOIN_RPC_HOST=127.0.0.1
BITCOIN_RPC_PORT=8332
EOF
    chmod 600 "$SATOSHI_ENV_FILE"
}

create_systemd_service() {
    step_info "Registrando servico systemd: ${BITCOIN_SERVICE}"
    cat > "/etc/systemd/system/${BITCOIN_SERVICE}" <<EOF
[Unit]
Description=Satoshi Node Bitcoin daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${BITCOIN_USER}
Group=${BITCOIN_GROUP}
ExecStart=/usr/local/bin/bitcoind -conf=${BITCOIN_CONF} -datadir=${BITCOIN_DIR}
ExecStop=/usr/local/bin/bitcoin-cli -conf=${BITCOIN_CONF} stop
Restart=on-failure
RestartSec=10
RuntimeDirectory=bitcoind
StateDirectory=bitcoind

[Install]
WantedBy=multi-user.target
EOF
    if command -v systemctl >/dev/null 2>&1; then
        systemctl daemon-reload
        systemctl enable "${BITCOIN_SERVICE}" >/dev/null 2>&1
    else
        step_warn "systemctl indisponivel - pulando enable do servico"
    fi
}

instalar_bitcoind() {
    banner
    section "Download do Node Bitcoin"
    echo ""

    choose_variant || return 0
    choose_version || return 0
    choose_storage_mode || return 0
    resolve_release || { press_enter_or_back; return; }

    step_info "Arquitetura: ${GN_HW_ARCH:-desconhecida}"
    step_info "Implementacao: ${BITCOIN_VARIANT}"
    step_info "Versao: ${BITCOIN_VERSION}"
    step_info "Modo: ${INSTALL_MODE}"
    if [ "$INSTALL_MODE" = "pruned" ]; then
        step_info "Prune: ${SATOSHI_PRUNE_GB:-30} GB"
    fi
    step_info "URL: ${BITCOIN_URL}"

    if [ "$AUTO_MODE" != "true" ] && ! confirm "Confirma o download?"; then
        return
    fi

    local tarball="/tmp/bitcoin-${BITCOIN_VERSION}.tar.gz"
    local extract_dir="/tmp/bitcoin-${BITCOIN_VERSION}"
    rm -rf "$extract_dir" "$tarball"

    step_info "Baixando binarios..."
    download_file "$BITCOIN_URL" "$tarball"

    step_info "Extraindo..."
    mkdir -p "$extract_dir"
    tar -xzf "$tarball" -C "$extract_dir"

    local top_dir
    top_dir="$(tar -tzf "$tarball" | head -1 | cut -d/ -f1)"
    local bin_dir="${extract_dir}/${top_dir}/bin"

    if [ ! -d "$bin_dir" ]; then
        step_err "Diretorio de binarios nao encontrado em ${bin_dir}"
        press_enter_or_back
        return
    fi

    step_info "Instalando binarios em /usr/local/bin..."
    install -m 0755 "${bin_dir}/bitcoind" /usr/local/bin/
    install -m 0755 "${bin_dir}/bitcoin-cli" /usr/local/bin/
    install -m 0755 "${bin_dir}/bitcoin-tx" /usr/local/bin/ 2>/dev/null || true
    rm -rf "$extract_dir" "$tarball"

    ensure_bitcoin_user
    step_ok "Binarios ${BITCOIN_VARIANT} ${BITCOIN_VERSION} instalados"
    log_ok "bitcoin instalado: ${BITCOIN_VARIANT} ${BITCOIN_VERSION}"

    if [ "$AUTO_MODE" != "true" ]; then
        press_enter_or_back
    fi
}

configurar_bitcoin() {
    banner
    section "Configuracao do bitcoin.conf"
    echo ""

    ensure_bitcoin_user

    local prune_val=0
    local prune_gb=0
    case "$INSTALL_MODE" in
        pruned)
            prune_gb="${SATOSHI_PRUNE_GB:-30}"
            prune_val=$(( prune_gb * 1024 ))
            ;;
        full) prune_val=0 ;;
        *) prune_val=0 ;;
    esac

    if [ -f "$SATOSHI_ENV_FILE" ]; then
        source "$SATOSHI_ENV_FILE"
    fi

    BITCOIN_RPC_USER="${BITCOIN_RPC_USER:-satoshi}"
    BITCOIN_RPC_PASS="${BITCOIN_RPC_PASS:-$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)}"

    mkdir -p "$BITCOIN_DIR" "$SATOSHI_LOG_DIR"

    cat > "$BITCOIN_CONF" <<EOF
# bitcoin.conf - GhostNodes / Satoshi Node
# Gerado em: $(date '+%F %T')
server=1
daemon=0
txindex=$([ "$INSTALL_MODE" = "full" ] && echo "1" || echo "0")
$( [ "$prune_val" -gt 0 ] && echo "prune=${prune_val}" || echo "# prune=0" )

listen=1
rpcbind=127.0.0.1
rpcallowip=127.0.0.1
rpcallowip=172.17.0.0/16
rpcuser=${BITCOIN_RPC_USER}
rpcpassword=${BITCOIN_RPC_PASS}

debuglogfile=${SATOSHI_LOG_DIR}/bitcoin.log
maxconnections=40
EOF

    chown "${BITCOIN_USER}:${BITCOIN_GROUP}" "$BITCOIN_CONF"
    chmod 600 "$BITCOIN_CONF"

    write_rpc_env
    create_systemd_service

    step_info "Iniciando ${BITCOIN_SERVICE}..."
    if command -v systemctl >/dev/null 2>&1; then
        systemctl restart "${BITCOIN_SERVICE}"
    else
        step_warn "systemctl indisponivel - servico nao foi reiniciado automaticamente"
    fi
    step_ok "bitcoin.conf salvo e servico iniciado"
    log_ok "bitcoin.conf gerado - modo=${INSTALL_MODE}"

    if [ "$AUTO_MODE" != "true" ]; then
        press_enter_or_back
    fi
}

verificar_bitcoin() {
    banner
    section "Status do Bitcoin Node"
    echo ""

    if command -v bitcoind >/dev/null 2>&1; then
        step_ok "bitcoind instalado"
    else
        step_err "bitcoind nao instalado"
    fi

    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active "${BITCOIN_SERVICE}" >/dev/null 2>&1; then
            step_ok "Servico ${BITCOIN_SERVICE} ativo"
        else
            step_warn "Servico ${BITCOIN_SERVICE} inativo"
        fi
    else
        step_warn "systemctl indisponivel - status do servico nao verificado"
    fi

    if bitcoin-cli -conf="${BITCOIN_CONF}" getblockchaininfo >/dev/null 2>&1; then
        step_ok "RPC respondendo"
        bitcoin-cli -conf="${BITCOIN_CONF}" getblockchaininfo \
            | while IFS= read -r line; do printf "  ${DIM}%s${RESET}\n" "$line"; done
    else
        step_warn "RPC ainda nao responde - confira sincronizacao/logs"
    fi

    if [ "$AUTO_MODE" != "true" ]; then
        press_enter_or_back
    fi
}

run_auto_install() {
    instalar_bitcoind
    configurar_bitcoin
    verificar_bitcoin
}

main() {
    banner

    echo ""
    case "$INSTALL_MODE" in
        full)
            step_ok "Modo detectado: Full Node"
            ;;
        pruned)
            step_warn "Modo detectado: Pruned Node"
            ;;
        *)
            step_info "Modo detectado: standard"
            ;;
    esac

    if [ "$AUTO_MODE" = "true" ]; then
        run_auto_install
        return
    fi

    while true; do
        echo ""
        printf "  ${BOLD}${CYAN}[1]${RESET}  Instalar Bitcoin Core / Knots\n"
        printf "  ${BOLD}${CYAN}[2]${RESET}  Configurar bitcoin.conf e systemd\n"
        printf "  ${BOLD}${CYAN}[3]${RESET}  Verificar status do node\n"
        printf "  ${BOLD}[0]${RESET}  Voltar  ${BOLD}[q]${RESET}  Sair\n"
        echo ""
        printf "  ${BOLD}Opcao:${RESET} "
        read -r opt
        case "$opt" in
            1) instalar_bitcoind ;;
            2) configurar_bitcoin ;;
            3) verificar_bitcoin ;;
            0|"") return ;;
            q|Q) exit 0 ;;
            *) step_warn "Opcao invalida" ;;
        esac
    done
}

main
