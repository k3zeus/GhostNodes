#!/usr/bin/env bash
# Hardware-only Halfin policy. This file is sourced by pre_install.sh.
if [ -n "${_HALFIN_STANDARD_HARDWARE_LOADED:-}" ]; then
  return 0 2>/dev/null || exit 0
fi
_HALFIN_STANDARD_HARDWARE_LOADED=1

_HALFIN_TOOL_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HALFIN_DIR="${HALFIN_DIR:-$(dirname "$_HALFIN_TOOL_DIR")}"
GN_ROOT="${GN_ROOT:-$(dirname "$HALFIN_DIR")}"

halfin_hw_info() { command -v step_info >/dev/null 2>&1 && step_info "$*" || printf '%s\n' "$*"; command -v log_info >/dev/null 2>&1 && log_info "$*" || true; }
halfin_hw_warn() { command -v step_warn >/dev/null 2>&1 && step_warn "$*" || printf '%s\n' "$*" >&2; command -v log_warn >/dev/null 2>&1 && log_warn "$*" || true; }
halfin_hw_err() { command -v step_err >/dev/null 2>&1 && step_err "$*" || printf '%s\n' "$*" >&2; command -v log_err >/dev/null 2>&1 && log_err "$*" || true; }

halfin_is_orangepi_zero3_baseline() {
    local model="${GN_HW_MODEL:-$(tr -d '\0' </proc/device-tree/model 2>/dev/null || true)}"
    local arch="${GN_HW_ARCH:-$(uname -m 2>/dev/null || true)}"
    local os="${GN_HW_OS:-$(. /etc/os-release 2>/dev/null; printf '%s' "${PRETTY_NAME:-}")}" 
    case "$arch" in aarch64) arch=arm64 ;; esac
    printf '%s' "$model" | grep -qiE 'Orange Pi Zero 3|OrangePi Zero3' || return 1
    [ "$arch" = arm64 ] || return 1
    printf '%s' "$os" | grep -qiE 'Debian.*bookworm|bookworm'
}

halfin_apt_backup_root() { printf '%s\n' "${HALFIN_APT_BACKUP_ROOT:-/etc/ghostnodes/backups/apt}"; }

halfin_apply_orangepi_apt() {
    if ! halfin_is_orangepi_zero3_baseline; then
        halfin_hw_info 'APT: fontes preservadas; perfil nao e Orange Pi Zero 3 arm64 Bookworm.'
        return 0
    fi
    local apt_root="${HALFIN_APT_ROOT:-/etc/apt}" source backup stamp apt_update
    source="$apt_root/sources.list"
    [ -f "$source" ] || { halfin_hw_err "APT: fonte ausente: $source"; return 1; }
    stamp="$(date +%Y%m%d-%H%M%S)"
    backup="$(halfin_apt_backup_root)/orangepi-zero3-$stamp"
    mkdir -p "$backup"
    cp -a "$source" "$backup/sources.list"
    [ -d "$apt_root/sources.list.d" ] && cp -a "$apt_root/sources.list.d" "$backup/sources.list.d" || true
    cat > "$source" <<'EOF'
deb http://repo.huaweicloud.com/debian bookworm main contrib non-free non-free-firmware
deb http://repo.huaweicloud.com/debian bookworm-updates main contrib non-free non-free-firmware
deb http://repo.huaweicloud.com/debian bookworm-backports main contrib non-free non-free-firmware
EOF
    apt_update="${HALFIN_APT_UPDATE_CMD:-apt-get}"
    if "$apt_update" update -o APT::Update::Error-Mode=any; then
        halfin_hw_info "APT: espelho Huawei Cloud aplicado; backup: $backup"
        return 0
    fi
    cp -a "$backup/sources.list" "$source"
    "$apt_update" update -o APT::Update::Error-Mode=any || true
    halfin_hw_err "APT: espelho rejeitado; fontes restauradas de $backup"
    return 1
}

