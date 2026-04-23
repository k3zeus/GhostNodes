#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  halfin/pre_install.sh — Pré-Instalação Completa             ║
# ║  Hardware: OrangePi Zero 3 — Debian Bookworm arm64           ║
# ║  Ghost Nodes - NodeNation  v0.14                             ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Ordem de execução:
#   1.  Usuário pleb
#   2.  Sources.list Debian oficial
#   3.  Remove Docker conflitante
#   4.  Hostname
#   5.  Atualização do sistema
#   6.  Instalação de ferramentas
#   7.  Alias Wi-Fi (wlx → wlan1)
#   8.  Bridge + hostapd (integrado do script_orange3.sh)
#   9.  Scripts extras: fail2ban, pi-hole, docker, routing
#   10. Aliases do shell
#   11. Remoção do usuário legado (orangepi) ← PENÚLTIMO
#   12. Propriedade dos arquivos ← ÚLTIMO
#

# ── Biblioteca modular ────────────────────────────────────────────────────────
_GN_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_GN_FIND="$_GN_SELF"
while [ ! -d "${_GN_FIND}/lib" ] && [ "$_GN_FIND" != "/" ]; do
    _GN_FIND="$(dirname "$_GN_FIND")"
done
if [ -f "${_GN_FIND}/halfin/lib/init.sh" ]; then
    source "${_GN_FIND}/halfin/lib/init.sh"
elif [ -f "${_GN_FIND}/lib/init.sh" ]; then
    source "${_GN_FIND}/lib/init.sh"
else
    # UI mínima inline — permite rodar sem a lib instalada ainda
    BOLD="\e[1m"; RESET="\e[0m"; DIM="\e[2m"
    GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"
    CYAN="\e[36m"; MAGENTA="\e[35m"; WHITE="\e[97m"
    CHECK="${GREEN}✔${RESET}"; CROSS="${RED}✘${RESET}"
    WARN="${YELLOW}⚠${RESET}"; ARROW="${CYAN}▶${RESET}"
    BULLET="${DIM}•${RESET}"
    sep()       { printf "${DIM}  ──────────────────────────────────────────────────────────────${RESET}\n"; }
    sep_thin()  { printf "${DIM}  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${RESET}\n"; }
    section()   { echo ""; printf "${BOLD}${MAGENTA}  ┌─ %s${RESET}\n" "$1"; sep_thin; }
    step_ok()   { printf "  ${CHECK} ${WHITE}%s${RESET}\n" "$1"; }
    step_warn() { printf "  ${WARN}  ${YELLOW}%s${RESET}\n" "$1"; }
    step_err()  { printf "  ${CROSS} ${RED}%s${RESET}\n" "$1"; }
    step_info() { printf "  ${ARROW} ${DIM}%s${RESET}\n" "$1"; }
    press_enter(){ echo ""; printf "  ${DIM}[ ENTER para continuar ]${RESET}"; read -r; }
    confirm()   { printf "\n  ${YELLOW}?${RESET} %s [S/n]: " "$1"; read -r R; R="${R:-s}"; [[ "$R" =~ ^[sS]$ ]]; }
fi

# ── Verificação de root ───────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    printf "\n  ${RED}[ERRO]${RESET} Execute como root: ${BOLD}sudo bash %s${RESET}\n\n" "$0"
    exit 1
fi

# ── Variáveis do projeto (com fallback) ───────────────────────────────────────
GN_USER="${GN_USER:-pleb}"
GN_ROOT="${GN_ROOT:-/home/${GN_USER}/nodenation}"
HALFIN_DIR="${HALFIN_DIR:-${GN_ROOT}/halfin}"
GN_DEFAULT_PASSWORD="${GN_DEFAULT_PASSWORD:-Mudar123}"
GN_HOSTNAME="${GN_HOSTNAME:-halfin}"
GN_LEGACY_USER="${GN_LEGACY_USER:-orangepi}"
PLEB_HOME="/home/${GN_USER}"

