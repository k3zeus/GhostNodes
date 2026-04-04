#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  extras/fail2ban.sh — Instalação e Configuração Fail2ban   ║
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
}

if [ "$EUID" -ne 0 ]; then
    printf "\n  ${RED}[ERRO]${RESET} Execute como root.\n\n"; exit 1
fi

# ── Configurações ─────────────────────────────────────────────────────────────
SSH_PORT="${FAIL2BAN_SSH_PORT:-22}"
MAX_RETRY="${FAIL2BAN_MAXRETRY:-4}"
BAN_TIME="${FAIL2BAN_BANTIME:-1w}"
JAIL_LOCAL="/etc/fail2ban/jail.local"

# ─────────────────────────────────────────────────────────────────────────────
section "🔒  Fail2ban — Proteção contra Brute-Force"
echo ""

# ── Instalação ────────────────────────────────────────────────────────────────
if dpkg -l fail2ban 2>/dev/null | grep -q "^ii"; then
    step_ok "fail2ban já instalado"
else
    step_info "Instalando fail2ban..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y fail2ban 2>&1 \
        | while IFS= read -r L; do printf "  ${DIM}%s${RESET}\n" "$L"; done
    step_ok "fail2ban instalado"
fi

# ── Copia jail.conf → jail.local (preserva atualizações futuras) ──────────────
if [ ! -f "$JAIL_LOCAL" ]; then
    step_info "Criando ${JAIL_LOCAL}..."
    cp /etc/fail2ban/jail.conf "$JAIL_LOCAL"
    step_ok "jail.local criado a partir de jail.conf"
else
    step_ok "jail.local já existe — mantendo configurações"
fi

# ── Configura bloco [sshd] no jail.local ─────────────────────────────────────
step_info "Configurando proteção SSH (porta ${SSH_PORT}, max ${MAX_RETRY} tentativas, ban ${BAN_TIME})..."

# Remove bloco sshd existente para reescrever limpo
sed -i '/^\[sshd\]/,/^\[/{/^\[sshd\]/!{/^\[/!d}}' "$JAIL_LOCAL" 2>/dev/null || true

# Adiciona configuração no final do arquivo
tee -a "$JAIL_LOCAL" > /dev/null << SSHD_CONF

# ── Halfin Node — SSH Protection — gerado em $(date '+%F %T') ─────────────────
[sshd]
enabled  = true
port     = ${SSH_PORT}
maxretry = ${MAX_RETRY}
bantime  = ${BAN_TIME}
findtime = 10m
SSHD_CONF

step_ok "Bloco [sshd] configurado"

# ── Habilita e reinicia ───────────────────────────────────────────────────────
systemctl enable fail2ban 2>/dev/null || true
systemctl restart fail2ban 2>/dev/null \
    && step_ok "fail2ban ativo e protegendo SSH" \
    || step_warn "Reinício falhou — verifique: journalctl -u fail2ban"

echo ""
sep
printf "  ${BOLD}Status fail2ban:${RESET}\n\n"
fail2ban-client status sshd 2>/dev/null \
    | while IFS= read -r L; do printf "  ${DIM}%s${RESET}\n" "$L"; done \
    || step_warn "fail2ban-client não respondeu ainda — aguarde alguns segundos"
echo ""
step_ok "Fail2ban configurado com sucesso"
