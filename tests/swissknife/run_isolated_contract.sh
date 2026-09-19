#!/usr/bin/env bash
# Executa o Swissknife somente em cópia isolada e com comandos privilegiados simulados.
# Nenhuma instalação, alteração de rede ou escrita em /etc é permitida.
set -euo pipefail

SOURCE=${1:?Uso: $0 <diretorio-swissknife>}
RUN_ID=${RUN_ID:-$(date +%Y%m%dT%H%M%S)-$$}
RUN_ROOT=${RUN_ROOT:-"$HOME/logs/osint/swissknife/$RUN_ID"}
WORK="$RUN_ROOT/work"
MOCK="$WORK/mockbin"
HOME_SANDBOX="$WORK/home"
SUMMARY="$RUN_ROOT/summary.txt"
REAL_IP=$(command -v ip)
REAL_SYSTEMCTL=$(command -v systemctl)
INSTALL_LOG=/tmp/swissknife-install.log

mkdir -p "$RUN_ROOT" "$WORK" "$MOCK" "$HOME_SANDBOX"
[[ ! -e "$INSTALL_LOG" ]] || { echo "Log temporário já existe: $INSTALL_LOG" >&2; exit 2; }
printf 'run_id=%s\nsource=%s\n' "$RUN_ID" "$SOURCE" > "$SUMMARY"

snapshot() {
  local name=$1
  local out="$RUN_ROOT/${name}.state"
  {
    uname -m
    "$REAL_SYSTEMCTL" is-active NetworkManager 2>/dev/null || true
    "$REAL_IP" -br link
    find /etc/NetworkManager/conf.d -maxdepth 1 -type f -exec sha256sum {} + 2>/dev/null | sort || true
    find "$SOURCE" -maxdepth 1 -type f -exec sha256sum {} + | sort
  } > "$out"
}