# ── Variáveis de rede (OrangePi Zero 3) ──────────────────────────────────────
SSID="${HALFIN_SSID:-Halfin}"
WPA2_PASS="${HALFIN_WPA_PASS:-Mudar102030}"
AP_IFACE="${HALFIN_AP_IFACE:-wlan0}"
BRIDGE_IFACE="${HALFIN_BRIDGE:-br0}"
BRIDGE_IP="${HALFIN_BRIDGE_IP:-10.21.21.1}"
NETMASK="${HALFIN_NETMASK:-255.255.255.0}"
DHCP_START="${HALFIN_DHCP_START:-10.21.21.100}"
DHCP_END="${HALFIN_DHCP_END:-10.21.21.105}"
WAN_CANDIDATAS="${HALFIN_WAN:-end0 wlan1}"   # lista separada por espaço
HOSTAPD_CONF="/etc/hostapd/hostapd.conf"
INTERFACES_FILE="/etc/network/interfaces"
DNSMASQ_CONF="/etc/dnsmasq.conf"

# ── Estado de instalação (permite retomar) ────────────────────────────────────
PRE_STATE="${GN_ROOT}/var/preinstall_halfin.state"
if mkdir -p "${GN_ROOT}/var" 2>/dev/null; then
    :
else
    mkdir -p "/tmp/gn_var"
    PRE_STATE="/tmp/gn_preinstall.state"
fi
touch "$PRE_STATE" 2>/dev/null || true

_state_get() { grep -m1 "^${1}=" "$PRE_STATE" 2>/dev/null | cut -d= -f2 || echo "0"; }
_state_set() {
    grep -q "^${1}=" "$PRE_STATE" 2>/dev/null \
        && sed -i "s/^${1}=.*/${1}=${2}/" "$PRE_STATE" \
        || echo "${1}=${2}" >> "$PRE_STATE"
}

# ── Executa script externo com fallback ──────────────────────────────────────
_run_extra() {
    local SCRIPT="$1"
    local DESC="$2"
    section "▶  Extra — ${DESC}"
    echo ""
    if [ ! -f "$SCRIPT" ]; then
        step_warn "Script não encontrado: $SCRIPT — pulando"
        return 0
    fi
    chmod +x "$SCRIPT"
    bash "$SCRIPT" && step_ok "${DESC} concluído" \
        || step_warn "${DESC} retornou erro — verifique logs"
}

# ══════════════════════════════════════════════════════════════════════════════
# ETAPA 1 — Usuário pleb
# ══════════════════════════════════════════════════════════════════════════════
etapa_usuario() {
    section "👤  Etapa 1 — Usuário ${GN_USER}"
    echo ""
    if id "$GN_USER" &>/dev/null; then
        step_ok "Usuário '${GN_USER}' já existe"
    else
        step_info "Criando usuário '${GN_USER}'..."
        adduser --disabled-password --gecos "" "$GN_USER"
        echo "${GN_USER}:${GN_DEFAULT_PASSWORD}" | chpasswd
        usermod -aG sudo "$GN_USER"
        step_ok "Usuário '${GN_USER}' criado"
        step_warn "Senha padrão: ${BOLD}${GN_DEFAULT_PASSWORD}${RESET} — ${RED}altere após o login!${RESET}"
    fi
    mkdir -p "$PLEB_HOME"
    chown "${GN_USER}:${GN_USER}" "$PLEB_HOME"
    _state_set "etapa_usuario" "1"
}

