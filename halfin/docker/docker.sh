#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/init.sh"
require_root

install_docker() {
    if ! docker info >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
        local ID VERSION_CODENAME UBUNTU_CODENAME ID_LIKE distro codename pkg conflicts=()
        source /etc/os-release
        distro="$ID"
        codename="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
        if [[ " ${ID_LIKE:-} " == *' ubuntu '* ]]; then distro=ubuntu; fi
        case "$distro" in debian|ubuntu) ;; *) step_err 'Distribuicao Docker nao suportada'; return 1;; esac
        for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
            dpkg -s "$pkg" 2>/dev/null | grep -q '^Status: install ok installed$' && conflicts+=("$pkg")
        done
        if [ "${#conflicts[@]}" -gt 0 ]; then apt-get remove -y "${conflicts[@]}"; fi
        apt-get update -o APT::Update::Error-Mode=any
        apt-get install -y ca-certificates curl
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL "https://download.docker.com/linux/${distro}/gpg" -o /etc/apt/keyrings/docker.asc
        chmod 644 /etc/apt/keyrings/docker.asc
        printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/%s %s stable\n' \
            "$(dpkg --print-architecture)" "$distro" "$codename" > /etc/apt/sources.list.d/docker.list
        apt-get update -o APT::Update::Error-Mode=any
        DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        systemctl enable --now docker
    fi
    docker info >/dev/null
    docker compose version
    if id "$GN_USER" >/dev/null 2>&1; then usermod -aG docker "$GN_USER"; fi
}

install_portainer() {
    if docker container inspect portainer >/dev/null 2>&1; then
        docker start portainer >/dev/null
    else
        docker volume create portainer_data >/dev/null
        docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always \
            -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:lts
    fi
    test "$(docker inspect -f '{{.State.Running}}' portainer)" = true
}

prepare_compose_env() {
    python3 - "${SCRIPT_DIR}" <<'PY'
import os, pathlib, secrets, sys
root = pathlib.Path(sys.argv[1])
target = root / '.env'
if not target.exists():
    text = (root / '.env.example').read_text()
    text = text.replace('DOCKER_ROOT=/home/pleb/nodenation/halfin/docker', f'DOCKER_ROOT={root}')
    for name in ('SYNCTHING_PASS', 'WG_PASSWORD', 'POSTGRES_PASSWORD'):
        text = text.replace(f'{name}=Mudar123', f'{name}={secrets.token_hex(24)}')
    fd = os.open(target, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w') as stream:
        stream.write(text)
target.chmod(0o600)
PY
}

main() {
    local choice
    while true; do
        section 'Docker / Portainer / Cockpit'
        printf '[1] Docker + Portainer\n[2] Cockpit\n[3] Ambos\n[0] Voltar sem instalar\n[q] Sair\n'
        read -r choice || return 0
        case "$choice" in
            0|'') return 0 ;;
            q|Q) [ "${GN_TUI_CHILD:-0}" = 1 ] && exit 200; return 0 ;;
            1|2|3) break ;;
            *) step_warn 'Opcao invalida' ;;
        esac
    done
    if [ "$choice" = 1 ] || [ "$choice" = 3 ]; then
        install_docker
        install_portainer
        prepare_compose_env
        if confirm 'Subir a stack Compose configurada no .env?' n; then
            docker compose --project-directory "$SCRIPT_DIR" config --quiet
            docker compose --project-directory "$SCRIPT_DIR" up -d --wait --wait-timeout 180
        fi
    fi
    if [ "$choice" = 2 ] || [ "$choice" = 3 ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y cockpit
        systemctl enable --now cockpit.socket
        systemctl is-active --quiet cockpit.socket
    fi
    step_ok 'Servicos selecionados instalados.'
}
main "$@"
