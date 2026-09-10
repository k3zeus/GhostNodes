#!/bin/bash
set -euo pipefail

PRIMARY="${HALFIN_PRIMARY_UPLINK:-end0}"
BACKUP="${HALFIN_BACKUP_UPLINK:-wlan1}"
STATE=/run/halfin-uplink-failover

has_ipv4() {
    ip -4 -o addr show dev "$1" scope global | grep -q .
}

gateway_for() {
    ip -4 route show default dev "$1" | awk '/via/ {print $3; exit}'
}

healthy() {
    local iface="$1"
    has_ipv4 "$iface" && curl --interface "$iface" --connect-timeout 3 --max-time 5 \
        -k -fsS -o /dev/null https://1.1.1.1/cdn-cgi/trace
}

configure_backup_policy() {
    local cidr address network gateway
    cidr=$(ip -4 -o addr show dev "$BACKUP" scope global | awk 'NR==1{print $4}')
    address=${cidr%/*}
    gateway=$(gateway_for "$BACKUP")
    network=$(ip -4 route show dev "$BACKUP" proto kernel | awk 'NR==1{print $1}')
    [ -n "$cidr" ] && [ -n "$gateway" ] && [ -n "$network" ] || return 1
    grep -q '^101 halfin-wlan1$' /etc/iproute2/rt_tables || echo '101 halfin-wlan1' >> /etc/iproute2/rt_tables
    ip route replace "$network" dev "$BACKUP" src "$address" table halfin-wlan1
    ip route replace default via "$gateway" dev "$BACKUP" table halfin-wlan1
    ip rule del from "$address/32" table halfin-wlan1 priority 101 2>/dev/null || true
    ip rule add from "$address/32" table halfin-wlan1 priority 101
    sysctl -w net.ipv4.conf.all.rp_filter=2 net.ipv4.conf.default.rp_filter=2 \
        "net.ipv4.conf.${BACKUP}.rp_filter=2" >/dev/null
}

set_metric() {
    local iface="$1" metric="$2" gateway
    gateway=$(gateway_for "$iface")
    [ -n "$gateway" ] || return 1
    # DHCP can leave a metric-zero default behind after a carrier loss.
    ip route del default via "$gateway" dev "$iface" metric 0 2>/dev/null || true
    ip route replace default via "$gateway" dev "$iface" metric "$metric"
}

if healthy "$PRIMARY"; then
    set_metric "$PRIMARY" 100
    if has_ipv4 "$BACKUP"; then
        configure_backup_policy
        set_metric "$BACKUP" 600 || true
    else
        ip route del default dev "$BACKUP" 2>/dev/null || true
    fi
    printf 'primary=%s\n' "$PRIMARY" > "$STATE"
    exit 0
fi

if healthy "$BACKUP"; then
    configure_backup_policy
    set_metric "$BACKUP" 50
    printf 'primary=%s\n' "$BACKUP" > "$STATE"
    exit 0
fi

printf 'primary=none\n' > "$STATE"
exit 1
