#!/usr/bin/env bash
set -euo pipefail
SOURCE=${1:?Uso: $0 <diretorio-swissknife>}
RUN_ID=${RUN_ID:-$(date +%Y%m%dT%H%M%S)-$$}
RUN_ROOT=${RUN_ROOT:-"$HOME/logs/osint/swissknife/$RUN_ID"}
WORK="$RUN_ROOT/work"; MOCK="$WORK/mockbin"; HOME_SANDBOX="$WORK/home"; SYS="$WORK/sys"; NMCONF="$WORK/nmconf"; SUMMARY="$RUN_ROOT/summary.txt"
REAL_IP=$(command -v ip); REAL_SYSTEMCTL=$(command -v systemctl)
mkdir -p "$RUN_ROOT" "$MOCK" "$HOME_SANDBOX" "$SYS"/{testlan,wlx001122334455,ap0}/device "$NMCONF"
printf 'unmanaged-devices=interface-name:ap0\n' > "$NMCONF/99-halfin-ap.conf"
printf 'run_id=%s\n' "$RUN_ID" > "$SUMMARY"
snapshot(){ local n=$1; { "$REAL_SYSTEMCTL" is-active NetworkManager 2>/dev/null || true; "$REAL_IP" -br link; find /etc/NetworkManager/conf.d -type f -maxdepth 1 -exec sha256sum {} + 2>/dev/null | sort || true; find "$SOURCE" -maxdepth 1 -type f -exec sha256sum {} + | sort; } > "$RUN_ROOT/$n.state"; }
snapshot before; cp -a "$SOURCE" "$WORK/swissknife"; SK="$WORK/swissknife"; chmod +x "$SK"/*.sh
mock(){ cat > "$MOCK/$1"; chmod +x "$MOCK/$1"; }
mock sudo <<'EOF'
#!/usr/bin/env bash
printf 'sudo %q\n' "$*" >> "$SWISS_MOCK_LOG"; cmd=${1:-}; shift || true
case "$cmd" in apt|mkdir|tee|systemctl|gpg) cat >/dev/null || true;; timeout|airmon-ng|nmap|nbtscan|arp-scan|p0f|wash) exec "$cmd" "$@";; *) exit 0;; esac
EOF
mock apt <<'EOF'
#!/usr/bin/env bash
printf 'apt %q\n' "$*" >> "$SWISS_MOCK_LOG"
EOF
mock tee <<'EOF'
#!/usr/bin/env bash
append=0; [[ ${1:-} == -a ]] && { append=1; shift; }; target=${1:-}; data=$(cat); printf '%s\n' "$data"; [[ -z "$target" ]] && exit 0; mkdir -p "$(dirname "$target")"; [[ $append == 1 ]] && printf '%s\n' "$data" >> "$target" || printf '%s\n' "$data" > "$target"
EOF
mock timeout <<'EOF'
#!/usr/bin/env bash
while [[ ${1:-} == -* || ${1:-} =~ ^[0-9]+$ ]]; do shift; done; exec "$@"
EOF
mock ip <<'EOF'
#!/usr/bin/env bash
case "$*" in
 *'link show up'*) printf '2: ap0: <UP>\n3: testlan: <UP>\n4: wlx001122334455: <UP>\n';;
 *'link show dev'*) exit 0;;
 *'addr show dev testlan'*) printf '3: testlan    inet 192.0.2.2/24 scope global testlan\n';;
 *'route show default dev ap0'*) printf 'default via 10.0.0.1 dev ap0 metric 10\n';;
 *'route show default dev testlan'*) printf 'default via 192.0.2.1 dev testlan metric 100\n';;
 *'route show dev testlan proto kernel'*) printf '192.0.2.0/24 proto kernel scope link src 192.0.2.2\n';;
 *'route show dev testlan'*) printf '192.0.2.0/24 proto kernel scope link src 192.0.2.2\n';;
 *) exit 0;; esac
EOF
mock iw <<'EOF'
#!/usr/bin/env bash
if [[ ${2:-} == ap0 ]]; then printf 'Interface ap0\n\ttype AP\n'; elif [[ -f "$SWISS_MONITOR_STATE" ]]; then printf 'Interface mon0\n\ttype monitor\n'; else printf 'Interface wlx001122334455\n\ttype managed\n'; fi
EOF
mock airmon-ng <<'EOF'
#!/usr/bin/env bash
if [[ ${1:-} == start ]]; then : > "$SWISS_MONITOR_STATE"; elif [[ ${1:-} == stop ]]; then rm -f "$SWISS_MONITOR_STATE"; fi; exit 0
EOF
mock airodump-ng <<'EOF'
#!/usr/bin/env bash
while (($#)); do [[ $1 == --write ]] && { shift; printf 'BSSID,,,,,Privacy,,Authentication,Power,,,,,ESSID\n00:11:22:33:44:55,,,,WPA2,,PSK,-40,,,,Lab\n' > "$1-01.csv"; exit 0; }; shift; done
EOF
mock wash <<'EOF'
#!/usr/bin/env bash
printf 'WPS mock\n'
EOF
mock p0f <<'EOF'
#!/usr/bin/env bash
while (($#)); do [[ $1 == -o ]] && { shift; printf 'p0f mock\n' > "$1"; exit 0; }; shift; done
EOF
mock nmap <<'EOF'
#!/usr/bin/env bash
xml='<nmaprun><host><address addr="192.0.2.10" addrtype="ipv4"/><ports><port protocol="tcp" portid="22"><state state="open"/></port><port protocol="tcp" portid="80"><state state="open"/></port><port protocol="tcp" portid="443"><state state="open"/></port></ports></host></nmaprun>'
while (($#)); do case "$1" in -oX) shift; printf '%s' "$xml" > "$1";; -oN) shift; printf 'broadcast\n' > "$1";; -oA) shift; printf '%s' "$xml" > "$1.xml"; printf 'deep\n' > "$1.nmap";; esac; shift || true; done; printf 'nmap mock\n'
EOF
for c in arp-scan nbtscan avahi-browse sslscan ssh-audit whatweb; do mock "$c" <<'EOF'
#!/usr/bin/env bash
printf 'mock\n'
EOF
done
export PATH="$MOCK:/usr/bin:/bin" HOME="$HOME_SANDBOX" SWISS_MOCK_LOG="$RUN_ROOT/mocked-privileged-operations.log" SWISS_MONITOR_STATE="$RUN_ROOT/monitor.state" SWISS_LOG_ROOT="$HOME_SANDBOX/logs/osint/swissknife" SWISS_SYS_CLASS_NET="$SYS" HALFIN_NM_CONF_DIR="$NMCONF" SWISSKNIFE_APPLY=1 IFACE_WLAN=wlx001122334455
bash "$SK/install.sh"; test -s "$SWISS_LOG_ROOT/install"/*/install.log
REPORT="$RUN_ROOT/report"; mkdir -p "$REPORT"
for f in 01-wireless-survey.sh 02-passive-listen.sh 03-discovery.sh 04-deep-scan.sh 05-service-checks.sh; do bash "$SK/$f" "$REPORT"; done
python3 "$SK/06-generate-report.py" "$REPORT"
for f in interface-selection.txt wifi-01.csv wps.txt p0f.log broadcast.nmap netbios.txt arp_scan.txt discovery.xml live_hosts.txt deep.xml deep.console services_targets.txt report.md report.html services/tls_192.0.2.10_443.txt services/ssh_192.0.2.10.txt services/web_192.0.2.10_80.txt; do test -s "$REPORT/$f"; done
grep -qx 'interface=testlan' "$REPORT/interface-selection.txt"
bash "$SK/audit-all.sh"; test -n "$(find "$SWISS_LOG_ROOT/reports" -name report.md -size +0 -print -quit)"
bash "$SK/serve-reports.sh"; test -s "$SWISS_LOG_ROOT/serve/serve-instructions.txt"
snapshot after; diff -u "$RUN_ROOT/before.state" "$RUN_ROOT/after.state" > "$RUN_ROOT/state.diff" || { cat "$RUN_ROOT/state.diff" >&2; exit 1; }
printf 'PASS\nreport_root=%s\n' "$RUN_ROOT" >> "$SUMMARY"; cat "$SUMMARY"