#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║   GhostNodes — SSH Gateway Setup                             ║
# ║   Generates master ed25519 keypair + hardens sshd            ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Usage: sudo bash setup-ssh-gateway.sh
#

set -euo pipefail

SSH_DIR="/home/pleb/.ssh"
KEY_NAME="ghostnode_master"
KEY_PATH="${SSH_DIR}/${KEY_NAME}"
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_DIR="/home/pleb/vault/ssh/backups"

# ── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

info()  { printf "${CYAN}[INFO]${RESET}  %s\n" "$1"; }
ok()    { printf "${GREEN}[OK]${RESET}    %s\n" "$1"; }
err()   { printf "${RED}[ERR]${RESET}   %s\n" "$1"; }
warn()  { printf "${DIM}[WARN]${RESET}  %s\n" "$1"; }

# ── Root check ────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    err "Execute como root: sudo bash setup-ssh-gateway.sh"
    exit 1
fi

echo ""
printf "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║          GhostNode — SSH Gateway Setup                       ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
printf "${RESET}\n"

# ── Step 1: Create SSH directory ──────────────────────────────
info "Preparing SSH directory..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown pleb:pleb "$SSH_DIR"

# ── Step 2: Generate master ed25519 key ───────────────────────
if [ -f "$KEY_PATH" ]; then
    warn "Master key already exists at $KEY_PATH"
    read -p "  Overwrite? (y/N): " OVERWRITE
    [[ "$OVERWRITE" != "y" && "$OVERWRITE" != "Y" ]] && { info "Keeping existing key."; } || {
        rm -f "$KEY_PATH" "${KEY_PATH}.pub"
    }
fi

if [ ! -f "$KEY_PATH" ]; then
    info "Generating ed25519 master keypair..."
    ssh-keygen -t ed25519 -C "ghostnode-master@$(hostname)" -f "$KEY_PATH" -N ""
    chown pleb:pleb "$KEY_PATH" "${KEY_PATH}.pub"
    chmod 600 "$KEY_PATH"
    chmod 644 "${KEY_PATH}.pub"
    ok "Master key generated: $KEY_PATH"
fi

# ── Step 3: Display public key ────────────────────────────────
echo ""
info "Your public key (copy to target hosts):"
printf "${DIM}────────────────────────────────────────────────────${RESET}\n"
cat "${KEY_PATH}.pub"
printf "${DIM}────────────────────────────────────────────────────${RESET}\n"
echo ""

# ── Step 4: Harden sshd_config ────────────────────────────────
info "Hardening SSH daemon configuration..."

# Backup original config
if [ ! -f "${SSHD_CONFIG}.ghostnode-backup" ]; then
    cp "$SSHD_CONFIG" "${SSHD_CONFIG}.ghostnode-backup"
    ok "Original sshd_config backed up"
fi

# Apply security settings
declare -A SSHD_SETTINGS=(
    ["PasswordAuthentication"]="no"
    ["PermitRootLogin"]="prohibit-password"
    ["PubkeyAuthentication"]="yes"
    ["AuthorizedKeysFile"]="%.ssh/authorized_keys"
    ["MaxAuthTries"]="3"
    ["LoginGraceTime"]="30"
    ["X11Forwarding"]="no"
    ["AllowAgentForwarding"]="no"
    ["PermitEmptyPasswords"]="no"
    ["ClientAliveInterval"]="300"
    ["ClientAliveCountMax"]="2"
)

for key in "${!SSHD_SETTINGS[@]}"; do
    value="${SSHD_SETTINGS[$key]}"
    if grep -q "^#*${key}" "$SSHD_CONFIG"; then
        sed -i "s/^#*${key}.*/${key} ${value}/" "$SSHD_CONFIG"
    else
        echo "${key} ${value}" >> "$SSHD_CONFIG"
    fi
done
ok "sshd_config hardened (password auth disabled, key-only)"

# ── Step 5: Create backup directory ───────────────────────────
mkdir -p "$BACKUP_DIR"
chown pleb:pleb "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

# ── Step 6: Restart sshd ─────────────────────────────────────
info "Restarting SSH daemon..."
systemctl restart sshd 2>/dev/null || service ssh restart 2>/dev/null || warn "Could not restart sshd — do it manually"
ok "SSH daemon restarted"

# ── Summary ───────────────────────────────────────────────────
echo ""
printf "${BOLD}${GREEN}"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   SSH Gateway Setup Complete!"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "${RESET}"
printf "  ${DIM}Master Key:${RESET}     ${BOLD}%s${RESET}\n" "$KEY_PATH"
printf "  ${DIM}Public Key:${RESET}     ${BOLD}%s.pub${RESET}\n" "$KEY_PATH"
printf "  ${DIM}Backup Dir:${RESET}     ${BOLD}%s${RESET}\n" "$BACKUP_DIR"
printf "\n"
printf "  ${DIM}Next steps:${RESET}\n"
printf "    1. Copy public key to target hosts:  ${BOLD}ssh-copy-id -i %s.pub user@target${RESET}\n" "$KEY_PATH"
printf "    2. Store private key in Vaultwarden:  ${BOLD}bash backup-keys.sh${RESET}\n"
printf "    3. Test connection:                   ${BOLD}ssh -i %s user@target${RESET}\n" "$KEY_PATH"
printf "\n"
