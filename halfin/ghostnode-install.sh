#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GN_ROOT="${GN_ROOT:-$(dirname "$SCRIPT_DIR")}"
source "${SCRIPT_DIR}/lib/init.sh"
require_root
test -f "${GN_ROOT}/ghostnode"
test -f "${GN_ROOT}/lib/core_lib.sh"
mkdir -p /usr/local/bin
# A wrapper preserves the installation root for root, sudo and ordinary users.
{
    printf '#!/bin/bash\n'
    printf 'export GN_ROOT=%q\n' "$GN_ROOT"
    printf 'exec bash %q "$@"\n' "${GN_ROOT}/ghostnode"
} > /usr/local/bin/ghostnode
chmod 755 /usr/local/bin/ghostnode
printf '%s\n' 'case $- in *i*) printf "\\nExecute ghostnode para abrir o menu.\\n";; esac' > /etc/profile.d/ghostnode-motd.sh
bash /usr/local/bin/ghostnode --help >/dev/null
step_ok 'Comando ghostnode instalado e validado.'
