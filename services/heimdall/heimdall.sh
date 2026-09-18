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
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if ! command -v docker >/dev/null 2>&1; then
  echo 'Docker não está instalado. Execute primeiro: services/docker/docker.sh' >&2
  exit 2
fi
systemctl enable --now docker
if docker container inspect heimdall >/dev/null 2>&1; then
  echo 'heimdall já existe; nenhuma alteração aplicada.'
  exit 0
fi
docker volume create heimdall_config >/dev/null
docker run -d --name heimdall --restart unless-stopped -p 127.0.0.1:${HEIMDALL_PORT:-8080}:80 -v heimdall_config:/config -e PUID=1000 -e PGID=1000 -e TZ=${TZ:-Etc/UTC} -e ALLOW_INTERNAL_REQUESTS=false lscr.io/linuxserver/heimdall:latest
docker ps --filter name=^heimdall$ --format '{{.Names}} {{.Status}}'
echo 'heimdall instalado.'