# ══════════════════════════════════════════════════════════════════════════════
# ETAPA 2 — Sources.list
# ══════════════════════════════════════════════════════════════════════════════
etapa_sourcelist() {
    section "📦  Etapa 2 — Sources.list Debian Bookworm"
    echo ""
    if grep -q "deb.debian.org/debian bookworm" /etc/apt/sources.list 2>/dev/null \
       && ! grep -qiE "ubuntu|armbian|orangepi-repo" /etc/apt/sources.list 2>/dev/null; then
        step_ok "sources.list já configurado com repositórios Debian oficiais"
        _state_set "etapa_sourcelist" "1"; return
    fi
    cp /etc/apt/sources.list "/etc/apt/sources.list.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
    tee /etc/apt/sources.list > /dev/null << 'SOURCES'
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
#deb-src http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware

deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
#deb-src http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware

deb http://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware
#deb-src http://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
#deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
SOURCES
    [ -f /etc/apt/sources.list.d/docker.list ] && \
        rm -f /etc/apt/sources.list.d/docker.list && step_ok "docker.list removido"
    step_ok "sources.list atualizado"
    _state_set "etapa_sourcelist" "1"
}

# ══════════════════════════════════════════════════════════════════════════════
# ETAPA 3 — Remove Docker conflitante
# ══════════════════════════════════════════════════════════════════════════════
etapa_remove_docker() {
    section "🐋  Etapa 3 — Remoção de Pacotes Docker Conflitantes"
    echo ""
    local FOUND=""
    for PKG in docker.io docker-doc docker-compose podman-docker containerd runc; do
        dpkg -l "$PKG" 2>/dev/null | grep -q "^ii" && FOUND="$FOUND $PKG" || true
    done
    if [ -z "$FOUND" ]; then
        step_ok "Nenhum pacote conflitante instalado"
    else
        step_warn "Removendo:${YELLOW}${FOUND}${RESET}"
        set +e; DEBIAN_FRONTEND=noninteractive apt-get remove -y $FOUND 2>/dev/null; set -e
        step_ok "Pacotes removidos"
    fi
    _state_set "etapa_remove_docker" "1"
}

# ══════════════════════════════════════════════════════════════════════════════
# ETAPA 4 — Hostname
# ══════════════════════════════════════════════════════════════════════════════
etapa_hostname() {
    section "🏷   Etapa 4 — Hostname"
    echo ""
    local CURRENT; CURRENT=$(hostname 2>/dev/null || echo "")
    if [ "$CURRENT" = "$GN_HOSTNAME" ]; then
        step_ok "Hostname já configurado: ${BOLD}${GN_HOSTNAME}${RESET}"
    else
        echo "$GN_HOSTNAME" > /etc/hostname
        hostname "$GN_HOSTNAME"
        if grep -q "127.0.1.1" /etc/hosts; then
            sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t${GN_HOSTNAME}/" /etc/hosts
        else
            echo "127.0.1.1	${GN_HOSTNAME}" >> /etc/hosts
        fi
        step_ok "Hostname: '${CURRENT}' → '${GN_HOSTNAME}'"
    fi
    _state_set "etapa_hostname" "1"
}

# ══════════════════════════════════════════════════════════════════════════════
# ETAPA 5 — Atualização
# ══════════════════════════════════════════════════════════════════════════════
etapa_update() {
    section "🔄  Etapa 5 — Atualização do Sistema"
    echo ""
    set +e
    step_info "apt-get update..."
    DEBIAN_FRONTEND=noninteractive apt-get update -q 2>&1 \
        | while IFS= read -r L; do printf "  ${DIM}%s${RESET}\n" "$L"; done
    step_info "apt-get upgrade..."
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y 2>&1 \
        | while IFS= read -r L; do
            echo "$L" | grep -qiE "^E:|error|fatal" \
                && printf "  ${RED}%s${RESET}\n" "$L" \
                || printf "  ${DIM}%s${RESET}\n" "$L"
          done
    set -e
    step_ok "Sistema atualizado"
    _state_set "etapa_update" "1"
}

