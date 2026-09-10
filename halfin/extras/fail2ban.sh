#!/bin/bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/init.sh"
require_root
DEBIAN_FRONTEND=noninteractive apt-get install -y fail2ban python3-systemd
mkdir -p /etc/fail2ban/jail.d
# Migrate only legacy Halfin-generated duplicate sshd sections.
if grep -q 'Halfin Node.*SSH Protection' /etc/fail2ban/jail.local 2>/dev/null; then
    cp -p /etc/fail2ban/jail.local /etc/fail2ban/jail.local.before-halfin-fix
    awk '/^\[/{skip=($0=="[sshd]")} !skip' /etc/fail2ban/jail.local > /etc/fail2ban/jail.local.new
    mv /etc/fail2ban/jail.local.new /etc/fail2ban/jail.local
fi
cat > /etc/fail2ban/jail.d/90-halfin.local <<EOF
[sshd]
enabled = true
backend = systemd
port = ${FAIL2BAN_SSH_PORT:-22}
maxretry = ${FAIL2BAN_MAXRETRY:-4}
bantime = ${FAIL2BAN_BANTIME:-1w}
findtime = 10m
EOF
fail2ban-client -t
systemctl enable fail2ban
systemctl restart fail2ban
for attempt in {1..20}; do
    if fail2ban-client status sshd; then
        step_ok 'Fail2ban ativo e protegendo SSH'
        exit 0
    fi
    sleep 0.5
done
step_err 'Fail2ban nao ficou pronto.'
exit 1
