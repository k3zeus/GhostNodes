#!/bin/bash
# Legacy entrypoint uses the same AP stage as the installer.
set -euo pipefail
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/pre_install.sh" --step etapa_orange3
