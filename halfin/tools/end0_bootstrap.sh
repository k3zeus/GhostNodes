#!/bin/bash
# Restore the primary wired uplink only when ifupdown did not configure it at boot.
# Halfin intentionally keeps end0 outside NetworkManager ownership.
set -euo pipefail

IFACE="${HALFIN_PRIMARY_UPLINK:-end0}"
IP_BIN="${IP_BIN:-ip}"
IFUP_BIN="${IFUP_BIN:-ifup}"
LOGGER_BIN="${LOGGER_BIN:-logger}"
INTERFACES_FILE="${INTERFACES_FILE:-/etc/network/interfaces}"

log() {
    "$LOGGER_BIN" -t halfin-end0-ensure -- "$*" 2>/dev/null || true
    printf '%s\n' "$*"
}

has_carrier() {
    "$IP_BIN" -o link show dev "$IFACE" | grep -qv 'NO-CARRIER'
}

has_ipv4() {
    "$IP_BIN" -4 -o addr show dev "$IFACE" scope global | grep -q .
}

has_default_route() {
    "$IP_BIN" -4 route show default dev "$IFACE" | grep -q '^default '
}

static_gateway() {
    [ -r "$INTERFACES_FILE" ] || return 1
    awk -v iface="$IFACE" '
        $1 == "iface" && $2 == iface && $3 == "inet" { active = ($4 == "static"); next }
        active && $1 == "gateway" { print $2; exit }
    ' "$INTERFACES_FILE"
}

"$IP_BIN" link show "$IFACE" >/dev/null 2>&1 || {
    log "uplink $IFACE is absent"
    exit 2
}

# A disconnected Ethernet cable is normal when wlan1 is the failover uplink.
# It must not make the boot guard fail or launch a competing DHCP client.
if ! has_carrier; then
    log "uplink $IFACE has no carrier; no wired recovery required"
    exit 0
fi

if has_ipv4 && has_default_route; then
    log "uplink $IFACE already has IPv4 and default route"
    exit 0
fi

log "uplink $IFACE lacks IPv4 or default route; requesting ifupdown recovery"
"$IFUP_BIN" --force "$IFACE" || log "ifupdown returned a non-zero status for $IFACE"

if has_ipv4 && has_default_route; then
    log "uplink $IFACE recovered by ifupdown"
    exit 0
fi

if has_ipv4 && gateway="$(static_gateway)" && [ -n "$gateway" ]; then
    log "uplink $IFACE has static IPv4 but no route; restoring configured gateway"
    "$IP_BIN" -4 route replace default via "$gateway" dev "$IFACE"
fi

if has_ipv4 && has_default_route; then
    log "uplink $IFACE recovered by configured static gateway"
    exit 0
fi

log "uplink $IFACE remains incomplete after recovery"
exit 1