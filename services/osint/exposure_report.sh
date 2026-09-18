#!/usr/bin/env bash
set -euo pipefail
allow=${OSINT_ALLOWLIST:-$(dirname "$0")/authorized-targets.txt}
[ -f "$allow" ] || { echo "Allowlist ausente: $allow" >&2; exit 2; }
while IFS= read -r target; do
  case "$target" in ""|\#*) continue;; esac
  echo "=== $target ==="; dig +short A "$target"; dig +short MX "$target"; dig +short TXT "$target"; dig +short CAA "$target"
done < "$allow"