snapshot before
cp -a "$SOURCE" "$WORK/swissknife"
SK="$WORK/swissknife"
chmod +x "$SK"/*.sh

write_mock() {
  local name=$1
  cat > "$MOCK/$name"
  chmod +x "$MOCK/$name"
}

write_mock sudo <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'sudo %q\n' "$*" >> "$SWISS_MOCK_LOG"
cmd=${1:-}; shift || true
case "$cmd" in
  apt|mkdir|tee|systemctl|gpg) cat >/dev/null || true; exit 0 ;;
  timeout|airmon-ng|nmap|nbtscan|arp-scan|p0f|wash) exec "$cmd" "$@" ;;
  *) exit 0 ;;
esac
EOF
write_mock apt <<'EOF'
#!/usr/bin/env bash
printf 'apt %q\n' "$*" >> "$SWISS_MOCK_LOG"
exit 0
EOF
write_mock systemctl <<'EOF'
#!/usr/bin/env bash
printf 'systemctl %q\n' "$*" >> "$SWISS_MOCK_LOG"
exit 0
EOF
write_mock curl <<'EOF'
#!/usr/bin/env bash
printf 'curl %q\n' "$*" >> "$SWISS_MOCK_LOG"
printf 'mock-download\n'
EOF
write_mock tee <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
append=0
[[ ${1:-} == -a ]] && { append=1; shift; }
target=${1:-}
data=$(cat)
printf '%s\n' "$data"
[[ -n "$target" ]] || exit 0
mkdir -p "$(dirname "$target")"
if [[ $append -eq 1 ]]; then printf '%s\n' "$data" >> "$target"; else printf '%s\n' "$data" > "$target"; fi
EOF
write_mock timeout <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
while [[ ${1:-} == -* || ${1:-} =~ ^[0-9]+$ ]]; do shift; done
exec "$@"
EOF
write_mock airmon-ng <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'airmon-ng %q\n' "$*" >> "$SWISS_MOCK_LOG"
[[ ${1:-} == start ]] && : > "$SWISS_MONITOR_STATE"
[[ ${1:-} == stop ]] && rm -f "$SWISS_MONITOR_STATE"
EOF
write_mock iw <<'EOF'
#!/usr/bin/env bash
if [[ -f "$SWISS_MONITOR_STATE" ]]; then
  printf 'phy#0\n\tInterface mon0\n\t\ttype monitor\n'
else
  printf 'phy#0\n\tInterface wlx001122334455\n\t\ttype managed\n'
fi
EOF
write_mock airodump-ng <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
while (($#)); do
  if [[ $1 == --write ]]; then shift; printf 'BSSID, First time seen, Last time seen, channel, Speed, Privacy, Cipher, Authentication, Power, # beacons, # IV, LAN IP, ID-length, ESSID, Key\n00:11:22:33:44:55,,,,6,,WPA2,,PSK,-40,,,,Lab\n' > "$1-01.csv"; exit 0; fi
  shift
done
EOF
write_mock wash <<'EOF'
#!/usr/bin/env bash
printf 'BSSID               Ch  dBm  WPS\n00:11:22:33:44:55  6   -40  1.0\n'
EOF
write_mock p0f <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
while (($#)); do [[ $1 == -o ]] && { shift; printf 'mock p0f\n' > "$1"; exit 0; }; shift; done
EOF
write_mock ip <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == *' route'* ]]; then printf '192.0.2.0/24 proto kernel scope link src 192.0.2.2 dev testlan\n'; else printf '2: testlan    inet 192.0.2.2/24 scope global testlan\n'; fi
EOF
write_mock arp-scan <<'EOF'
#!/usr/bin/env bash
printf '192.0.2.10\t00:11:22:33:44:55\tMock Device\n'
EOF
write_mock nbtscan <<'EOF'
#!/usr/bin/env bash
printf '192.0.2.10 MOCKHOST <00>\n'
EOF
write_mock avahi-browse <<'EOF'
#!/usr/bin/env bash
printf '= testlan IPv4 mock-service _http._tcp local\n'
EOF
write_mock nmap <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
xml='<nmaprun><host><address addr="192.0.2.10" addrtype="ipv4"/><address addr="00:11:22:33:44:55" addrtype="mac" vendor="Mock"/><ports><port protocol="tcp" portid="22"><state state="open"/><service name="ssh" product="OpenSSH" version="9"/></port><port protocol="tcp" portid="80"><state state="open"/><service name="http" product="mock" version="1"/></port><port protocol="tcp" portid="443"><state state="open"/><service name="https" product="mock" version="1"/></port></ports></host></nmaprun>'
while (($#)); do
  case "$1" in
    -oX) shift; printf '%s\n' "$xml" > "$1" ;;
    -oN) shift; printf 'mock broadcast discovery\n' > "$1" ;;
    -oA) shift; printf '%s\n' "$xml" > "$1.xml"; printf 'mock deep scan\n' > "$1.nmap"; printf 'mock\n' > "$1.gnmap" ;;
  esac
  shift || true
done
printf 'mock nmap\n'
EOF
write_mock sslscan <<'EOF'
#!/usr/bin/env bash
printf 'mock tls\n'
EOF
write_mock ssh-audit <<'EOF'
#!/usr/bin/env bash
printf 'mock ssh audit\n'
EOF
write_mock whatweb <<'EOF'
#!/usr/bin/env bash
printf 'mock web\n'
EOF
write_mock caddy <<'EOF'
#!/usr/bin/env bash
[[ ${1:-} == hash-password ]] && printf '$2a$mock-hash\n'
EOF

export PATH="$MOCK:/usr/bin:/bin"
export HOME="$HOME_SANDBOX"
export SWISS_MOCK_LOG="$RUN_ROOT/mocked-privileged-operations.log"
export SWISS_MONITOR_STATE="$RUN_ROOT/monitor.state"
export IFACE_LAN=testlan
export IFACE_WLAN=wlx001122334455
export SCAN_RANGE=192.0.2.0/24
export VULN=0

# O pacote entregue permanece achatado: registra a falha do orquestrador original.
set +e
bash "$SK/audit-all.sh" > "$RUN_ROOT/flattened-layout.stdout" 2> "$RUN_ROOT/flattened-layout.stderr"
flattened_rc=$?
set -e
grep -q '/services/01-wireless-survey.sh' "$RUN_ROOT/flattened-layout.stderr" || { echo 'ERRO: falha de layout não foi registrada' >&2; exit 1; }
printf 'flattened_layout_exit=%s (falso sucesso conhecido)\n' "$flattened_rc" >> "$SUMMARY"

# Adaptador de teste: somente na cópia temporária, para testar o fluxo previsto pelo autor.
mkdir "$SK/services"
for phase in 01-wireless-survey.sh 02-passive-listen.sh 03-discovery.sh 04-deep-scan.sh 05-service-checks.sh 06-generate-report.py; do ln -s "../$phase" "$SK/services/$phase"; done

bash "$SK/install.sh" > "$RUN_ROOT/install.stdout" 2> "$RUN_ROOT/install.stderr"
mv "$INSTALL_LOG" "$RUN_ROOT/install.log"
test -d "$HOME/swissknife/reports"
test -d "$HOME/swissknife/captures"

REPORT="$RUN_ROOT/individual-report"
mkdir -p "$REPORT"
for phase in 01-wireless-survey.sh 02-passive-listen.sh 03-discovery.sh 04-deep-scan.sh 05-service-checks.sh; do "$SK/$phase" "$REPORT" > "$RUN_ROOT/${phase}.stdout" 2> "$RUN_ROOT/${phase}.stderr"; done
python3 "$SK/06-generate-report.py" "$REPORT" > "$RUN_ROOT/06-generate-report.stdout" 2> "$RUN_ROOT/06-generate-report.stderr"
for file in wifi-01.csv wps.txt p0f.log broadcast.nmap netbios.txt mdns.txt arp_scan.txt discovery.xml live_hosts.txt deep.xml deep.console services_targets.txt report.md report.html services/tls_192.0.2.10_443.txt services/ssh_192.0.2.10.txt services/web_192.0.2.10_80.txt; do test -s "$REPORT/$file"; done

"$SK/audit-all.sh" > "$RUN_ROOT/audit-all.stdout" 2> "$RUN_ROOT/audit-all.stderr"
latest=$(find "$HOME/swissknife/reports" -mindepth 1 -maxdepth 1 -type d | sort | tail -n1)
test -s "$latest/report.md"
test -s "$latest/report.html"
printf '192.0.2.2\n' | bash "$SK/serve-reports.sh" > "$RUN_ROOT/serve-reports.stdout" 2> "$RUN_ROOT/serve-reports.stderr"

snapshot after
diff -u "$RUN_ROOT/before.state" "$RUN_ROOT/after.state" > "$RUN_ROOT/state.diff" || { cat "$RUN_ROOT/state.diff" >&2; exit 1; }
printf 'PASS\n' >> "$SUMMARY"
printf 'report_root=%s\n' "$RUN_ROOT" >> "$SUMMARY"
cat "$SUMMARY"