# ══════════════════════════════════════════════════════════════════════════════
# ETAPA 6 — Ferramentas
# ══════════════════════════════════════════════════════════════════════════════
etapa_ferramentas() {
    section "🛠   Etapa 6 — Instalação de Ferramentas"
    echo ""
    local PKGS="git htop vim net-tools nmap tree lm-sensors dos2unix \
                openssh-server iptraf-ng hostapd iptables iw traceroute \
                bridge-utils iptables-persistent btop sqlite3 dnsmasq \
                ca-certificates curl gnupg lsb-release"
    local MISSING="" PKG_OK=0 PKG_FAIL=0 PKG_FAIL_LIST=""
    for PKG in $PKGS; do
        dpkg -l "$PKG" 2>/dev/null | grep -q "^ii" || MISSING="$MISSING $PKG"
    done
    if [ -z "$MISSING" ]; then
        step_ok "Todos os pacotes já instalados"
        _state_set "etapa_ferramentas" "1"; return
    fi
    step_info "Instalando:${YELLOW}${MISSING}${RESET}"; echo ""
    for PKG in $MISSING; do
        set +e
        DEBIAN_FRONTEND=noninteractive apt-get install -y "$PKG" -q 2>&1 \
            | tail -2 | while IFS= read -r L; do printf "    ${DIM}%s${RESET}\n" "$L"; done
        RC=${PIPESTATUS[0]}; set -e
        if [ "$RC" -eq 0 ]; then
            step_ok "$PKG"; PKG_OK=$((PKG_OK+1))
        else
            step_warn "$PKG falhou (RC=$RC)"
            PKG_FAIL=$((PKG_FAIL+1)); PKG_FAIL_LIST="$PKG_FAIL_LIST $PKG"
            dpkg --configure -a 2>/dev/null || true
        fi
    done
    echo ""; sep
    step_ok "Instalados com sucesso: ${PKG_OK}"
    [ "$PKG_FAIL" -gt 0 ] && step_warn "Falhas: ${PKG_FAIL} —${PKG_FAIL_LIST}"
    _state_set "etapa_ferramentas" "1"
}

# ══════════════════════════════════════════════════════════════════════════════
# ETAPA 7 — Alias Wi-Fi (wlx → wlan1)
# ══════════════════════════════════════════════════════════════════════════════
etapa_alias_wifi() {
    section "📡  Etapa 7 — Interface Wi-Fi (alias wlx → wlan1)"
    echo ""

    # Verifica alias.sh do projeto primeiro
    local ALIAS_SH="${HALFIN_DIR}/tools/alias.sh"
    if [ -f "$ALIAS_SH" ]; then
        step_info "Usando tools/alias.sh do projeto..."
        bash "$ALIAS_SH"
        _state_set "etapa_alias" "1"; return
    fi

    # Fallback inline — detecta wlan0 + wlx*
    local TEM_WLAN0=0 IFACE_WLX=""
    while IFS= read -r IFACE; do
        [ "$IFACE" = "wlan0" ] && TEM_WLAN0=1
        [[ "$IFACE" == wlx* ]] && IFACE_WLX="$IFACE"
    done < <(iw dev 2>/dev/null | awk '$1=="Interface"{print $2}')

    if [ "$TEM_WLAN0" -eq 0 ] || [ -z "$IFACE_WLX" ]; then
        step_info "Condição wlan0 + wlx não atendida — nenhuma renomeação necessária"
        _state_set "etapa_alias" "1"; return
    fi

    step_warn "Detectado: wlan0 (interna) + ${IFACE_WLX} (externa USB)"
    step_info "Criando regra udev: ${IFACE_WLX} → wlan1"

    local MAC; MAC=$(cat "/sys/class/net/${IFACE_WLX}/address" 2>/dev/null || echo "")
    if [ -z "$MAC" ]; then
        step_err "Não foi possível ler MAC de ${IFACE_WLX}"; return
    fi

    tee /etc/udev/rules.d/70-halfin-wlan1.rules > /dev/null << UDEV
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="${MAC}", NAME="wlan1"
UDEV
    udevadm control --reload 2>/dev/null || true
    udevadm trigger --subsystem-match=net 2>/dev/null || true
    step_ok "${IFACE_WLX} (${MAC}) → wlan1 após reboot"
    _state_set "etapa_alias" "1"
}

