#!/usr/bin/env bash
#
# Contract and menu coverage for nodenation bootstrap logic.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NODENATION_SCRIPT="${PROJECT_ROOT}/nodenation"

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
    if "$@" >/dev/null 2>&1; then
        TESTS_PASS=$((TESTS_PASS + 1))
        printf "  ${GREEN}✔${RESET} %s\n" "$desc"
    else
        TESTS_FAIL=$((TESTS_FAIL + 1))
        FAIL_MSGS+=("$desc: command returned non-zero")
        printf "  ${RED}✘${RESET} %s ${DIM}(returned non-zero)${RESET}\n" "$desc"
    fi
}

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$haystack" == *"$needle"* ]]; then
        TESTS_PASS=$((TESTS_PASS + 1))
        printf "  ${GREEN}✔${RESET} %s\n" "$desc"
    else
        TESTS_FAIL=$((TESTS_FAIL + 1))
        FAIL_MSGS+=("$desc: missing '$needle'")
        printf "  ${RED}✘${RESET} %s ${DIM}(missing '%s')${RESET}\n" "$desc" "$needle"
    fi
}

TEST_TMP="$(mktemp -d)"
MOCK_BIN="${TEST_TMP}/mock-bin"
STAGING_DIR="${TEST_TMP}/staging"
GN_ROOT_TEST="${TEST_TMP}/root"
mkdir -p "$MOCK_BIN" "${STAGING_DIR}/halfin/lib" "${STAGING_DIR}/satoshi" "${GN_ROOT_TEST}" "${TEST_TMP}/var"

cleanup() {
    rm -rf "$TEST_TMP"
}
trap cleanup EXIT

cat > "${STAGING_DIR}/halfin/lib/init.sh" <<'EOF'
#!/usr/bin/env bash
:
EOF
chmod +x "${STAGING_DIR}/halfin/lib/init.sh"

cat > "${MOCK_BIN}/bitcoin-cli" <<'EOF'
#!/usr/bin/env bash
echo '{"chain":"main","blocks":123}'
EOF
chmod +x "${MOCK_BIN}/bitcoin-cli"

PATH="${MOCK_BIN}:$PATH"

source "$NODENATION_SCRIPT"

banner_root() { :; }
section() { :; }
sep() { :; }
sep_thin() { :; }
press_enter() { :; }
press_enter_or_back() { :; }
step_ok() { :; }
step_warn() { :; }
step_err() { :; }
step_info() { :; }
clear() { :; }
sleep() { :; }

GN_TMP_DIR="$STAGING_DIR"
GN_TMP_VAR="${TEST_TMP}/var"
GN_TMP_HW="${GN_TMP_VAR}/hardware.env"
GN_ROOT="$GN_ROOT_TEST"
GN_USER="pleb"
GN_HW_ARCH="x86_64"
GN_HW_MODEL="Test Rig"
GN_HW_RAM_GB=4
GN_HW_DISK_GB=2048
GN_HW_CPU_CORES=4
GN_HW_OS="Debian GNU/Linux 12 (bookworm)"
mkdir -p "$GN_TMP_VAR"

printf "\n${BOLD}${CYAN}═══ Test Suite: nodenation bootstrap/menu ═══${RESET}\n\n"

printf "${BOLD}  Section: Syntax and Source Safety${RESET}\n"
assert_ok "nodenation parses" bash -n "$NODENATION_SCRIPT"
assert_ok "nodenation exposes main()" grep -q '^main()' "$NODENATION_SCRIPT"
assert_ok "nodenation guards direct execution" grep -q '_GN_EXECUTED_DIRECTLY' "$NODENATION_SCRIPT"
assert_ok "nodenation supports CI non-tty bootstrap override" grep -q 'GN_BOOTSTRAP_ALLOW_NONTTY' "$NODENATION_SCRIPT"
assert_ok "nodenation auto-elevates through sudo when not root" grep -q 'exec sudo -E bash "\$0" "\$@"' "$NODENATION_SCRIPT"

printf "\n${BOLD}  Section: Satoshi automatic selection${RESET}\n"
satoshi_prepare_auto_selection
assert_eq "auto uses core by default" "core" "$SATOSHI_VARIANT"
assert_eq "auto uses default core version" "29.1" "$SATOSHI_VERSION"
assert_eq "auto selects full at 1TB+" "full" "$GN_INSTALL_MODE"

GN_HW_DISK_GB=256
satoshi_prepare_auto_selection
assert_eq "auto selects pruned below 1TB" "pruned" "$GN_INSTALL_MODE"
assert_eq "auto prune defaults to 30GB" "30" "$SATOSHI_PRUNE_GB"

printf "\n${BOLD}  Section: Satoshi manual selection${RESET}\n"
GN_HW_DISK_GB=900
satoshi_prepare_manual_selection <<< $'2\n29.3.knots20260210\n1\ns\n'
assert_eq "manual keeps knots variant" "knots" "$SATOSHI_VARIANT"
assert_eq "manual accepts custom knots version" "29.3.knots20260210" "$SATOSHI_VERSION"
assert_eq "manual full selection persists" "full" "$GN_INSTALL_MODE"

