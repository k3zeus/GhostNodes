#!/usr/bin/env bash
# Shared Bitcoin node engine. A base-project profile supplies the policy.
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SELF_DIR")"
PROFILE_NAME=""
ACTION="plan"

usage() {
    cat <<'EOF'
Uso: bitcoin-node.sh --profile <nome> [--plan|--verify-artifact|--install|--status]
EOF
}
json_get() {
    local file="$1" path="$2"
    python3 - "$file" "$path" <<'PY'
import json, sys
value = json.load(open(sys.argv[1], encoding='utf-8'))
for part in sys.argv[2].split('.'):
    value = value[part]
print(value)
PY
}
while [ "$#" -gt 0 ]; do
    case "$1" in
        --profile) PROFILE_NAME="${2:-}"; shift 2 ;;
        --plan) ACTION="plan"; shift ;;
        --verify-artifact) ACTION="verify"; shift ;;
        --install) ACTION="install"; shift ;;
        --status) ACTION="status"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
[ -n "$PROFILE_NAME" ] || { usage >&2; exit 2; }
PROFILE="$ROOT/bitcoin/profiles/${PROFILE_NAME}.json"
[ -r "$PROFILE" ] || { echo "Perfil inexistente: $PROFILE_NAME" >&2; exit 2; }
IMPLEMENTATION="$(json_get "$PROFILE" implementation)"
MANIFEST="$ROOT/bitcoin/manifests/$(json_get "$PROFILE" manifest)"
[ -r "$MANIFEST" ] || { echo "Manifesto inexistente: $MANIFEST" >&2; exit 2; }
VERSION="$(json_get "$MANIFEST" version)"
MODE="$(json_get "$PROFILE" mode)"
MAX_PRUNE_GIB="$(json_get "$PROFILE" max_prune_gib)"
MIN_PRUNE_GIB="$(json_get "$PROFILE" min_prune_gib)"
DATA_DIR="$(json_get "$PROFILE" data_dir)"
CONFIG_FILE="$(json_get "$PROFILE" config_file)"
SERVICE="$(json_get "$PROFILE" service)"

detect_arch() {
    local raw="${GN_BITCOIN_ARCH:-$(uname -m)}"
    case "$raw" in
        aarch64|arm64) echo arm64 ;;
        x86_64|amd64) echo amd64 ;;
        *) echo "Arquitetura não suportada pelo perfil: $raw" >&2; return 1 ;;
    esac
}
parent_with_space() {
    local p="$1"
    while [ ! -e "$p" ] && [ "$p" != / ]; do p="$(dirname "$p")"; done
    printf '%s\n' "$p"
}
free_gib() {
    if [ -n "${GN_BITCOIN_FREE_GIB:-}" ]; then printf '%s\n' "$GN_BITCOIN_FREE_GIB"; return; fi
    local probe; probe="$(parent_with_space "$DATA_DIR")"
    df -Pk "$probe" | awk 'NR==2 {print int($4/1024/1024)}'
}
storage_source() {
    local probe
    probe="$(parent_with_space "$DATA_DIR")"
    findmnt -n -o SOURCE -T "$probe" 2>/dev/null || df -Pk "$probe" | awk 'NR==2 {print $1}'
}
uses_microsd() {
    [ "${GN_BITCOIN_STORAGE_CLASS:-}" = "microsd" ] && return 0
    [ "${GN_BITCOIN_STORAGE_CLASS:-}" = "durable" ] && return 1
    local source parent
    source="$(storage_source)"
    case "$source" in /dev/mmcblk*) return 0 ;; esac
    parent="$(lsblk -no PKNAME "$source" 2>/dev/null | head -1 || true)"
    case "$parent" in mmcblk*) return 0 ;; esac
    return 1
}
calculate_prune() {
    local free="$1"
    local candidate=$((free / 3))
    [ "$candidate" -gt "$MAX_PRUNE_GIB" ] && candidate="$MAX_PRUNE_GIB"
    [ "$candidate" -ge "$MIN_PRUNE_GIB" ] || return 1
    printf '%s\n' "$candidate"
}
ARCH="$(detect_arch)"
FILENAME="$(json_get "$MANIFEST" "artifacts.${ARCH}.filename")"
URL="$(json_get "$MANIFEST" "artifacts.${ARCH}.url")"
SHA256="$(json_get "$MANIFEST" "artifacts.${ARCH}.sha256")"
FREE_GIB="$(free_gib)"
PRUNE_GIB="$(calculate_prune "$FREE_GIB" || true)"