# ══════════════════════════════════════════════════════════════════════════════
# ETAPA 8 — Bridge + hostapd (lógica do script_orange3.sh integrada)
# ══════════════════════════════════════════════════════════════════════════════

# 8.1 Detecta interface WAN
_detectar_wan() {
    step_info "Detectando interface WAN..."
    WAN_IFACE=""
    for iface in $WAN_CANDIDATAS; do
        if ip link show "$iface" 2>/dev/null | grep -q "state UP"; then
            WAN_IFACE="$iface"
            step_ok "Interface WAN detectada: ${BOLD}${WAN_IFACE}${RESET}"
            return 0
        fi
    done
    # Fallback: usa rota padrão
    WAN_IFACE=$(ip route 2>/dev/null | awk '/^default/{print $5; exit}')
    if [ -n "$WAN_IFACE" ]; then
        step_warn "Nenhuma interface UP encontrada — usando rota padrão: ${WAN_IFACE}"
        return 0
    fi
    step_err "Nenhuma interface WAN encontrada. Defina HALFIN_WAN no globals.env"
    return 1
}

# 8.2 Configura /etc/network/interfaces com bridge
_configurar_bridge() {
    step_info "Configurando bridge ${BRIDGE_IFACE}..."

    # Backup do arquivo atual
    local BKP="/etc/network/interfaces.bkp.$(date +%Y%m%d%H%M%S)"
    cp "$INTERFACES_FILE" "$BKP" 2>/dev/null && step_ok "Backup: $BKP" || true

    tee "$INTERFACES_FILE" > /dev/null << NETCFG
# /etc/network/interfaces — Halfin Node — gerado em $(date '+%F %T')
# Ghost Nodes - NodeNation

# Loopback
auto lo
iface lo inet loopback

# Interface Ethernet (WAN — internet)
allow-hotplug ${WAN_IFACE:-end0}
iface ${WAN_IFACE:-end0} inet dhcp

# Interface WiFi AP (não recebe IP diretamente — gerenciada pelo bridge)
allow-hotplug ${AP_IFACE}
iface ${AP_IFACE} inet manual

# Bridge — agrupa wlan0 e distribui rede local
auto ${BRIDGE_IFACE}
iface ${BRIDGE_IFACE} inet static
    address ${BRIDGE_IP}
    netmask ${NETMASK}
    bridge_ports ${AP_IFACE}
    bridge_stp off
    bridge_fd 0
    bridge_maxwait 0
NETCFG

    step_ok "/etc/network/interfaces configurado (bridge ${BRIDGE_IFACE})"
}

# 8.3 Configura dnsmasq (DHCP da rede local)
_configurar_dnsmasq() {
    step_info "Configurando dnsmasq (DHCP ${DHCP_START}–${DHCP_END})..."

    [ -f "$DNSMASQ_CONF" ] && \
        cp "$DNSMASQ_CONF" "${DNSMASQ_CONF}.bkp.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true

    tee "$DNSMASQ_CONF" > /dev/null << DNSMASQ
# dnsmasq — Halfin Node DHCP — gerado em $(date '+%F %T')
interface=${BRIDGE_IFACE}
bind-interfaces
dhcp-range=${DHCP_START},${DHCP_END},24h
dhcp-option=3,${BRIDGE_IP}
dhcp-option=6,${BRIDGE_IP}
server=8.8.8.8
server=8.8.4.4
log-queries
log-dhcp
DNSMASQ

    systemctl enable dnsmasq 2>/dev/null || true
    systemctl restart dnsmasq 2>/dev/null || \
        step_warn "dnsmasq não pôde ser reiniciado — verifique após reboot"
    step_ok "dnsmasq configurado"
}

