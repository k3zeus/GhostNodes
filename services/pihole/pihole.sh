#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true
run() { if "$DRY_RUN"; then printf '[dry-run] '; printf '%q ' "$@"; printf '\n'; else "$@"; fi; }
require_debian_like() {
  [[ -r /etc/os-release ]] || { echo 'Este instalador requer Debian ou Ubuntu.' >&2; exit 1; }
  . /etc/os-release
  case "$ID" in debian|ubuntu) ;; *) echo "Sistema não suportado: $ID (use Debian/Ubuntu)." >&2; exit 1;; esac
}
if "$DRY_RUN"; then
  echo 'DRY RUN: nenhuma alteração será aplicada.'
  exit 0
fi
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then exec sudo -- "$0" "$@"; fi
require_debian_like
apt-get update
apt-get install -y ca-certificates curl
installer=$(mktemp /tmp/pihole-install.XXXXXX)
trap 'rm -f "$installer"' EXIT
curl -fsSL https://install.pi-hole.net -o "$installer"
echo 'O instalador oficial abrirá perguntas sobre IP estático, DNS, interface e senha.'
bash "$installer"
command -v pihole >/dev/null
echo 'Pi-hole instalado. Revise pihole -a -p e a configuração de DNS antes de apontar clientes.'
