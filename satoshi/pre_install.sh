#!/bin/bash
#
# SATOSHI NODE - pre-install bootstrap
#

set -euo pipefail

_GN_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_GN_FIND="$_GN_SELF"
while [ ! -d "${_GN_FIND}/halfin/lib" ] && [ "$_GN_FIND" != "/" ]; do
    _GN_FIND="$(dirname "$_GN_FIND")"
done

source "${_GN_FIND}/halfin/lib/init.sh" 2>/dev/null || {
    echo "[ERRO] halfin/lib/init.sh nao encontrado."
    exit 1
}

require_root

GN_USER="${GN_USER:-pleb}"
GN_ROOT="${GN_ROOT:-/home/${GN_USER}/nodenation}"
GN_DEFAULT_PASSWORD="${GN_DEFAULT_PASSWORD:-Mudar123}"

ensure_runtime_user() {
    if id "$GN_USER" >/dev/null 2>&1; then
        step_ok "Usuario '${GN_USER}' ja existe"
        return
    fi

    step_info "Criando usuario '${GN_USER}'..."
    adduser --disabled-password --gecos "" "$GN_USER"
    echo "${GN_USER}:${GN_DEFAULT_PASSWORD}" | chpasswd
    usermod -aG sudo "$GN_USER"
    step_ok "Usuario '${GN_USER}' criado"
}

install_packages() {
    local packages="ca-certificates curl wget tar"
    local missing=()
    local package

    for package in $packages; do
        if ! dpkg -l "$package" 2>/dev/null | grep -q "^ii"; then
            missing+=("$package")
        fi
    done

    if [ "${#missing[@]}" -eq 0 ]; then
        step_ok "Dependencias base ja instaladas"
        return
    fi

    step_info "Instalando dependencias base: ${missing[*]}"
    DEBIAN_FRONTEND=noninteractive apt-get update -q
    DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
    step_ok "Dependencias base instaladas"
}

main() {
    clear
    main_banner "  SATOSHI NODE - PRE INSTALL  "
    ensure_runtime_user
    mkdir -p "${GN_ROOT}/var"
    chown -R "${GN_USER}:${GN_USER}" "/home/${GN_USER}"
    install_packages
    step_ok "Pre-install do Satoshi concluido"
}

main