# 8.4 Configura hostapd (Access Point Wi-Fi)
_configurar_hostapd() {
    step_info "Configurando hostapd (SSID: ${SSID})..."

    mkdir -p /etc/hostapd

    tee "$HOSTAPD_CONF" > /dev/null << HOSTAPD
# hostapd.conf — Halfin Node — gerado em $(date '+%F %T')
# Ghost Nodes - NodeNation

interface=${AP_IFACE}
driver=nl80211
bridge=${BRIDGE_IFACE}

### SSID e Autenticação ###
ssid=${SSID}
country_code=BR

### Frequência: use hw_mode=g para 2.4GHz, hw_mode=a para 5GHz ###
hw_mode=a
channel=36

### Segurança WPA2 ###
auth_algs=1
wpa=2
wpa_passphrase=${WPA2_PASS}
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
rsn_pairwise=CCMP

### 802.11ac (Wi-Fi 5 — 5GHz) ###
ieee80211ac=1
ieee80211d=1
ieee80211h=1
wmm_enabled=1

### Canal 80MHz (ajuste conforme hardware) ###
ht_capab=[HT40+][SHORT-GI-40][DSSS_CCK-40][MAX-AMSDU-7935]
vht_oper_chwidth=1
vht_oper_centr_freq_seg0_idx=42

### Geral ###
macaddr_acl=0
ignore_broadcast_ssid=0
HOSTAPD

    # Aponta /etc/default/hostapd para o conf
    sed -i 's|#\?DAEMON_CONF=.*|DAEMON_CONF="'"$HOSTAPD_CONF"'"|' /etc/default/hostapd 2>/dev/null || true

    systemctl unmask hostapd 2>/dev/null || true
    systemctl enable hostapd
    systemctl restart hostapd 2>/dev/null || \
        step_warn "hostapd não iniciou — verifique o hardware Wi-Fi e o canal configurado"
    step_ok "hostapd configurado (${SSID} / 5GHz canal 36)"
}

etapa_orange3() {
    section "🍊  Etapa 8 — Bridge + Wi-Fi AP (OrangePi Zero 3)"
    echo ""

    _detectar_wan || { step_err "WAN não encontrada — pulando configuração de rede"; return 1; }
    _configurar_bridge
    _configurar_dnsmasq
    _configurar_hostapd

    step_ok "Configuração de rede concluída"
    _state_set "etapa_orange3" "1"
}

# ══════════════════════════════════════════════════════════════════════════════
# ETAPA 9 — Scripts extras
# ══════════════════════════════════════════════════════════════════════════════
etapa_extras() {
    section "🔗  Etapa 9 — Scripts Extras"
    echo ""
    _run_extra "${HALFIN_DIR}/extras/fail2ban.sh"  "Fail2ban"
    echo ""
    _run_extra "${HALFIN_DIR}/extras/pi-hole.sh"   "Pi-hole + Unbound"
    echo ""
    _run_extra "${HALFIN_DIR}/docker/docker.sh"    "Docker + Portainer"
    echo ""
    _run_extra "${HALFIN_DIR}/routing.sh"          "Routing / iptables"

    _state_set "etapa_extras" "1"
}

# ══════════════════════════════════════════════════════════════════════════════
# STEP 9.1 — GhostNodes Sovereign Dashboard
# ══════════════════════════════════════════════════════════════════════════════
etapa_dashboard() {
    section "🌐  Step 9.1 — Sovereign Dashboard"
    echo ""
    _run_extra "${HALFIN_DIR}/extras/webapp.sh" "Dashboard UI + API"
    _state_set "etapa_dashboard" "1"
}

