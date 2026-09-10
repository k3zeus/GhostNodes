#!/bin/bash
# Each installation stage runs in a separate strict Bash process.
set -euo pipefail
_GN_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_GN_SELF}/lib/init.sh"
require_root
export GN_USER GN_ROOT HALFIN_DIR
PLEB_HOME="$(getent passwd "$GN_USER" | cut -d: -f6 || true)"
PLEB_HOME="${PLEB_HOME:-/home/${GN_USER}}"
SSID="${HALFIN_SSID:-Halfin}"
WPA2_PASS="${HALFIN_WPA_PASS:-Mudar102030}"
AP_IFACE="${HALFIN_AP_IFACE:-wlan0}"
BRIDGE_IFACE="${HALFIN_BRIDGE:-br0}"
CLIENT_IFACE="${HALFIN_CLIENT_IFACE:-wlan1}"
BRIDGE_IP="${HALFIN_BRIDGE_IP:-10.21.21.1}"
NETMASK="${HALFIN_NETMASK:-255.255.255.0}"
DHCP_START="${HALFIN_DHCP_START:-10.21.21.100}"
DHCP_END="${HALFIN_DHCP_END:-10.21.21.105}"
HOSTAPD_CONF=/etc/hostapd/hostapd.conf
DNSMASQ_CONF=/etc/dnsmasq.d/halfin.conf
# Old checkpoints recorded false successes; never trust that format.
PRE_STATE="${GN_ROOT}/var/preinstall_halfin.v2.state"

_state_get() {
    local value
    value=$(sed -n "s/^${1}=//p" "$PRE_STATE" 2>/dev/null | tail -1)
    printf '%s\n' "${value:-0}"
}

_state_set() {
    local tmp
    mkdir -p "$(dirname "$PRE_STATE")"
    tmp=$(mktemp "${PRE_STATE}.XXXXXX")
    if [ -f "$PRE_STATE" ]; then
        grep -v "^${1}=" "$PRE_STATE" > "$tmp" || true
    fi
    printf '%s=%s\n' "$1" "$2" >> "$tmp"
    mv "$tmp" "$PRE_STATE"
}

_run_extra() {
    local script="$1" description="$2" rc
    section "Extra - ${description}"
    if [ ! -f "$script" ]; then
        step_err "Script ausente: $script"
        return 1
    fi
    if bash "$script"; then
        step_ok "${description}: etapa encerrada"
    else
        rc=$?
        step_err "${description}: falha (codigo ${rc})"
        return "$rc"
    fi
}

etapa_usuario() {
    [[ "$GN_USER" =~ ^[a-z_][a-z0-9_-]*$ ]] || return 1
    if ! id "$GN_USER" >/dev/null 2>&1; then
        adduser --disabled-password --gecos '' "$GN_USER"
        printf '%s:%s\n' "$GN_USER" "$GN_DEFAULT_PASSWORD" | chpasswd
        step_warn 'Altere a senha inicial com passwd apos o primeiro login.'
    fi
    usermod -aG sudo "$GN_USER"
    mkdir -p "$PLEB_HOME"
    chown "${GN_USER}:${GN_USER}" "$PLEB_HOME"
}

etapa_sourcelist() {
    local ID ID_LIKE
    source /etc/os-release
    case "${ID:-}" in
        debian|ubuntu) ;;
        *) [[ " ${ID_LIKE:-} " == *' debian '* || " ${ID_LIKE:-} " == *' ubuntu '* ]] || {
            step_err 'Distribuicao nao suportada: requer Debian/Ubuntu.'; return 1;
        } ;;
    esac
    step_ok "Repositorios de ${PRETTY_NAME:-$ID} preservados"
}

etapa_remove_docker() {
    step_info 'Pacotes Docker existentes preservados ate sua instalacao ser selecionada.'
}