GN_HW_DISK_GB=300
satoshi_prepare_manual_selection <<< $'1\n\n2\n3\n45\n'
assert_eq "manual defaults core version on blank input" "29.1" "$SATOSHI_VERSION"
assert_eq "manual pruned selection persists" "pruned" "$GN_INSTALL_MODE"
assert_eq "manual custom prune persists" "45" "$SATOSHI_PRUNE_GB"

printf "\n${BOLD}  Section: Compatibility policy${RESET}\n"
GN_HW_DISK_GB=1024
GN_HW_RAM_GB=2
check_compat satoshi >/dev/null 2>&1 || true
assert_eq "compat marks full at 1TB" "full" "$_COMPAT_MODE"
GN_HW_DISK_GB=128
GN_HW_RAM_GB=1
check_compat satoshi >/dev/null 2>&1 || true
assert_eq "compat marks pruned under 1TB" "pruned" "$_COMPAT_MODE"

printf "\n${BOLD}  Section: Menu dispatch${RESET}\n"
LAUNCH_LOG=""
launch_subproject() {
    LAUNCH_LOG+="$1|$2|${SATOSHI_VARIANT:-}|${SATOSHI_VERSION:-}|${GN_INSTALL_MODE:-}|${SATOSHI_PRUNE_GB:-}"$'\n'
    return 0
}

GN_HW_DISK_GB=2048
menu_satoshi <<< $'1\n0\n'
assert_contains "menu_satoshi auto dispatches launch" "$LAUNCH_LOG" "satoshi|Satoshi Node|core|29.1|full|"

LAUNCH_LOG=""
GN_HW_DISK_GB=500
menu_satoshi <<< $'2\n2\n29.2.knots20250101\n2\n2\n0\n'
assert_contains "menu_satoshi manual dispatches knots launch" "$LAUNCH_LOG" "satoshi|Satoshi Node|knots|29.2.knots20250101|pruned|30"

assert_ok "coming soon menu returns cleanly" bash -lc "source '$NODENATION_SCRIPT'; banner_root(){ :; }; section(){ :; }; sep(){ :; }; _menu_read(){ _MENU_OPT=0; }; menu_coming_soon 'Adam Node'"

printf "\n${BOLD}  Section: pre_install export contract${RESET}\n"
PREINSTALL_LOG="${TEST_TMP}/preinstall.env"
INSTALL_LOG="${TEST_TMP}/install.log"
_GN_FOUND_SCRIPT="${STAGING_DIR}/satoshi/pre_install.sh"
_GN_FOUND_DESC="Test Satoshi pre-install"
cat > "$_GN_FOUND_SCRIPT" <<EOF
#!/usr/bin/env bash
cat > "$PREINSTALL_LOG" <<ENV
GN_INSTALL_MODE=\${GN_INSTALL_MODE:-}
SATOSHI_VARIANT=\${SATOSHI_VARIANT:-}
SATOSHI_VERSION=\${SATOSHI_VERSION:-}
SATOSHI_PRUNE_GB=\${SATOSHI_PRUNE_GB:-}
ENV
exit 0
EOF
chmod +x "$_GN_FOUND_SCRIPT"

confirm() { return 0; }
instalar_projeto() { echo installed > "$INSTALL_LOG"; }
id() {
    if [ "${1:-}" = "$GN_USER" ]; then
        return 0
    fi
    command id "$@"
}

SATOSHI_VARIANT="knots"
SATOSHI_VERSION="29.3.knots20260210"
SATOSHI_PRUNE_GB="30"
GN_INSTALL_MODE="pruned"
_executar_pre_install "satoshi"

assert_ok "pre_install log created" test -f "$PREINSTALL_LOG"
PREINSTALL_ENV="$(cat "$PREINSTALL_LOG")"
assert_contains "exports mode to pre_install" "$PREINSTALL_ENV" "GN_INSTALL_MODE=pruned"
assert_contains "exports variant to pre_install" "$PREINSTALL_ENV" "SATOSHI_VARIANT=knots"
assert_contains "exports version to pre_install" "$PREINSTALL_ENV" "SATOSHI_VERSION=29.3.knots20260210"
assert_contains "exports prune size to pre_install" "$PREINSTALL_ENV" "SATOSHI_PRUNE_GB=30"
assert_ok "install promotion path called" test -f "$INSTALL_LOG"

echo ""
printf "${BOLD}${CYAN}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
printf "  Tests: ${BOLD}%d${RESET}  Pass: ${GREEN}${BOLD}%d${RESET}  Fail: " "$TESTS_RUN" "$TESTS_PASS"
if [ "$TESTS_FAIL" -gt 0 ]; then
    printf "${RED}${BOLD}%d${RESET}\n" "$TESTS_FAIL"
    echo ""
    for msg in "${FAIL_MSGS[@]}"; do
        printf "  ${RED}✘ %s${RESET}\n" "$msg"
    done
else
    printf "${GREEN}${BOLD}0${RESET}\n"
fi
printf "${BOLD}${CYAN}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n"

exit "$TESTS_FAIL"