# ══════════════════════════════════════════════════════════════════════════════
# ETAPA 10 — Aliases do shell
# ══════════════════════════════════════════════════════════════════════════════
etapa_aliases() {
    section "⌨   Etapa 10 — Aliases do Shell"
    echo ""

    local ALIASES_FILE="${PLEB_HOME}/.bash_aliases"

    # Evita duplicar aliases se já existirem
    if grep -q "alias ls=" "$ALIASES_FILE" 2>/dev/null; then
        step_ok "Aliases já configurados em ${ALIASES_FILE}"
        _state_set "etapa_aliases" "1"; return
    fi

    tee -a "$ALIASES_FILE" > /dev/null << 'ALIASES'

# ── Halfin Node Aliases — Ghost Nodes NodeNation ─────────────────────────────
# ls colorido
alias ls="ls -la --color"
# IP detalhado
alias ip="ip -c -br -a"
# Update simples
alias update="sudo apt update && sudo apt upgrade"
# Verificar portas
alias ports="sudo netstat -tulanp"
# Tamanho de arquivos
alias filesize="du -sh * | sort -h"
# Busca no histórico
alias gh="history|grep"
# cd para cima
alias ..="cd .."
# Limpar tela
alias c="clear"
# VIM
alias vi="vim"
# Sudo root
alias root="sudo -i"
# ghostnode
alias gn="ghostnode"
# ─────────────────────────────────────────────────────────────────────────────
ALIASES

    chown "${GN_USER}:${GN_USER}" "$ALIASES_FILE" 2>/dev/null || true
    step_ok "Aliases adicionados em ${ALIASES_FILE}"
    step_info "Execute: source ~/.bashrc  (ou faça logout e login)"
    _state_set "etapa_aliases" "1"
}

# ══════════════════════════════════════════════════════════════════════════════
# ETAPA 11 — Remove usuário legado (orangepi) ← PENÚLTIMO
# ══════════════════════════════════════════════════════════════════════════════
etapa_remove_legado() {
    section "🗑   Etapa 11 — Remoção do Usuário Legado (${GN_LEGACY_USER})"
    echo ""

    if ! id "$GN_LEGACY_USER" &>/dev/null; then
        step_ok "Usuário '${GN_LEGACY_USER}' não existe — nada a fazer"
        _state_set "etapa_remove_legado" "1"; return
    fi

    printf "  ${YELLOW}${BOLD}Atenção:${RESET} Se a conexão SSH cair, reconecte com '${GN_USER}'.\n\n"

    # Remove overrides de autologin ANTES de encerrar sessões
    local GETTY_OVR="/lib/systemd/system/getty@.service.d/override.conf"
    local SERIAL_OVR="/lib/systemd/system/serial-getty@.service.d/override.conf"
    [ -f "$GETTY_OVR" ]  && rm -f "$GETTY_OVR"  && step_ok "Removido: $GETTY_OVR"
    [ -f "$SERIAL_OVR" ] && rm -f "$SERIAL_OVR" && step_ok "Removido: $SERIAL_OVR"

    pkill -9 -u "$GN_LEGACY_USER" 2>/dev/null || true
    sleep 1
    deluser --remove-home "$GN_LEGACY_USER" 2>/dev/null \
        && step_ok "Usuário '${GN_LEGACY_USER}' removido" \
        || step_warn "Falha na remoção — faça manualmente se necessário"

    systemctl daemon-reload 2>/dev/null || true
    _state_set "etapa_remove_legado" "1"
}

# ══════════════════════════════════════════════════════════════════════════════
# ETAPA 12 — Propriedade dos arquivos ← ÚLTIMO
# ══════════════════════════════════════════════════════════════════════════════
etapa_chown() {
    section "🔐  Etapa 12 — Propriedade dos Arquivos"
    echo ""
    step_info "Ajustando chown -R ${GN_USER}:${GN_USER} ${PLEB_HOME}/"
    chown -R "${GN_USER}:${GN_USER}" "${PLEB_HOME}/" 2>/dev/null \
        && step_ok "Propriedade definida: ${PLEB_HOME}/" \
        || step_warn "Falha parcial em chown — verifique permissões"
    _state_set "etapa_chown" "1"
}

