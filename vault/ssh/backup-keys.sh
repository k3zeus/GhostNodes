#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║   GhostNodes — SSH Key Backup to Vaultwarden                 ║
# ║   Exports master key + known hosts for disaster recovery     ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Usage: bash backup-keys.sh
#
# Prereqs:
#   - Vaultwarden running and accessible
#   - BW CLI installed (npm install -g @bitwarden/cli)
#     OR manual import via Vaultwarden web UI
#

set -euo pipefail

SSH_DIR="/home/pleb/.ssh"
KEY_NAME="ghostnode_master"
BACKUP_DIR="/home/pleb/vault/ssh/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="ssh_backup_${TIMESTAMP}.tar.gz.enc"

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

info()  { printf "${CYAN}[INFO]${RESET}  %s\n" "$1"; }
ok()    { printf "${GREEN}[OK]${RESET}    %s\n" "$1"; }
err()   { printf "${RED}[ERR]${RESET}   %s\n" "$1"; }

echo ""
printf "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║          GhostNode — SSH Key Backup                          ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
printf "${RESET}\n"

# ── Verify source files ──────────────────────────────────────
if [ ! -f "${SSH_DIR}/${KEY_NAME}" ]; then
    err "Master key not found: ${SSH_DIR}/${KEY_NAME}"
    err "Run setup-ssh-gateway.sh first"
    exit 1
fi

mkdir -p "$BACKUP_DIR"

# ── Create encrypted archive of SSH material ─────────────────
info "Creating encrypted backup of SSH keys..."

# Collect all SSH files
TEMP_DIR=$(mktemp -d)
cp "${SSH_DIR}/${KEY_NAME}" "$TEMP_DIR/"
cp "${SSH_DIR}/${KEY_NAME}.pub" "$TEMP_DIR/"
[ -f "${SSH_DIR}/authorized_keys" ] && cp "${SSH_DIR}/authorized_keys" "$TEMP_DIR/"
[ -f "${SSH_DIR}/known_hosts" ] && cp "${SSH_DIR}/known_hosts" "$TEMP_DIR/"
[ -f "${SSH_DIR}/config" ] && cp "${SSH_DIR}/config" "$TEMP_DIR/"

# Create tar
tar -czf "${BACKUP_DIR}/ssh_backup_${TIMESTAMP}.tar.gz" -C "$TEMP_DIR" .

# Encrypt with passphrase
info "Encrypting backup archive..."
read -sp "  Enter encryption passphrase: " PASSPHRASE
echo ""
read -sp "  Confirm passphrase: " PASSPHRASE_CONFIRM
echo ""

if [ "$PASSPHRASE" != "$PASSPHRASE_CONFIRM" ]; then
    err "Passphrases do not match!"
    rm -rf "$TEMP_DIR" "${BACKUP_DIR}/ssh_backup_${TIMESTAMP}.tar.gz"
    exit 1
fi

openssl enc -aes-256-cbc -salt -pbkdf2 \
    -in "${BACKUP_DIR}/ssh_backup_${TIMESTAMP}.tar.gz" \
    -out "${BACKUP_DIR}/${ARCHIVE_NAME}" \
    -pass "pass:${PASSPHRASE}"

# Cleanup unencrypted
rm -f "${BACKUP_DIR}/ssh_backup_${TIMESTAMP}.tar.gz"
rm -rf "$TEMP_DIR"

ok "Encrypted backup created: ${BACKUP_DIR}/${ARCHIVE_NAME}"

# ── Print recovery instructions ──────────────────────────────
echo ""
printf "${BOLD}${GREEN}"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Backup Complete!"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "${RESET}"
printf "  ${DIM}Archive:${RESET}      ${BOLD}%s${RESET}\n" "${BACKUP_DIR}/${ARCHIVE_NAME}"
printf "\n"
printf "  ${DIM}To restore:${RESET}\n"
printf "    1. ${BOLD}openssl enc -d -aes-256-cbc -pbkdf2 -in %s -out ssh_backup.tar.gz${RESET}\n" "${ARCHIVE_NAME}"
printf "    2. ${BOLD}tar xzf ssh_backup.tar.gz -C ~/.ssh/${RESET}\n"
printf "    3. ${BOLD}chmod 600 ~/.ssh/ghostnode_master${RESET}\n"
printf "\n"
printf "  ${DIM}Recommended:${RESET} Upload ${BOLD}%s${RESET} to Vaultwarden as a Secure Note attachment\n" "${ARCHIVE_NAME}"
printf "\n"
