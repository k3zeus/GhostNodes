#!/usr/bin/env bash
set -euo pipefail
command -v gitleaks >/dev/null || { echo "Instale gitleaks no ambiente de desenvolvimento."; exit 2; }
root=${1:-.}; gitleaks detect --source "$root" --redact