halfin_wireless_interfaces() {
    local sys="${HALFIN_SYS_CLASS_NET:-/sys/class/net}" path iface
    for path in "$sys"/*; do
        [ -e "$path" ] || continue
        iface="$(basename "$path")"
        if [ -d "$path/wireless" ] || [ -e "$path/phy80211" ]; then
            printf '%s\n' "$iface"
        fi
    done | LC_ALL=C sort -u
}

halfin_mac_for_iface() {
    local sys="${HALFIN_SYS_CLASS_NET:-/sys/class/net}"
    tr '[:upper:]' '[:lower:]' < "$sys/$1/address" 2>/dev/null
}

halfin_write_hw_value() {
    local key="$1" value="$2" file="${HALFIN_HARDWARE_ENV:-${GN_ROOT}/var/hardware.env}" tmp
    mkdir -p "$(dirname "$file")"
    tmp="$(mktemp "${file}.XXXXXX")"
    [ -f "$file" ] && grep -v "^${key}=" "$file" > "$tmp" || true
    printf '%s=%q\n' "$key" "$value" >> "$tmp"
    mv "$tmp" "$file"
}

halfin_configure_wifi_roles() {
    local -a radios=() ordered=() remaining=()
    local iface ap='' client='' mac_ap='' mac_client='' udev_dir rule
    mapfile -t radios < <(halfin_wireless_interfaces)
    HALFIN_WIFI_RADIO_COUNT="${#radios[@]}"
    HALFIN_WIFI_AP_IFACE=''
    HALFIN_WIFI_CLIENT_IFACE=''
    if [ "${#radios[@]}" -eq 0 ]; then
        halfin_hw_warn 'Wi-Fi: nenhum radio encontrado; nenhuma interface foi alterada. O AP nao sera configurado.'
        return 0
    fi
    for iface in "${radios[@]}"; do [ "$iface" = wlan0 ] && ap=wlan0; done
    [ -n "$ap" ] || ap="${radios[0]}"
    for iface in "${radios[@]}"; do [ "$iface" != "$ap" ] && remaining+=("$iface"); done
    for iface in "${remaining[@]}"; do [ "$iface" = wlan1 ] && client=wlan1; done
    [ -n "$client" ] || [ "${#remaining[@]}" -eq 0 ] || client="${remaining[0]}"
    mac_ap="$(halfin_mac_for_iface "$ap")"
    [ -n "$mac_ap" ] || { halfin_hw_err "Wi-Fi: MAC ausente em $ap"; return 1; }
    udev_dir="${HALFIN_UDEV_DIR:-/etc/udev/rules.d}"
    mkdir -p "$udev_dir"
    rule="$udev_dir/70-halfin-wifi-roles.rules"
    {
        printf '# Managed by Halfin. Roles are bound to MAC, never discovery order.\n'
        printf 'SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="%s", NAME="wlan0"\n' "$mac_ap"
        if [ -n "$client" ]; then
            mac_client="$(halfin_mac_for_iface "$client")"
            [ -n "$mac_client" ] || { halfin_hw_err "Wi-Fi: MAC ausente em $client"; return 1; }
            printf 'SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="%s", NAME="wlan1"\n' "$mac_client"
        fi
    } > "$rule"
    halfin_write_hw_value HALFIN_WIFI_AP_MAC "$mac_ap"
    halfin_write_hw_value HALFIN_WIFI_AP_IFACE wlan0
    HALFIN_WIFI_AP_IFACE="$ap"
    if [ -n "$client" ]; then
        halfin_write_hw_value HALFIN_WIFI_CLIENT_MAC "$mac_client"
        halfin_write_hw_value HALFIN_WIFI_CLIENT_IFACE wlan1
        HALFIN_WIFI_CLIENT_IFACE="$client"
        halfin_hw_info "Wi-Fi: AP=$ap (persistira como wlan0); cliente=$client (persistira como wlan1)."
    else
        halfin_hw_warn "Wi-Fi: radio unico $ap (persistira como wlan0). wlan1 nao foi encontrada; conecte e configure o segundo adaptador manualmente depois."
    fi
    if [ "${#radios[@]}" -gt 2 ]; then
        halfin_hw_warn "Wi-Fi: ${#radios[@]} radios detectados; somente AP e primeiro cliente receberam papeis."
    fi
    [ "${HALFIN_UDEV_RELOAD:-1}" = "1" ] && command -v udevadm >/dev/null 2>&1 && udevadm control --reload || true
}

halfin_remove_orangepi_now() {
    local legacy=orangepi backup_root backup
    id "$legacy" >/dev/null 2>&1 || return 0
    if pgrep -u "$legacy" >/dev/null 2>&1; then return 1; fi
    backup_root="${HALFIN_USER_BACKUP_ROOT:-/var/backups/halfin-users}"
    backup="$backup_root/${legacy}-$(date +%Y%m%d-%H%M%S).tar.gz"
    mkdir -p "$backup_root"
    tar --one-file-system -C /home -czf "$backup" "$legacy"
    userdel -r "$legacy"
    halfin_hw_info "Usuario legado orangepi removido; backup: $backup"
}

halfin_migrate_orangepi_user() {
    halfin_is_orangepi_zero3_baseline || return 0
    id orangepi >/dev/null 2>&1 || { halfin_hw_info 'Usuario legado orangepi ja nao existe.'; return 0; }
    id pleb >/dev/null 2>&1 || { halfin_hw_err 'Usuario pleb ausente; orangepi sera preservado.'; return 1; }
[ -d /home/pleb ] && [ "$(stat -c '%U:%G' /home/pleb 2>/dev/null || true)" = 'pleb:pleb' ] || { halfin_hw_err 'Home de pleb invalida; orangepi sera preservado.'; return 1; }
    getent group sudo | awk -F: '{ n = split($4, members, ","); for (i = 1; i <= n; i++) if (members[i] == "pleb") exit 0; exit 1 }' || { halfin_hw_err 'pleb nao pertence ao grupo sudo; orangepi sera preservado.'; return 1; }
    if halfin_remove_orangepi_now; then return 0; fi
    halfin_hw_warn 'Usuario orangepi ainda possui processos; remocao sera tentada no proximo boot.'
    cat > /etc/systemd/system/halfin-remove-orangepi.service <<EOF
[Unit]
Description=Halfin finalize Orange Pi legacy user migration
After=multi-user.target
[Service]
Type=oneshot
ExecStart=/bin/bash ${HALFIN_DIR}/tools/standard_hardware.sh --remove-orangepi
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable halfin-remove-orangepi.service
}

if [ "${1:-}" = --remove-orangepi ]; then
    halfin_is_orangepi_zero3_baseline || exit 0
    halfin_remove_orangepi_now && systemctl disable --now halfin-remove-orangepi.service 2>/dev/null || exit 1
fi