etapa_hostname() {
    [[ "$GN_HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]{0,62}$ ]] || return 1
    hostnamectl set-hostname "$GN_HOSTNAME"
    if grep -q '^127\.0\.1\.1[[:space:]]' /etc/hosts; then
        sed -i "s/^127\.0\.1\.1[[:space:]].*/127.0.1.1 ${GN_HOSTNAME}/" /etc/hosts
    else
        printf '127.0.1.1 %s\n' "$GN_HOSTNAME" >> /etc/hosts
    fi
}

etapa_update() {
    DEBIAN_FRONTEND=noninteractive apt-get update -o APT::Update::Error-Mode=any || return $?
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y || return $?
    step_ok 'Sistema atualizado'
}

etapa_ferramentas() {
    local pkg missing=()
    for pkg in git htop vim net-tools nmap tree lm-sensors dos2unix openssh-server \
        iptraf-ng hostapd iptables iw traceroute bridge-utils iptables-persistent \
        btop sqlite3 dnsmasq ca-certificates curl gnupg lsb-release ifupdown \
        network-manager python3 python3-venv dnsutils wget; do
        dpkg -s "$pkg" 2>/dev/null | grep -q '^Status: install ok installed$' || missing+=("$pkg")
    done
    if [ "${#missing[@]}" -gt 0 ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}" || return $?
    fi
    step_ok 'Ferramentas instaladas'
}

etapa_alias_wifi() {
    step_info 'Nomes das interfaces preservados; configure HALFIN_AP_IFACE se necessario.'
}

_detectar_wan() {
    WAN_IFACE="${HALFIN_WAN_IFACE:-$(ip -4 route show default | awk 'NR==1{print $5}')}"
    [ -n "$WAN_IFACE" ] && [ "$WAN_IFACE" != "$AP_IFACE" ] &&
        [ "$WAN_IFACE" != "$BRIDGE_IFACE" ] && ip link show "$WAN_IFACE" >/dev/null || {
        step_err 'WAN invalida ou compartilhada com o AP.'; return 1;
    }
}

_validar_rede() {
    [[ "$AP_IFACE" =~ ^[a-zA-Z0-9_.-]{1,15}$ ]] || return 1
    [[ "$BRIDGE_IFACE" =~ ^[a-zA-Z0-9_.-]{1,15}$ ]] || return 1
    [ "${#WPA2_PASS}" -ge 8 ] && [ "${#WPA2_PASS}" -le 63 ] || {
        step_err 'Senha WPA2 precisa ter entre 8 e 63 caracteres.'; return 1;
    }
    [[ "$WPA2_PASS" != *$'\n'* && "$SSID" != *$'\n'* ]] || return 1
    [ "${#SSID}" -ge 1 ] && [ "${#SSID}" -le 32 ] || return 1
    python3 - "$BRIDGE_IP" "$NETMASK" "$DHCP_START" "$DHCP_END" <<'PY'
import ipaddress, sys
ip, mask, start, end = sys.argv[1:]
net = ipaddress.IPv4Network(f'{ip}/{mask}', strict=False)
a, b, gateway = map(ipaddress.IPv4Address, (start, end, ip))
assert a in net and b in net and net.network_address < a <= b < net.broadcast_address
assert not a <= gateway <= b
PY
}

_configurar_bridge() {
    mkdir -p /etc/network/interfaces.d /etc/NetworkManager/conf.d
    # ifupdown owns WAN/bridge while NetworkManager owns only the client radio.
    # This is additive so unrelated administrator exclusions remain intact.
    cat > /etc/NetworkManager/conf.d/99-halfin-network-ownership.conf <<EOF
[ifupdown]
managed=false

[keyfile]
unmanaged-devices+=interface-name:end0;interface-name:${AP_IFACE};interface-name:${BRIDGE_IFACE}
EOF
    rm -f /etc/NetworkManager/conf.d/90-halfin-ap.conf
    # A client radio declared here is claimed by ifupdown at the next boot,
    # even when NetworkManager is configured to manage it.
    awk -v iface="$CLIENT_IFACE" '
        /^[[:space:]]*(auto|allow-hotplug)[[:space:]]+/ && $2 == iface { skip=1; next }
        skip && /^[[:space:]]*iface[[:space:]]+/ && $2 == iface { next }
        skip && /^[[:space:]]/ { next }
        skip { skip=0 }
        { print }
    ' /etc/network/interfaces > /etc/network/interfaces.halfin.new
    mv /etc/network/interfaces.halfin.new /etc/network/interfaces
    if ! grep -qE '^source(-directory)? /etc/network/interfaces.d' /etc/network/interfaces; then
        printf '\nsource /etc/network/interfaces.d/*\n' >> /etc/network/interfaces
    fi
    cat > /etc/network/interfaces.d/halfin <<EOF
auto ${BRIDGE_IFACE}
iface ${BRIDGE_IFACE} inet static
    address ${BRIDGE_IP}
    netmask ${NETMASK}
    bridge_ports none
    bridge_stp off
    bridge_fd 0
EOF
    nmcli general reload 2>/dev/null || true
    nmcli device set end0 managed no 2>/dev/null || true
    nmcli device set "$AP_IFACE" managed no 2>/dev/null || true
    nmcli device set "$CLIENT_IFACE" managed yes 2>/dev/null || true
    ifup "$BRIDGE_IFACE"
}

_remover_nm_polkit_legado() {
    # Wi-Fi changes use sudo in the terminal, not a persistent broad Polkit grant.
    rm -f /etc/polkit-1/rules.d/49-halfin-network-manager.rules
}

_configurar_dnsmasq() {
    mkdir -p /etc/dnsmasq.d
    cat > "$DNSMASQ_CONF" <<EOF
interface=${BRIDGE_IFACE}
bind-dynamic
dhcp-range=${DHCP_START},${DHCP_END},${NETMASK},24h
dhcp-option=3,${BRIDGE_IP}
dhcp-option=6,${BRIDGE_IP}
server=1.1.1.1
domain-needed
bogus-priv
EOF
    dnsmasq --test || return $?
    systemctl enable dnsmasq
    systemctl restart dnsmasq || return $?
    systemctl is-active --quiet dnsmasq
}

_configurar_hostapd() {
    mkdir -p /etc/hostapd
    # Conservative 2.4 GHz settings; do not assume 5 GHz/VHT80 support.
    cat > "$HOSTAPD_CONF" <<EOF
interface=${AP_IFACE}
driver=nl80211
bridge=${BRIDGE_IFACE}
ssid=${SSID}
country_code=BR
hw_mode=g
channel=${HALFIN_AP_CHANNEL:-6}
auth_algs=1
wpa=2
wpa_passphrase=${WPA2_PASS}
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wmm_enabled=1
EOF
    chmod 600 "$HOSTAPD_CONF"
    printf 'DAEMON_CONF="%s"\n' "$HOSTAPD_CONF" > /etc/default/hostapd
    systemctl unmask hostapd
    systemctl enable hostapd
    systemctl restart hostapd || return $?
    systemctl is-active --quiet hostapd
}

etapa_orange3() {
    _validar_rede || return $?
    _detectar_wan || return $?
    iw dev "$AP_IFACE" info >/dev/null || {
        step_err "AP ${AP_IFACE} ausente: conecte o hardware e repita esta etapa."; return 1;
    }
    _configurar_bridge
    _remover_nm_polkit_legado
    _configurar_hostapd
    if command -v pihole-FTL >/dev/null 2>&1 && [ "$(pihole-FTL --config dhcp.active)" = true ]; then
        step_info 'Pi-hole DHCP existente preservado; dnsmasq nao sera iniciado em paralelo.'
    else
        _configurar_dnsmasq
    fi
    bash "${HALFIN_DIR}/routing.sh"
    local prefix
    prefix=$(python3 -c 'import ipaddress,sys; print(ipaddress.IPv4Network("0.0.0.0/"+sys.argv[1]).prefixlen)' "$NETMASK")
    python3 "${HALFIN_DIR}/tools/ap_health.py" install --ap "$AP_IFACE" \
        --bridge "$BRIDGE_IFACE" --address "${BRIDGE_IP}/${prefix}"
}

etapa_extras() {
    _run_extra "${HALFIN_DIR}/extras/fail2ban.sh" Fail2ban
    _run_extra "${HALFIN_DIR}/extras/pi-hole.sh" 'Pi-hole + Unbound'
    _run_extra "${HALFIN_DIR}/docker/docker.sh" 'Docker + Portainer + Cockpit'
}

etapa_dashboard() {
    if confirm 'Instalar o dashboard Web?' n; then
        _run_extra "${HALFIN_DIR}/extras/webapp.sh" Dashboard
    else
        step_info 'Dashboard nao selecionado.'
    fi
}

etapa_aliases() {
    local file="${PLEB_HOME}/.bash_aliases"
    if ! grep -q '# GhostNodes aliases' "$file" 2>/dev/null; then
        printf '\n# GhostNodes aliases\nalias gn="ghostnode"\n' >> "$file"
    fi
    chown "${GN_USER}:${GN_USER}" "$file"
    bash "${HALFIN_DIR}/ghostnode-install.sh"
}

etapa_remove_legado() {
    # Never terminate the SSH session or remove a home containing the running repo.
    if id "$GN_LEGACY_USER" >/dev/null 2>&1; then
        step_warn "Usuario ${GN_LEGACY_USER} preservado. Remova manualmente apos validar login como ${GN_USER}."
    fi
}

etapa_chown() {
    chown "${GN_USER}:${GN_USER}" "$PLEB_HOME"
    step_ok 'Propriedade dos dados dos servicos preservada.'
}

main() {
    local stage rc
    local stages=(etapa_usuario etapa_sourcelist etapa_remove_docker etapa_hostname
        etapa_update etapa_ferramentas etapa_alias_wifi etapa_orange3 etapa_extras
        etapa_dashboard etapa_aliases etapa_remove_legado etapa_chown)
    if [ "${1:-}" = --step ]; then
        stage="${2:-}"
        [[ " ${stages[*]} " == *" $stage "* && -n "$stage" ]] || return 2
        "$stage"
        return
    fi
    main_banner 'HALFIN - Instalacao'
    mkdir -p "${GN_ROOT}/var" "${GN_ROOT}/halfin/logs"
    exec 9>"${GN_ROOT}/var/preinstall_halfin.lock"
    flock -n 9 || { step_err 'Outra instalacao esta em andamento.'; return 1; }
    for stage in "${stages[@]}"; do
        section "$stage"
        # A child interpreter keeps errexit effective inside a parent condition.
        if bash "${_GN_SELF}/pre_install.sh" --step "$stage" 2>&1 | tee -a "${GN_ROOT}/halfin/logs/install.log"; then
            _state_set "$stage" 1
        else
            rc=$?
            _state_set "$stage" failed
            step_err "Instalacao incompleta em ${stage} (codigo ${rc}). Corrija e repita --step ${stage}."
            return "$rc"
        fi
    done
    step_ok 'Etapas selecionadas concluidas. Execute ghostnode para verificar o sistema.'
}

main "$@"
