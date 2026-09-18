#!/usr/bin/env bash
set -euo pipefail
HALFIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ "${EUID:-$(id -u)}" -eq 0 ] || { echo 'Execute com sudo.' >&2; exit 1; }
install -d -m 0755 /etc/ssh/sshd_config.d /etc/ghostnodes/backups
[ -f /etc/ssh/sshd_config.d/60-halfin-access.conf ] || cp -a /etc/ssh/sshd_config /etc/ghostnodes/backups/sshd_config.before-halfin-access
cat > /etc/ssh/sshd_config.d/60-halfin-access.conf <<'EOF'
# Halfin: password remains available for Tailscale/NetBird administration.
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
KbdInteractiveAuthentication no
MaxAuthTries 4
LoginGraceTime 30
X11Forwarding no
EOF
sshd -t
if systemctl list-unit-files ssh.service --no-legend 2>/dev/null | grep -q ssh; then systemctl reload ssh; else systemctl reload sshd; fi
if command -v ufw >/dev/null 2>&1; then ufw --force disable || true; fi
bash "$HALFIN_DIR/extras/fail2ban.sh"
install -d -m 0755 /etc/profile.d
cat > /etc/profile.d/20-halfin-ssh-key-guidance.sh <<'EOF'
case $- in *i*)
  if [ "$(id -un 2>/dev/null)" = pleb ] && [ ! -s "$HOME/.ssh/authorized_keys" ]; then
    printf '\nHalfin: senha SSH permanece ativa. Recomenda-se cadastrar uma chave SSH agora.\n'
  fi
esac
EOF
chmod 0644 /etc/profile.d/20-halfin-ssh-key-guidance.sh
echo 'Halfin access: SSH sem root, senha e chave ativas; Fail2ban ativo; UFW desabilitado.'
