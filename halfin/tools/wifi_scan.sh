#!/usr/bin/env bash
set -euo pipefail

# ─── Pastas e arquivos ────────────────────────────────────────────────────────

# ── Biblioteca modular do projeto ───────────────────────────────────────────
_GN_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
unset _GN_INIT_LOADED _GN_COLORS_LOADED _GN_UI_LOADED _GN_BANNER_LOADED _GN_LOG_LOADED
# Resolve raiz do subprojeto (sobe até encontrar lib/)
if [ -n "${LIB_DIR:-}" ] && [ -f "${LIB_DIR}/init.sh" ]; then
    source "${LIB_DIR}/init.sh"
else
    _GN_FIND="$_GN_SELF"
    while [ ! -d "${_GN_FIND}/lib" ] && [ "$_GN_FIND" != "/" ]; do
        _GN_FIND="$(dirname "$_GN_FIND")"
    done
    source "${_GN_FIND}/lib/init.sh"
fi

DB_DIR="${GN_DB_DIR}"
DB="$DB_DIR/wifi_scan.db"
LOG="$DB_DIR/log_scan_wifi.log"

if ! command -v sqlite3 >/dev/null 2>&1; then
    echo -e "${RED}[ERRO]${RESET} sqlite3 não encontrado. Instale o pacote sqlite3."
    exit 1
fi

if ! command -v nmcli >/dev/null 2>&1; then
    echo -e "${RED}[ERRO]${RESET} nmcli não encontrado. Instale o NetworkManager."
    exit 1
fi

mkdir -p "$DB_DIR"
chmod 700 "$DB_DIR"
touch "$LOG"

SCAN_TMP="$(mktemp /tmp/scan_output.XXXXXX)"
TMP_SQL="$(mktemp /tmp/scan_wifi_sql.XXXXXX)"

# ─── Cleanup automático em caso de erro ───────────────────────────────────────
trap 'rm -f "$SCAN_TMP" "$TMP_SQL"' EXIT

# ─── Cria tabela SQLite se não existir ────────────────────────────────────────
sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS networks (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  bssid     TEXT UNIQUE,
  ssid      TEXT,
  mode      TEXT,
  channel   INTEGER,
  security  TEXT,
  password  TEXT,
  last_seen DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL

# ─── Executa scan e extrai campos por posição de coluna ───────────────────────
# O nmcli sem -t imprime tabela com colunas de largura fixa.
# Usa saída com delimitador estável para evitar parsing frágil do nmcli
# Formato: BSSID|SSID|MODE|CHAN|SECURITY
nmcli --escape no -t -m multiline -f BSSID,SSID,MODE,CHAN,SECURITY device wifi list \
  2>>"$LOG" \
  | awk -F': ' '
      BEGIN { OFS="|" }
      /^BSSID:/    { bssid=$2; next }
      /^SSID:/     { ssid=$2; if (ssid=="--") ssid=""; next }
      /^MODE:/     { mode=$2; next }
      /^CHAN:/     { chan=$2; next }
      /^SECURITY:/ {
          security=$2
          if (bssid ~ /^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$/) {
              print bssid, ssid, mode, chan, security
          }
          bssid=ssid=mode=chan=security=""
          next
      }
    ' \
  > "$SCAN_TMP"

# Remove carriage returns (WSL / ambientes híbridos)
sed -i 's/\r$//' "$SCAN_TMP"

# ─── Valida conteúdo do scan ──────────────────────────────────────────────────
if [ ! -s "$SCAN_TMP" ]; then
    echo "$(date '+%F %T') - Nenhuma rede encontrada ou nmcli sem saída." >> "$LOG"
    exit 0
fi

# ─── Gera SQL de upsert ───────────────────────────────────────────────────────
echo "BEGIN TRANSACTION;" > "$TMP_SQL"

while IFS='|' read -r bssid ssid mode chan security; do

    # Valida BSSID mínimo
    if [[ ! "$bssid" =~ ^[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}$ ]]; then
        echo "$(date '+%F %T') - BSSID inválido ignorado: '$bssid'" >> "$LOG"
        continue
    fi

    # Escapa aspas simples para SQLite (duplica)
    bssid_s="${bssid//\'/\'\'}"
    ssid_s="${ssid//\'/\'\'}"
    mode_s="${mode//\'/\'\'}"
    security_s="${security//\'/\'\'}"

    # Channel deve ser numérico
    if [[ "$chan" =~ ^[0-9]+$ ]]; then
        chan_sql="$chan"
    else
        chan_sql="NULL"
    fi

    # UPSERT: atualiza se BSSID já existe, insere se não existe
    cat >> "$TMP_SQL" <<ENDSQL
INSERT INTO networks (bssid, ssid, mode, channel, security, last_seen)
  VALUES ('${bssid_s}', '${ssid_s}', '${mode_s}', ${chan_sql}, '${security_s}', CURRENT_TIMESTAMP)
  ON CONFLICT(bssid) DO UPDATE SET
    ssid      = excluded.ssid,
    mode      = excluded.mode,
    channel   = excluded.channel,
    security  = excluded.security,
    last_seen = CURRENT_TIMESTAMP;
ENDSQL

done < "$SCAN_TMP"

echo "COMMIT;" >> "$TMP_SQL"

# ─── Executa SQL no banco ─────────────────────────────────────────────────────
sqlite3 "$DB" < "$TMP_SQL"

# ─── Log final ────────────────────────────────────────────────────────────────
COUNT="$(sqlite3 "$DB" "SELECT COUNT(*) FROM networks;")"
UPDATED="$(wc -l < "$SCAN_TMP")"
echo "$(date '+%F %T') - Scan concluído. Redes processadas: ${UPDATED}. Total no banco: ${COUNT}." >> "$LOG"

exit 0
