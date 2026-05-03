#!/bin/bash
#
# Basic validation for satoshi install flow
#

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

TESTS_RUN=0
TESTS_PASS=0
TESTS_FAIL=0
FAIL_MSGS=()

RED="\e[31m"; GREEN="\e[32m"; CYAN="\e[36m"; BOLD="\e[1m"; DIM="\e[2m"; RESET="\e[0m"

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$expected" = "$actual" ]; then
        TESTS_PASS=$((TESTS_PASS + 1))
        printf "  ${GREEN}✔${RESET} %s\n" "$desc"
    else
        TESTS_FAIL=$((TESTS_FAIL + 1))
        FAIL_MSGS+=("$desc: expected='$expected' actual='$actual'")
        printf "  ${RED}✘${RESET} %s ${DIM}(expected='%s' got='%s')${RESET}\n" "$desc" "$expected" "$actual"
    fi
}

assert_ok() {
    local desc="$1"; shift
    TESTS_RUN=$((TESTS_RUN + 1))
    if "$@" 2>/dev/null; then
        TESTS_PASS=$((TESTS_PASS + 1))
        printf "  ${GREEN}✔${RESET} %s\n" "$desc"
    else
        TESTS_FAIL=$((TESTS_FAIL + 1))
        FAIL_MSGS+=("$desc: command returned non-zero")
        printf "  ${RED}✘${RESET} %s ${DIM}(returned non-zero)${RESET}\n" "$desc"
    fi
}

SATOSHI_INSTALL="${PROJECT_ROOT}/satoshi/install.sh"
SATOSHI_PREINSTALL="${PROJECT_ROOT}/satoshi/pre_install.sh"
AUTO_SH="${PROJECT_ROOT}/var/auto.sh"

printf "\n${BOLD}${CYAN}═══ Test Suite: Satoshi Install Flow ═══${RESET}\n\n"

printf "${BOLD}  Section: Files${RESET}\n"
assert_ok "satoshi/install.sh exists" test -f "$SATOSHI_INSTALL"
assert_ok "satoshi/pre_install.sh exists" test -f "$SATOSHI_PREINSTALL"
assert_ok "var/auto.sh exists" test -f "$AUTO_SH"

printf "\n${BOLD}  Section: Syntax${RESET}\n"
assert_ok "satoshi/install.sh parses" bash -n "$SATOSHI_INSTALL"
assert_ok "satoshi/pre_install.sh parses" bash -n "$SATOSHI_PREINSTALL"

printf "\n${BOLD}  Section: Function Declarations${RESET}\n"
EXPECTED_FUNCTIONS=(
    "download_file"
    "normalize_arch"
    "default_version_for_variant"
    "ensure_bitcoin_user"
    "resolve_release"
    "choose_variant"
    "choose_version"
    "choose_storage_mode"
    "write_rpc_env"
    "create_systemd_service"
    "instalar_bitcoind"
    "configurar_bitcoin"
    "verificar_bitcoin"
    "run_auto_install"
    "main"
)

for func in "${EXPECTED_FUNCTIONS[@]}"; do
    found=$(grep -c "^${func}()" "$SATOSHI_INSTALL" 2>/dev/null || echo "0")
    assert_ok "Function '${func}()' declared" test "$found" -gt 0
done

printf "\n${BOLD}  Section: Config Safeguards${RESET}\n"
assert_ok "satoshi config exports rpc env" grep -q "bitcoin-rpc.env" "$SATOSHI_INSTALL"
assert_ok "satoshi config enables systemd" grep -q "systemctl enable" "$SATOSHI_INSTALL"
assert_ok "satoshi config allows docker bridge RPC" grep -q "rpcallowip=172.17.0.0/16" "$SATOSHI_INSTALL"
assert_ok "satoshi service name is namespaced" grep -q "satoshi-bitcoind.service" "$SATOSHI_INSTALL"

printf "\n${BOLD}  Section: Auto Registry${RESET}\n"
match_script=$(bash -c "
    source '$AUTO_SH'
    GN_HW_MODEL='Orange Pi Zero 3'
    GN_HW_ARCH='arm64'
    GN_HW_OS='Debian GNU/Linux 12 (bookworm)'
    GN_ROOT='${PROJECT_ROOT}'
    gn_find_preinstall 'satoshi' && echo \"\$_GN_FOUND_SCRIPT\"
" 2>/dev/null)
assert_eq "OrangePi Bookworm maps to satoshi/pre_install.sh" "${PROJECT_ROOT}/satoshi/pre_install.sh" "${match_script:-EMPTY}"

echo ""
printf "${BOLD}${CYAN}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
printf "  Tests: ${BOLD}%d${RESET}  Pass: ${GREEN}${BOLD}%d${RESET}  Fail: " "$TESTS_RUN" "$TESTS_PASS"
if [ "$TESTS_FAIL" -gt 0 ]; then
    printf "${RED}${BOLD}%d${RESET}\n" "$TESTS_FAIL"
    echo ""
    for msg in "${FAIL_MSGS[@]}"; do
        printf "  ${RED}  ✘ %s${RESET}\n" "$msg"
    done
else
    printf "${GREEN}${BOLD}0${RESET}\n"
fi
printf "${BOLD}${CYAN}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n"

exit "$TESTS_FAIL"
