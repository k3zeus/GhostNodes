#!/bin/bash
#
# ╔══════════════════════════════════════════════════════════════╗
# ║       ghostnode-install.sh — Instala o comando global        ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Uso: sudo bash ghostnode-install.sh
#

set -euo pipefail



# ── Biblioteca modular do projeto ──────────────────────────────
_GN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Sobe um nível se estiver em subpasta (tools/, docker/, etc)
[[ "$_GN_ROOT" == */tools || "$_GN_ROOT" == */docker ]] && _GN_ROOT="$(dirname "$_GN_ROOT")"
source "${_GN_ROOT}/lib/init.sh"

HALFIN_DIR="/home/pleb/halfin"
INSTALL_DIR="/usr/local/bin"
CMD_NAME="ghostnode"
MOTD_SCRIPT="/etc/profile.d/ghostnode-motd.sh"

clear
printf "${BOLD}${CYAN}"
echo ""
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║          ghostnode — Instalação do Comando Global            ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
printf "${RESET}\n"

# ── Verifica root ─────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    step_err "Execute como root: sudo bash ghostnode-install.sh"
    exit 1
fi

# ── Copia o binário principal ─────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/ghostnode"

if [ ! -f "$SRC" ]; then
    # Tenta encontrar em $HALFIN_DIR
    SRC="$HALFIN_DIR/ghostnode"
fi

if [ ! -f "$SRC" ]; then
    step_err "Arquivo 'ghostnode' não encontrado em:"
    printf "  ${DIM}  %s${RESET}\n" "$SCRIPT_DIR" "$HALFIN_DIR"
    exit 1
fi

step_info "Instalando $CMD_NAME em $INSTALL_DIR..."
cp "$SRC" "$INSTALL_DIR/$CMD_NAME"
chmod +x "$INSTALL_DIR/$CMD_NAME"
step_ok "Comando instalado: $INSTALL_DIR/$CMD_NAME"

# ── Instala a biblioteca lib/ ──────────────────────────────────────────────────
step_info "Instalando biblioteca modular lib/..."
LIB_SRC=""
for CANDIDATE in "$SCRIPT_DIR/lib" "$HALFIN_DIR/lib"; do
    [ -d "$CANDIDATE" ] && LIB_SRC="$CANDIDATE" && break
done

if [ -n "$LIB_SRC" ]; then
    mkdir -p "$HALFIN_DIR/lib"
    cp -r "$LIB_SRC/"* "$HALFIN_DIR/lib/"
    chmod +x "$HALFIN_DIR/lib/"*.sh 2>/dev/null || true
    step_ok "Biblioteca instalada em $HALFIN_DIR/lib/"
else
    step_warn "Pasta lib/ não encontrada — scripts podem não funcionar sem ela"
    step_info "Esperada em: $SCRIPT_DIR/lib ou $HALFIN_DIR/lib"
fi


# ── Cria MOTD — usa print_motd() da lib/banner.sh ────────────────────────────
step_info "Configurando MOTD de login..."

cat > "$MOTD_SCRIPT" << 'MOTD'
#!/bin/bash
# ghostnode MOTD — exibido em todo login interativo
[[ $- != *i* ]] && return 0
HALFIN_DIR="/home/pleb/halfin"
[ -f "${HALFIN_DIR}/lib/init.sh" ] && source "${HALFIN_DIR}/lib/init.sh" && print_motd
MOTD

chmod +x "$MOTD_SCRIPT"
step_ok "MOTD instalado: $MOTD_SCRIPT"

# ── Verifica se /usr/local/bin está no PATH ───────────────────────────────────
step_info "Verificando PATH..."
if echo "$PATH" | grep -q "/usr/local/bin"; then
    step_ok "/usr/local/bin está no PATH"
else
    # Adiciona ao /etc/environment se necessário
    if ! grep -q "/usr/local/bin" /etc/environment 2>/dev/null; then
        sed -i 's|PATH="|PATH="/usr/local/bin:|' /etc/environment 2>/dev/null || true
    fi
    step_ok "PATH atualizado em /etc/environment"
fi

# ── Cria link simbólico de conveniência para root ─────────────────────────────
if [ -d /root ]; then
    ln -sf "$INSTALL_DIR/$CMD_NAME" /root/ghostnode 2>/dev/null || true
fi

# ── Cria symlink em /home/pleb se existir ─────────────────────────────────────
if id pleb &>/dev/null && [ -d /home/pleb ]; then
    ln -sf "$INSTALL_DIR/$CMD_NAME" /home/pleb/ghostnode 2>/dev/null || true
    step_ok "Symlink criado em /home/pleb/ghostnode"
fi

# ── Teste rápido ──────────────────────────────────────────────────────────────
echo ""
if command -v ghostnode &>/dev/null; then
    step_ok "Comando 'ghostnode' disponível e funcional"
else
    step_ok "Comando instalado — faça logout/login ou execute: source /etc/profile"
fi

printf "\n"
printf "${BOLD}${GREEN}"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Instalação concluída!"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "${RESET}"
printf "  ${DIM}Para iniciar:${RESET}     ${BOLD}ghostnode${RESET}\n"
printf "  ${DIM}Para ajuda:${RESET}       ${BOLD}ghostnode --help${RESET}\n"
printf "  ${DIM}MOTD no login:${RESET}    ${BOLD}%s${RESET}\n" "$MOTD_SCRIPT"
printf "\n"
