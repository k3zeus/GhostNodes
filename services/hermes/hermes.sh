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
if ! command -v docker >/dev/null 2>&1; then
  echo 'Docker não está instalado. Execute primeiro: services/docker/docker.sh' >&2
  exit 2
fi
systemctl enable --now docker
if docker container inspect hermes-open-webui >/dev/null 2>&1; then echo 'hermes-open-webui já existe; nenhuma alteração aplicada.'; exit 0; fi
install -d -m 0750 /opt/ghostnodes/hermes
secret=$(openssl rand -hex 32)
printf 'WEBUI_SECRET_KEY=%s\n' "$secret" > /opt/ghostnodes/hermes/.env
chmod 0600 /opt/ghostnodes/hermes/.env
docker volume create hermes_open_webui_data >/dev/null
docker run -d --name hermes-open-webui --restart unless-stopped -p "127.0.0.1:${HERMES_PORT:-3000}:8080" -v hermes_open_webui_data:/app/backend/data --env-file /opt/ghostnodes/hermes/.env ghcr.io/open-webui/open-webui:main
docker ps --filter name=^hermes-open-webui$ --format '{{.Names}} {{.Status}}'
echo 'Hermes (Open WebUI) instalado em localhost; configure proxy e acesso da Raiz antes de expor.'
