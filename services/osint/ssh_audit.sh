#!/usr/bin/env bash
set -euo pipefail
[ ${EUID:-$(id -u)} -eq 0 ] || exec sudo -- "$0" "$@"
sshd_bin=$(command -v sshd || true)
if [ -z "$sshd_bin" ] && [ -x /usr/sbin/sshd ]; then sshd_bin=/usr/sbin/sshd; fi
[ -n "$sshd_bin" ] || { echo 'sshd não encontrado.' >&2; exit 2; }
"$sshd_bin" -T | grep -E "^(permitrootlogin|passwordauthentication|pubkeyauthentication|maxauthtries|logingracetime) "
printf "sudo users: "; getent group sudo | cut -d: -f4
printf "authorized key files: "; find /home -path "*/.ssh/authorized_keys" -type f -printf "%p\n" 2>/dev/null