show_plan() {
    echo "Perfil: $PROFILE_NAME"
    echo "Implementação: $IMPLEMENTATION"
    echo "Versão: $VERSION"
    echo "Arquitetura: $ARCH"
    echo "Modo: $MODE"
    echo "Espaço livre no filesystem de dados: ${FREE_GIB} GiB"
    echo "Filesystem de dados: $(storage_source)"
    if [ -z "$PRUNE_GIB" ]; then
        echo "Resultado: RECUSAR — menos de ${MIN_PRUNE_GIB} GiB podem ser reservados para prune mantendo 2/3 livres"
        return 1
    fi
    echo "Prune calculado: ${PRUNE_GIB} GiB ($((PRUNE_GIB * 1024)) MiB)"
    echo "Dados: $DATA_DIR"
    echo "Artefato: $FILENAME"
    echo "URL: $URL"
    echo "SHA256: $SHA256"
    if uses_microsd; then
        echo "Mídia: MicroSD detectado — instalação permitida com confirmação adicional de risco."
    fi
}
status() {
    if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet "$SERVICE"; then
        echo "Estado: ativo ($SERVICE)"
    else
        echo "Estado: não instalado ou inativo ($SERVICE)"
        return 1
    fi
}
verify_artifact() {
    command -v curl >/dev/null || { echo 'curl é obrigatório.' >&2; return 1; }
    command -v sha256sum >/dev/null || { echo 'sha256sum é obrigatório.' >&2; return 1; }
    local tmp expected actual
    tmp="$(mktemp -d /tmp/ghostnodes-bitcoin-verify.XXXXXX)"
    trap 'rm -rf "$tmp"' RETURN
    curl -fsSL --retry 3 -o "$tmp/$FILENAME" "$URL"
    curl -fsSL --retry 3 -o "$tmp/SHA256SUMS" "$(json_get "$MANIFEST" sha256sums_url)"
    curl -fsSL --retry 3 -o "$tmp/SHA256SUMS.asc" "$(json_get "$MANIFEST" sha256sums_signature_url)"
    expected="$(awk -v n="$FILENAME" '$2==n || $2=="*"n {print $1}' "$tmp/SHA256SUMS")"
    [ "$expected" = "$SHA256" ] || { echo 'SHA256SUMS oficial diverge do manifesto fixado.' >&2; return 1; }
    actual="$(sha256sum "$tmp/$FILENAME" | awk '{print $1}')"
    [ "$actual" = "$SHA256" ] || { echo 'Checksum do artefato inválido.' >&2; return 1; }
    tar -tzf "$tmp/$FILENAME" | grep -E '(^|/)bin/bitcoind$' > /dev/null || { echo 'Tarball sem bitcoind.' >&2; return 1; }
    tar -tzf "$tmp/$FILENAME" | grep -E '(^|/)bin/bitcoin-cli$' > /dev/null || { echo 'Tarball sem bitcoin-cli.' >&2; return 1; }
    [ -s "$tmp/SHA256SUMS.asc" ] || { echo 'Assinatura de checksums ausente.' >&2; return 1; }
    echo "Artefato verificado e extraível: $FILENAME"
}

