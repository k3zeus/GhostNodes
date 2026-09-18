#!/usr/bin/env bash
set -euo pipefail
units=${*:-ssh.service fail2ban.service docker.service pihole-FTL.service bitcoind.service}
for unit in $units; do systemctl cat "$unit" >/dev/null 2>&1 || continue; echo "--- $unit ---"; systemd-analyze security "$unit"; done

