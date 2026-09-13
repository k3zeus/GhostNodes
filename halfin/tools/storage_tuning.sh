#!/usr/bin/env bash
# Conservative write-reduction defaults for Halfin installations.
set -euo pipefail
export PATH=/usr/sbin:/usr/bin:/sbin:/bin

backup_fstab() {
    install -d -m 0750 /etc/ghostnodes/backups
    [ -e /etc/ghostnodes/backups/fstab.before-halfin-storage ] || \
        cp -a /etc/fstab /etc/ghostnodes/backups/fstab.before-halfin-storage
}

enable_noatime_root() {
    local tmp
    if ! awk '$1 !~ /^#/ && $2 == "/" { found=1 } END { exit !found }' /etc/fstab; then
        echo 'Halfin storage: entrada de / não encontrada no fstab; noatime não foi persistido.'
        return 0
    fi
    backup_fstab
    tmp="$(mktemp /etc/fstab.halfin.XXXXXX)"
    awk '
        $1 !~ /^#/ && $2 == "/" {
            count=split($4, options, ","); found=0; rebuilt=""
            for (i=1; i<=count; i++) {
                if (options[i] ~ /^commit=/) continue
                if (options[i] == "noatime") found=1
                rebuilt=rebuilt (rebuilt == "" ? "" : ",") options[i]
            }
            if (!found) rebuilt=rebuilt ",noatime"
            $4=rebuilt
        }
        { print }
    ' /etc/fstab > "$tmp"
    install -m 0644 "$tmp" /etc/fstab
    rm -f "$tmp"
    mount -o remount,noatime,commit=5 / 2>/dev/null || \
        echo 'Halfin storage: noatime será aplicado no próximo boot.'
}

zram_is_active() {
    command -v swapon >/dev/null 2>&1 || return 1
    swapon --show --noheadings --raw --output NAME 2>/dev/null | grep -q '^/dev/zram'
}

configure_zram() {
    # Some board images already provide ZRAM. Do not replace an active device.
    if zram_is_active; then
        echo 'Halfin storage: ZRAM already active; preserving the image provider.'
        if systemctl is-failed --quiet zramswap.service 2>/dev/null; then
            systemctl disable zramswap.service || true
            systemctl reset-failed zramswap.service || true
        fi
        return 0
    fi
    DEBIAN_FRONTEND=noninteractive apt-get install -y zram-tools
    cat > /etc/default/zramswap <<'EOF'
# Managed by GhostNodes Halfin. Keep swap compressed in RAM, never in MicroSD.
ALGO=lz4
PERCENT=50
PRIORITY=100
EOF
    if [ -f /swapfile ]; then
        swapoff /swapfile 2>/dev/null || true
        sed -i '\|^[^#].*[[:space:]]/swapfile[[:space:]]| s|^|# GhostNodes disabled disk swap: |' /etc/fstab
    fi
    if systemctl list-unit-files dphys-swapfile.service --no-legend 2>/dev/null | grep -q dphys-swapfile; then
        systemctl disable --now dphys-swapfile.service || true
    fi
    systemctl enable --now zramswap.service
}

configure_journal_limits() {
    install -d -m 0755 /etc/systemd/journald.conf.d
    cat > /etc/systemd/journald.conf.d/60-halfin-retention.conf <<'EOF'
[Journal]
# Preserve diagnostics but bound writes and occupied space on the system volume.
Storage=auto
SystemMaxUse=100M
SystemKeepFree=200M
SystemMaxFileSize=16M
MaxRetentionSec=14day
RuntimeMaxUse=64M
EOF
    systemctl restart systemd-journald.service
}

configure_memory_policy() {
    install -d -m 0755 /etc/sysctl.d
    rm -f /etc/sysctl.d/60-halfin-memory.conf
    cat > /etc/sysctl.d/99-halfin-memory.conf <<'EOF'
# Prefer RAM; zram remains available as a compressed last resort.
vm.swappiness=10
EOF
    sysctl --system >/dev/null
    sysctl -w vm.swappiness=10 >/dev/null
}

main() {
    enable_noatime_root
    configure_zram
    configure_journal_limits
    configure_memory_policy
    echo 'Halfin storage: noatime, ZRAM, journal limits and memory policy configured.'
}

main "$@"
