#!/usr/bin/env bash
set -euo pipefail
command -v aide >/dev/null || { echo "AIDE opcional; prefira SSD para sua base."; exit 2; }
aide --check

