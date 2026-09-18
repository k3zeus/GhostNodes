#!/usr/bin/env bash
set -euo pipefail
sshd -T | grep -E "^(permitrootlogin|passwordauthentication|pubkeyauthentication|maxauthtries|logingracetime) "
printf "sudo users: "; getent group sudo | cut -d: -f4
printf "authorized key files: "; find /home -path "*/.ssh/authorized_keys" -type f -printf "%p
" 2>/dev/null

