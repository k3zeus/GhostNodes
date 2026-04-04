#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  docker/docker.sh — Instalação Docker + Portainer          ║
# ║  Ghost Nodes - NodeNation / Halfin Node                    ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Biblioteca modular ────────────────────────────────────────────────────────
_GN_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_GN_FIND="$_GN_SELF"
while [ ! -d "${_GN_FIND}/lib" ] && [ "$_GN_FIND" != "/" ]; do
    _GN_FIND="$(dirname "$_GN_FIND")"
done
[ -f "${_GN_FIND}/halfin/lib/init.sh" ] && source "${_GN_FIND}/halfin/lib/init.sh" || {
    BOLD="\e[1m"; RESET="\e[0m"; DIM="\e[2m"
    GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; CYAN="\e[36m"; WHITE="\e[97m"
    CHECK="${GREEN}✔${RESET}"; CROSS="${RED}✘${RESET}"; WARN="${YELLOW}⚠${RESET}"; ARROW="${CYAN}▶${RESET}"
    sep()     { printf "${DIM}  ──────────────────────────────────────────────────────────────${RESET}\n"; }
    sep_thin(){ printf "${DIM}  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${RESET}\n"; }
    section() { echo ""; printf "${BOLD}\e[35m  ┌─ %s${RESET}\n" "$1"; sep_thin; }
    step_ok()  { printf "  ${CHECK} ${WHITE}%s${RESET}\n" "$1"; }
    step_warn(){ printf "  ${WARN}  ${YELLOW}%s${RESET}\n" "$1"; }
    step_err() { printf "  ${CROSS} ${RED}%s${RESET}\n" "$1"; }
    step_info(){ printf "  ${ARROW} ${DIM}%s${RESET}\n" "$1"; }
    press_enter(){ echo ""; printf "  ${DIM}[ ENTER para continuar ]${RESET}"; read -r; }
    confirm()  { printf "\n  ${YELLOW}?${RESET} %s [S/n]: " "$1"; read -r R; R="${R:-s}"; [[ "$R" =~ ^[sS]$ ]]; }
}

if [ "$EUID" -ne 0 ]; then
    printf "\n  ${RED}[ERRO]${RESET} Execute como root.\n\n"; exit 1
fi

GN_USER="${GN_USER:-pleb}"
COCKPIT_IP="${HALFIN_BRIDGE_IP:-10.21.21.1}"

# ─────────────────────────────────────────────────────────────────────────────
section "🐳  Docker + Portainer — Halfin Node"
echo ""

printf "  ${BOLD}${CYAN}[1]${RESET}  Instalar Docker + Portainer  ${DIM}(recomendado)${RESET}\n"
printf "  ${BOLD}${CYAN}[2]${RESET}  Instalar apenas Cockpit  ${DIM}(interface web leve)${RESET}\n"
printf "  ${BOLD}${CYAN}[3]${RESET}  Instalar Docker + Portainer + Cockpit\n"
printf "  ${BOLD}[0]${RESET}  Pular — não instalar agora\n"
echo ""
printf "  ${BOLD}[q]${RESET}  Sair\n"
sep
echo ""
printf "  Opção: "
read -r OPT

case "$OPT" in
    0|"")
        step_info "Instalação de Docker pulada"
        exit 0
        ;;
    q|Q)
        exit 0
        ;;
    1|3)
        _instalar_docker=1
        [[ "$OPT" == "3" ]] && _instalar_cockpit=1 || _instalar_cockpit=0
        ;;
    2)
        _instalar_docker=0
        _instalar_cockpit=1
        ;;
    *)
        step_warn "Opção inválida — saindo"
        exit 1
        ;;
esac

# ══════════════════════════════════════════════════════════════════════════════
# Docker + Portainer
# ══════════════════════════════════════════════════════════════════════════════
if [ "${_instalar_docker:-0}" -eq 1 ]; then
    section "1/2 — Docker CE"
    echo ""

    # Verifica se já instalado
    if command -v docker &>/dev/null && systemctl is-active docker &>/dev/null; then
        step_ok "Docker já está instalado e ativo"
        DOCKER_VER=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')
        step_info "Versão: $DOCKER_VER"
    else
        step_info "Adicionando repositório oficial Docker..."

        apt-get update -q
        apt-get install -y ca-certificates curl

        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg \
            -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc

        # Detecta codename do SO
        local_codename=$(. /etc/os-release 2>/dev/null && echo "$VERSION_CODENAME")
        local_arch=$(dpkg --print-architecture)

        tee /etc/apt/sources.list.d/docker.list > /dev/null << DOCKERSRC
deb [arch=${local_arch} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian ${local_codename} stable
DOCKERSRC

        apt-get update -q

        step_info "Instalando Docker CE..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
            docker-ce docker-ce-cli containerd.io \
            docker-buildx-plugin docker-compose-plugin 2>&1 \
            | while IFS= read -r L; do printf "  ${DIM}%s${RESET}\n" "$L"; done

        systemctl enable docker
        systemctl start docker
        step_ok "Docker CE instalado e ativo"
    fi

    # Adiciona usuário pleb ao grupo docker
    if id "$GN_USER" &>/dev/null; then
        usermod -aG docker "$GN_USER" 2>/dev/null || true
        step_ok "Usuário '${GN_USER}' adicionado ao grupo docker"
    fi

    # ── Portainer ─────────────────────────────────────────────────────────────
    echo ""
    step_info "Verificando Portainer..."
    if docker ps -a 2>/dev/null | grep -q portainer; then
        step_ok "Portainer já existe"
        docker ps 2>/dev/null | grep portainer | while IFS= read -r L; do
            printf "  ${DIM}%s${RESET}\n" "$L"
        done
    else
        step_info "Criando volume e container Portainer..."
        docker volume create portainer_data 2>/dev/null || true
        docker run -d \
            -p 8000:8000 -p 9443:9443 \
            --name portainer \
            --restart=always \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v portainer_data:/data \
            portainer/portainer-ce:lts \
            2>&1 | while IFS= read -r L; do printf "  ${DIM}%s${RESET}\n" "$L"; done
        step_ok "Portainer instalado"
    fi

    echo ""
    sep
    step_ok "Docker + Portainer configurados"
    printf "  ${DIM}Portainer HTTPS: ${CYAN}https://${COCKPIT_IP}:9443${RESET}\n"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Cockpit
# ══════════════════════════════════════════════════════════════════════════════
if [ "${_instalar_cockpit:-0}" -eq 1 ]; then
    section "2/2 — Cockpit  ${DIM}(Interface Web de Gerenciamento)${RESET}"
    echo ""

    if systemctl is-active cockpit &>/dev/null; then
        step_ok "Cockpit já está ativo"
    else
        step_info "Instalando Cockpit..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y cockpit 2>&1 \
            | while IFS= read -r L; do printf "  ${DIM}%s${RESET}\n" "$L"; done
        systemctl enable cockpit
        systemctl start cockpit
        step_ok "Cockpit instalado e ativo"
    fi

    echo ""
    sep
    step_ok "Cockpit configurado"
    printf "  ${DIM}Acesse: ${CYAN}http://${COCKPIT_IP}:9090${RESET}\n"
fi

echo ""
sep
step_ok "Instalação concluída"
echo ""
