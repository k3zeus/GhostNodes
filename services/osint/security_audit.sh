#!/usr/bin/env bash
set -euo pipefail
command -v lynis >/dev/null || { echo "Instale lynis para auditoria."; exit 2; }
lynis audit system --quick