install_node() {
    [ "$(id -u)" -eq 0 ] || { echo 'A instalação requer sudo.' >&2; return 1; }
    show_plan
    if uses_microsd; then
        cat <<'EOF'
AVISO DE ARMAZENAMENTO: os dados do Bitcoin Core serão gravados no MicroSD.
O prune limita blocos retidos, mas a sincronização e o chainstate continuam
com escrita intensa. Para maior vida útil, use um SSD para o diretório de dados.
Digite MICROSD para confirmar que entende e deseja continuar:
EOF
        read -r media_answer
        [ "$media_answer" = "MICROSD" ] || { echo 'Instalação cancelada: risco de MicroSD não confirmado.'; return 0; }
    fi
    printf 'Confirmar instalação do Bitcoin Core prunado conforme o plano? [s/N]: '
    read -r answer
    [ "$answer" = s ] || [ "$answer" = S ] || { echo 'Instalação cancelada.'; return 0; }
    command -v curl >/dev/null || { echo 'curl é obrigatório.' >&2; return 1; }
    command -v sha256sum >/dev/null || { echo 'sha256sum é obrigatório.' >&2; return 1; }
    local tmp expected actual target extracted bindir
    tmp="$(mktemp -d /tmp/ghostnodes-bitcoin.XXXXXX)"
    trap 'rm -rf "$tmp"' RETURN
    curl -fsSL --retry 3 -o "$tmp/$FILENAME" "$URL"
    curl -fsSL --retry 3 -o "$tmp/SHA256SUMS" "$(json_get "$MANIFEST" sha256sums_url)"
    expected="$(awk -v n="$FILENAME" '$2==n || $2=="*"n {print $1}' "$tmp/SHA256SUMS")"
    [ "$expected" = "$SHA256" ] || { echo 'SHA256SUMS oficial diverge do manifesto fixado.' >&2; return 1; }
    actual="$(sha256sum "$tmp/$FILENAME" | awk '{print $1}')"
    [ "$actual" = "$SHA256" ] || { echo 'Checksum do artefato inválido.' >&2; return 1; }
    tar -xzf "$tmp/$FILENAME" -C "$tmp"
    extracted="$(tar -tzf "$tmp/$FILENAME" | awk -F/ 'NR==1 {print $1}')"
    bindir="$tmp/$extracted/bin"
    [ -x "$bindir/bitcoind" ] && [ -x "$bindir/bitcoin-cli" ] || { echo 'Tarball sem binários esperados.' >&2; return 1; }
    target="/opt/ghostnodes/bitcoin/$IMPLEMENTATION/$VERSION"
    install -d -m 0755 "$target/bin" "$(dirname "$DATA_DIR")" "$(dirname "$CONFIG_FILE")"
    install -m 0755 "$bindir/bitcoind" "$bindir/bitcoin-cli" "$target/bin/"
    id bitcoin >/dev/null 2>&1 || adduser --system --group --home /nonexistent bitcoin
    install -d -o bitcoin -g bitcoin -m 0750 "$DATA_DIR"
    local rpcpass; rpcpass="$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')"
    umask 077
    cat > "$CONFIG_FILE" <<EOF
server=1
prune=$((PRUNE_GIB * 1024))
txindex=0
disablewallet=1
persistmempool=0
debug=0
shrinkdebugfile=1
printtoconsole=0
listen=1
rpcbind=127.0.0.1
rpcallowip=127.0.0.1
rpcuser=halfin
rpcpassword=$rpcpass
datadir=$DATA_DIR
EOF
    chown bitcoin:bitcoin "$CONFIG_FILE"; chmod 0640 "$CONFIG_FILE"
    cat > "/etc/systemd/system/$SERVICE" <<EOF
[Unit]
Description=GhostNodes Bitcoin Core ($PROFILE_NAME)
After=network-online.target
Wants=network-online.target
[Service]
User=bitcoin
Group=bitcoin
ExecStart=$target/bin/bitcoind -conf=$CONFIG_FILE
ExecStop=$target/bin/bitcoin-cli -conf=$CONFIG_FILE stop
Restart=on-failure
RestartSec=15
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now "$SERVICE"
    echo "Instalação concluída: $SERVICE"
}
case "$ACTION" in
    plan) show_plan ;;
    verify) verify_artifact ;;
    status) status ;;
    install) install_node ;;
esac