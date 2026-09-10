#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/init.sh"
export GN_DB_DIR
main_banner 'Wi-Fi - Conexao'
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo 'Autorizacao sudo necessaria para alterar conexoes Wi-Fi.'
    sudo -v
    export GN_WIFI_USE_SUDO=1
fi
exec python3 "${SCRIPT_DIR}/wifi_db.py" connect "$@"
