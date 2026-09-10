#!/bin/bash
set -euo pipefail
HALFIN_DIR="${HALFIN_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
source "${HALFIN_DIR}/lib/init.sh"
require_root
WAN_IFACE="${HALFIN_WAN_IFACE:-end0}"
BACKUP_WAN_IFACE="${HALFIN_BACKUP_WAN_IFACE:-wlan1}"
BRIDGE_IFACE="${HALFIN_BRIDGE:-br0}"
[ -n "$WAN_IFACE" ] && [ "$WAN_IFACE" != "$BRIDGE_IFACE" ] || {
    step_err 'WAN ausente ou igual a bridge.'; exit 1;
}
ip link show "$WAN_IFACE" >/dev/null
ip link show "$BRIDGE_IFACE" >/dev/null
sysctl -w net.ipv4.ip_forward=1
mkdir -p /etc/sysctl.d
printf 'net.ipv4.ip_forward=1\n' > /etc/sysctl.d/90-halfin-routing.conf

# Reconcile only our chains; Docker, VPN and administrator rules remain intact.
for spec in 'filter HALFIN-FWD' 'nat HALFIN-NAT'; do
    read -r table chain <<< "$spec"
    iptables -w -t "$table" -N "$chain" 2>/dev/null || iptables -w -t "$table" -S "$chain" >/dev/null
    iptables -w -t "$table" -F "$chain"
done
LAN_CIDR=$(ip -o -4 addr show dev "$BRIDGE_IFACE" | awk 'NR==1{print $4}')
LAN_CIDR="${HALFIN_LAN_CIDR:-${LAN_CIDR:-10.21.21.0/24}}"
for uplink in "$WAN_IFACE" "$BACKUP_WAN_IFACE"; do
    [ "$uplink" != "$BRIDGE_IFACE" ] && ip link show "$uplink" >/dev/null 2>&1 || continue
    iptables -w -A HALFIN-FWD -i "$uplink" -o "$BRIDGE_IFACE" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    iptables -w -A HALFIN-FWD -i "$BRIDGE_IFACE" -o "$uplink" -j ACCEPT
    iptables -w -t nat -A HALFIN-NAT -s "$LAN_CIDR" -o "$uplink" -j MASQUERADE
done
iptables -w -C FORWARD -j HALFIN-FWD 2>/dev/null || iptables -w -I FORWARD 1 -j HALFIN-FWD
iptables -w -t nat -C POSTROUTING -j HALFIN-NAT 2>/dev/null || iptables -w -t nat -A POSTROUTING -j HALFIN-NAT

if [ "${1:-}" != --apply ]; then
    # Retire the old hook that restored the entire firewall on every link-up.
    if [ -f /etc/network/if-up.d/iptables-halfin ]; then
        mv /etc/network/if-up.d/iptables-halfin /etc/network/iptables-halfin.legacy
    fi
    # Some older Halfin images used the generic hook name. Retire only the
    # known raw restore hook; do not touch administrator-maintained scripts.
    if [ -f /etc/network/if-up.d/iptables ] && \
        grep -qx 'iptables-restore < /etc/iptables.rules' /etc/network/if-up.d/iptables; then
        mv /etc/network/if-up.d/iptables /etc/network/iptables.legacy
    fi
    cat > /etc/systemd/system/halfin-routing.service <<EOF
[Unit]
Description=Halfin routing rules
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
Environment=GN_ROOT=${GN_ROOT}
Environment=HALFIN_DIR=${HALFIN_DIR}
Environment=HALFIN_BRIDGE=${BRIDGE_IFACE}
ExecStart=/bin/bash ${HALFIN_DIR}/routing.sh --apply

[Install]
WantedBy=multi-user.target
EOF
    cat > /etc/systemd/system/halfin-uplink-failover.service <<EOF
[Unit]
Description=Halfin WAN failover (end0 primary, wlan1 backup)
After=network-online.target NetworkManager.service halfin-routing.service
Wants=network-online.target

[Service]
Type=oneshot
Environment=HALFIN_PRIMARY_UPLINK=${WAN_IFACE}
Environment=HALFIN_BACKUP_UPLINK=${BACKUP_WAN_IFACE}
ExecStart=/bin/bash ${HALFIN_DIR}/tools/uplink_failover.sh
EOF
    cat > /etc/systemd/system/halfin-uplink-failover.timer <<'EOF'
[Unit]
Description=Periodic Halfin WAN failover check

[Timer]
OnBootSec=45s
OnUnitActiveSec=20s
AccuracySec=2s

[Install]
WantedBy=timers.target
EOF
    systemctl daemon-reload
    systemctl enable halfin-routing.service
    systemctl enable --now halfin-uplink-failover.timer
fi
step_ok "Routing configurado: ${BRIDGE_IFACE} -> ${WAN_IFACE}"
