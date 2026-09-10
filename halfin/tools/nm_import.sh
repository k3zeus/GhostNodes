#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/init.sh"
export GN_DB_DIR
exec python3 "${SCRIPT_DIR}/wifi_db.py" import-nm "$@"
