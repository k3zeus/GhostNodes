#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/init.sh"
require_root
if ! confirm 'Instalar Pi-hole + Unbound?' n; then exit 0; fi
BRIDGE="${HALFIN_BRIDGE:-br0}"
BRIDGE_IP="${HALFIN_BRIDGE_IP:-10.21.21.1}"
UNBOUND_PORT="${PIHOLE_UNBOUND_PORT:-5335}"
DEBIAN_FRONTEND=noninteractive apt-get install -y unbound dnsutils curl
mkdir -p /etc/unbound/unbound.conf.d
cat > /etc/unbound/unbound.conf.d/pi-hole.conf <<EOF
server:
    interface: 127.0.0.1
    port: ${UNBOUND_PORT}
    do-ip6: no
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: no
    edns-buffer-size: 1232
    prefetch: yes
EOF
unbound-checkconf
systemctl enable unbound
systemctl restart unbound
systemctl is-active --quiet unbound
# Download completely before stopping the working DNS/DHCP service.
installer="$(mktemp /tmp/ghostnodes-pihole.XXXXXX)"
curl -fsSL https://install.pi-hole.net -o "$installer"
dnsmasq_active=0
systemctl is-active --quiet dnsmasq && dnsmasq_active=1
restore_dns() {
    local rc=$?
    rm -f "$installer"
    if [ "$rc" -ne 0 ] && [ "$dnsmasq_active" -eq 1 ]; then
        systemctl stop pihole-FTL 2>/dev/null || true
        systemctl start dnsmasq || true
    fi
}
trap restore_dns EXIT
systemctl stop dnsmasq
if [ "${PIHOLE_UNATTENDED:-false}" = true ]; then
    bash "$installer" --unattended
else
    bash "$installer"
fi
command -v pihole-FTL >/dev/null
# Use supported v6 settings, preserving the installed TOML and DHCP contract.
pihole-FTL --config dns.upstreams "[\"127.0.0.1#${UNBOUND_PORT}\"]"
pihole-FTL --config dns.interface "$BRIDGE"
pihole-FTL --config dns.listeningMode BIND
pihole-FTL --config dhcp.start "${HALFIN_DHCP_START:-10.21.21.100}"
pihole-FTL --config dhcp.end "${HALFIN_DHCP_END:-10.21.21.105}"
pihole-FTL --config dhcp.router "$BRIDGE_IP"
pihole-FTL --config dhcp.netmask "${HALFIN_NETMASK:-255.255.255.0}"
pihole-FTL --config dhcp.active true
systemctl restart pihole-FTL
systemctl is-active --quiet pihole-FTL
dig +time=5 +tries=1 @127.0.0.1 pi-hole.net | grep -q 'status: NOERROR'
systemctl disable dnsmasq
if command -v halfin-ap >/dev/null 2>&1; then
    halfin-ap install --ap "${HALFIN_AP_IFACE:-wlan0}" --bridge "$BRIDGE" \
        --address "${BRIDGE_IP}/$(python3 -c 'import ipaddress,os; print(ipaddress.IPv4Network("0.0.0.0/"+os.environ.get("HALFIN_NETMASK","255.255.255.0")).prefixlen)')" \
        --dns-service pihole-FTL
fi
# Keep resolv.conf managed by the operating system.
step_ok 'Pi-hole + Unbound respondendo; DHCP configurado na bridge.'
