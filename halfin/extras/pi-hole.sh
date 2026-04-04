#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  extras/pi-hole.sh — Pi-hole + Unbound DNS                 ║
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

# ── Configurações ─────────────────────────────────────────────────────────────
GN_USER="${GN_USER:-pleb}"
GN_ROOT="${GN_ROOT:-/home/${GN_USER}/nodenation}"
HALFIN_DIR="${HALFIN_DIR:-${GN_ROOT}/halfin}"
UNBOUND_PORT="${PIHOLE_UNBOUND_PORT:-5335}"
PIHOLE_TOML_SRC="${HALFIN_DIR}/Files/pihole/pihole.toml"
UNBOUND_CONF="/etc/unbound/unbound.conf.d/pi-hole.conf"

# ─────────────────────────────────────────────────────────────────────────────
section "🕳   Pi-hole — DNS com Bloqueio de Anúncios"
echo ""

if ! confirm "Instalar Pi-hole + Unbound?"; then
    step_info "Instalação do Pi-hole cancelada"; exit 0
fi

# ── Remove dnsmasq (conflita com Pi-hole) ─────────────────────────────────────
section "1/4 — Preparação"
echo ""
step_info "Removendo dnsmasq (conflita com Pi-hole)..."
DEBIAN_FRONTEND=noninteractive apt-get purge -y dnsmasq 2>/dev/null | \
    while IFS= read -r L; do printf "  ${DIM}%s${RESET}\n" "$L"; done || true
step_ok "dnsmasq removido"

# ── Instala Unbound ───────────────────────────────────────────────────────────
section "2/4 — Unbound (DNS Resolver)"
echo ""
step_info "Instalando unbound..."
DEBIAN_FRONTEND=noninteractive apt-get install -y unbound 2>&1 | \
    while IFS= read -r L; do printf "  ${DIM}%s${RESET}\n" "$L"; done
step_ok "unbound instalado"

step_info "Baixando root hints (servidores raiz DNS)..."
wget -qO /var/lib/unbound/root.hints https://www.internic.net/domain/named.root \
    && step_ok "root.hints atualizado" \
    || step_warn "Falha ao baixar root.hints — usando padrão do pacote"

step_info "Criando configuração unbound para Pi-hole..."
mkdir -p /etc/unbound/unbound.conf.d

tee "$UNBOUND_CONF" > /dev/null << UNBOUNDCFG
# pi-hole.conf — Unbound — Halfin Node — gerado em $(date '+%F %T')
server:
    verbosity: 0
    interface: 127.0.0.1
    port: ${UNBOUND_PORT}
    do-ip4: yes
    do-udp: yes
    do-tcp: yes
    do-ip6: no
    prefer-ip6: no
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: no
    edns-buffer-size: 1232
    prefetch: yes
    num-threads: 1
    so-rcvbuf: 1m
    # Redes privadas protegidas
    private-address: 192.168.0.0/16
    private-address: 169.254.0.0/16
    private-address: 172.16.0.0/12
    private-address: 10.0.0.0/8
    private-address: 10.21.0.0/24
    private-address: 10.21.21.0/24
    private-address: fd00::/8
    private-address: fe80::/10
UNBOUNDCFG

systemctl enable unbound 2>/dev/null || true
systemctl restart unbound \
    && step_ok "unbound rodando na porta ${UNBOUND_PORT}" \
    || step_warn "unbound não iniciou — verifique: journalctl -u unbound"

# Testa resolução via unbound
step_info "Testando resolução DNS via unbound..."
dig pi-hole.net @127.0.0.1 -p "$UNBOUND_PORT" +short 2>/dev/null | head -3 \
    | while IFS= read -r L; do printf "  ${GREEN}%s${RESET}\n" "$L"; done \
    || step_warn "Teste de resolução não respondeu"

# Configura EDNS para dnsmasq/Pi-hole
tee /etc/dnsmasq.d/99-edns.conf > /dev/null << 'EDNS'
edns-packet-max=1232
EDNS

# ── Instala Pi-hole ───────────────────────────────────────────────────────────
section "3/4 — Pi-hole"
echo ""
step_info "Iniciando instalação do Pi-hole..."
echo ""
printf "  ${DIM}Nota: o instalador do Pi-hole é interativo.${RESET}\n"
printf "  ${DIM}Recomendado: selecione 'Custom' como upstream DNS e use 127.0.0.1#${UNBOUND_PORT}${RESET}\n\n"
press_enter

curl -sSL https://install.pi-hole.net | bash || {
    step_err "Instalação do Pi-hole falhou"
    exit 1
}
step_ok "Pi-hole instalado"

# ── Copia configuração personalizada ──────────────────────────────────────────
section "4/4 — Configuração Customizada"
echo ""
if [ -f "$PIHOLE_TOML_SRC" ]; then
    step_info "Aplicando configuração customizada: $PIHOLE_TOML_SRC"
    [ -f /etc/pihole/pihole.toml ] && \
        cp /etc/pihole/pihole.toml "/etc/pihole/pihole.toml.bkp.$(date +%Y%m%d%H%M%S)"
    cp "$PIHOLE_TOML_SRC" /etc/pihole/pihole.toml
    step_ok "pihole.toml aplicado"
else
    step_warn "Arquivo customizado não encontrado: $PIHOLE_TOML_SRC"
    step_info "Usando configuração padrão do instalador Pi-hole"
fi

# ── Configura resolv.conf ─────────────────────────────────────────────────────
step_info "Apontando resolv.conf para Pi-hole (127.0.0.1)..."
echo "nameserver 127.0.0.1" | tee /etc/resolv.conf > /dev/null
step_ok "DNS local configurado"

systemctl restart unbound 2>/dev/null || true

echo ""
sep
step_ok "Pi-hole + Unbound instalados com sucesso"
printf "  ${DIM}Acesse a interface: ${CYAN}http://10.21.21.1/admin${RESET}\n"
echo ""
