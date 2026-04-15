#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  var/auto.sh — Registro de Pré-Configurações               ║
# ║  Ghost Node Nation                                          ║
# ║  Mapeia hardware/SO → script pre_install.sh do subprojeto  ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Formato de cada entrada:
#   gn_register_preinstall \
#       "<subprojeto>" \
#       "<modelo_hw_regex>" \
#       "<arch>" \
#       "<os_regex>" \
#       "<caminho/pre_install.sh>" \
#       "<descricao>"
#
# Carregado automaticamente por nodenation ao detectar hardware.
# Para adicionar suporte a novo hardware/subprojeto, basta
# adicionar uma nova chamada gn_register_preinstall abaixo.
#
[ -n "${_GN_AUTO_LOADED:-}" ] && return 0
_GN_AUTO_LOADED=1

# ── Tabela interna ────────────────────────────────────────────────────────────
declare -a _GN_AUTO_ENTRIES=()

# gn_register_preinstall — registra uma entrada na tabela
gn_register_preinstall() {
    local SUBPROJECT="$1"   # halfin | satoshi | ...
    local HW_REGEX="$2"     # regex contra GN_HW_MODEL (case-insensitive)
    local ARCH="$3"         # arm64 | x86_64 | armhf | any
    local OS_REGEX="$4"     # regex contra GN_HW_OS (case-insensitive)
    local SCRIPT="$5"       # caminho relativo à raiz GN_ROOT
    local DESC="$6"         # descrição legível para o menu

    _GN_AUTO_ENTRIES+=("${SUBPROJECT}|${HW_REGEX}|${ARCH}|${OS_REGEX}|${SCRIPT}|${DESC}")
}

# ══════════════════════════════════════════════════════════════════════════════
# ENTRADAS REGISTRADAS
# Adicione novas entradas aqui para cada hardware/subprojeto suportado
# ══════════════════════════════════════════════════════════════════════════════

# ── Halfin Node ───────────────────────────────────────────────────────────────

# OrangePi Zero 3 — hardware primário do Halfin Node
gn_register_preinstall \
    "halfin" \
    "Orange Pi Zero 3|OrangePi Zero3|orangepi zero3" \
    "arm64" \
    "Debian.*bookworm|bookworm" \
    "halfin/pre_install.sh" \
    "OrangePi Zero 3 — Debian Bookworm arm64 (configuração oficial)"

# OrangePi Zero 2W — variante menor, mesmo fluxo
gn_register_preinstall \
    "halfin" \
    "Orange Pi Zero 2W|OrangePi Zero2W" \
    "arm64" \
    "Debian.*bookworm|bookworm" \
    "halfin/pre_install.sh" \
    "OrangePi Zero 2W — Debian Bookworm arm64"

# Raspberry Pi 4 — alternativa comum arm64
gn_register_preinstall \
    "halfin" \
    "Raspberry Pi 4|Raspberry Pi Model B Rev" \
    "arm64" \
    "Debian|Raspbian|bookworm|bullseye" \
    "halfin/pre_install_rpi4.sh" \
    "Raspberry Pi 4 — Debian/Raspbian arm64"

# Genérico arm64 Debian/Ubuntu/Armbian (fallback para Halfin)
gn_register_preinstall \
    "halfin" \
    ".*" \
    "arm64" \
    "Debian|Ubuntu|Armbian" \
    "halfin/pre_install.sh" \
    "Debian/Ubuntu arm64 genérico (compatibilidade básica)"

# Genérico qualquer arch + Linux (último fallback — Halfin)
gn_register_preinstall \
    "halfin" \
    ".*" \
    "any" \
    "Debian|Ubuntu|Armbian|Linux" \
    "halfin/pre_install.sh" \
    "Linux genérico — funcionalidade pode ser limitada"

# ── Satoshi Node ──────────────────────────────────────────────────────────────

# x86_64 Debian/Ubuntu — servidor doméstico comum
gn_register_preinstall \
    "satoshi" \
    ".*" \
    "x86_64" \
    "Debian|Ubuntu" \
    "satoshi/pre_install.sh" \
    "x86_64 — Debian/Ubuntu (Full ou Pruned Node)"

# arm64 genérico — SBC qualquer
gn_register_preinstall \
    "satoshi" \
    ".*" \
    "arm64" \
    "Debian|Ubuntu" \
    "satoshi/pre_install.sh" \
    "arm64 — Debian/Ubuntu (Pruned Node recomendado)"

# ══════════════════════════════════════════════════════════════════════════════
# gn_find_preinstall — busca a melhor entrada para o hw/subprojeto atual
# Uso: gn_find_preinstall "halfin"
# Preenche: _GN_FOUND_SCRIPT, _GN_FOUND_DESC
# Retorna: 0 se encontrou, 1 se não encontrou
# ══════════════════════════════════════════════════════════════════════════════
gn_find_preinstall() {
    local TARGET_PROJECT="$1"
    local BASE_DIR="${2:-$GN_ROOT}"
    _GN_FOUND_SCRIPT=""
    _GN_FOUND_DESC=""

    local MODEL="${GN_HW_MODEL:-}"
    local ARCH="${GN_HW_ARCH:-}"
    local OS="${GN_HW_OS:-}"

    for ENTRY in "${_GN_AUTO_ENTRIES[@]}"; do
        IFS='|' read -r E_PROJ E_HW_RE E_ARCH E_OS_RE E_SCRIPT E_DESC <<< "$ENTRY"

        # Filtra por subprojeto
        [ "$E_PROJ" != "$TARGET_PROJECT" ] && continue

        # Verifica arquitetura (any = qualquer)
        if [ "$E_ARCH" != "any" ] && [ "$E_ARCH" != "$ARCH" ]; then
            continue
        fi

        # Verifica modelo (regex case-insensitive)
        if ! echo "$MODEL" | grep -qiE "$E_HW_RE" 2>/dev/null; then
            continue
        fi

        # Verifica OS (regex case-insensitive)
        if ! echo "$OS" | grep -qiE "$E_OS_RE" 2>/dev/null; then
            continue
        fi

        # Match encontrado — usa o primeiro (mais específico primeiro na lista)
        _GN_FOUND_SCRIPT="${BASE_DIR}/${E_SCRIPT}"
        _GN_FOUND_DESC="$E_DESC"
        return 0
    done

    return 1
}
