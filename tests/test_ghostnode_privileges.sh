#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NODE="$ROOT/ghostnode"
fail() { echo "FAIL: $*" >&2; exit 1; }
need() { grep -Fq "$1" "$NODE" || fail "$2"; }
bash -n "$NODE"
need "ensure_sudo()" "sudo helper missing"
need "sudo -v ||" "sudo prompt missing"
need "wifi_scan.sh" "2.1 route missing"
need "GN_WIFI_USE_SUDO=1 run_script" "Wi-Fi routes lack sudo"
need "sudo_run ip link set" "2.3 repair lacks sudo"
need "sudo_run systemctl start hostapd" "2.3 hostapd repair lacks sudo"
need "run_root_script" "3.2 lacks sudo"
need "sudo_run docker compose" "3.3 lacks sudo"
need "sudo_run bash" "4.2 lacks sudo"
need "sudo_run journalctl" "4.4 lacks sudo"
need "sudo_run systemctl start" "4.5 lacks sudo"
need "sudo_run systemctl stop" "4.6 lacks sudo"
need "sudo_run systemctl reboot" "5 lacks sudo"
need "sudo_run systemctl poweroff" "6 lacks sudo"
echo "OK: menu privilege contract"