# ══════════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════════
main() {
    clear
    printf "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║  Ghost Nodes - NodeNation                                    ║"
    echo "  ║  Pre-Install — Halfin Node / OrangePi Zero 3                 ║"
    printf "  ║  %-60s║\n" "  v0.14 — $(date '+%d/%m/%Y')"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    printf "${RESET}\n"

    printf "  ${DIM}Hardware :${RESET} ${BOLD}${GN_HW_MODEL:-OrangePi Zero 3}${RESET}\n"
    printf "  ${DIM}Arch     :${RESET} ${BOLD}${GN_HW_ARCH:-arm64}${RESET}\n"
    printf "  ${DIM}SO       :${RESET} ${BOLD}${GN_HW_OS:-Debian Bookworm}${RESET}\n"
    printf "  ${DIM}Usuário  :${RESET} ${BOLD}${GN_USER}${RESET}\n"
    printf "  ${DIM}Raiz     :${RESET} ${BOLD}${GN_ROOT}${RESET}\n"
    printf "  ${DIM}SSID     :${RESET} ${BOLD}${SSID}${RESET}  ${DIM}|${RESET}  ${DIM}WAN candidatas:${RESET} ${BOLD}${WAN_CANDIDATAS}${RESET}\n"
    echo ""
    sep

    # Mostra etapas já concluídas
    local SKIP=""
    for E in etapa_usuario etapa_sourcelist etapa_remove_docker etapa_hostname \
              etapa_update etapa_ferramentas; do
        [ "$(_state_get $E)" = "1" ] && SKIP="${SKIP}${E##etapa_} "
    done
    [ -n "$SKIP" ] && { step_info "Já concluídas (pular): ${SKIP}"; echo ""; }

    # Run steps — skip already completed ones
    [ "$(_state_get etapa_usuario)" != "1" ]       && etapa_usuario
    [ "$(_state_get etapa_sourcelist)" != "1" ]    && etapa_sourcelist
    [ "$(_state_get etapa_remove_docker)" != "1" ] && etapa_remove_docker
    [ "$(_state_get etapa_hostname)" != "1" ]      && etapa_hostname
    [ "$(_state_get etapa_update)" != "1" ]        && etapa_update
    [ "$(_state_get etapa_ferramentas)" != "1" ]   && etapa_ferramentas
    etapa_alias_wifi        # always verify
    [ "$(_state_get etapa_orange3)" != "1" ]       && etapa_orange3
    [ "$(_state_get etapa_extras)" != "1" ]        && etapa_extras
    [ "$(_state_get etapa_dashboard)" != "1" ]     && etapa_dashboard
    [ "$(_state_get etapa_aliases)" != "1" ]       && etapa_aliases
    etapa_remove_legado     # penultimate
    etapa_chown             # last

    echo ""
    printf "${BOLD}${GREEN}"
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║           ✔  Installation Complete!                         ║"
    echo "  ╠══════════════════════════════════════════════════════════════╣"
    printf "  ║  ${RESET}${DIM}  User      : %-50s${RESET}${BOLD}${GREEN}║\n" "${GN_USER}  (pass: ${GN_DEFAULT_PASSWORD})"
    printf "  ║  ${RESET}${DIM}  Hostname  : %-50s${RESET}${BOLD}${GREEN}║\n" "${GN_HOSTNAME}"
    printf "  ║  ${RESET}${DIM}  SSID      : %-50s${RESET}${BOLD}${GREEN}║\n" "${SSID}"
    printf "  ║  ${RESET}${DIM}  Dashboard : %-50s${RESET}${BOLD}${GREEN}║\n" "http://${GN_HOSTNAME}.local"
    echo "  ╠══════════════════════════════════════════════════════════════╣"
    printf "  ║  ${RESET}${YELLOW}${BOLD}  ⚠  Change your password: passwd${RESET}${BOLD}${GREEN}                        ║\n"
    echo "  ║     Run: source ~/.bashrc                                    ║"
    echo "  ║     Run: ghostnode                                           ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    printf "${RESET}\n"
}

main
