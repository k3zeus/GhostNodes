#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  tests/test_halfin_install.sh                                ║
# ║  Unit tests for halfin/pre_install.sh — Installation Flow    ║
# ║  Ghost Nodes - NodeNation                                    ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Validates:
#   - pre_install.sh parses without syntax errors
#   - All etapa_* functions are declared
#   - etapa_extras() is a proper function (not loose code)
#   - pre_install.sh file exists and is non-empty
#   - halfin/lib/init.sh loads without error
#   - gn_find_preinstall finds correct script for OrangePi
#   - End-to-end: OrangePi Zero 3 → find → validate script exists
#
# Usage: bash tests/test_halfin_install.sh
#

set -uo pipefail

# ── Test Framework ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

TESTS_RUN=0
TESTS_PASS=0
TESTS_FAIL=0
FAIL_MSGS=()

RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"
CYAN="\e[36m"; BOLD="\e[1m"; DIM="\e[2m"; RESET="\e[0m"

assert_eq() {
    local DESC="$1" EXPECTED="$2" ACTUAL="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$EXPECTED" = "$ACTUAL" ]; then
        TESTS_PASS=$((TESTS_PASS + 1))
        printf "  ${GREEN}✔${RESET} %s\n" "$DESC"
    else
        TESTS_FAIL=$((TESTS_FAIL + 1))
        FAIL_MSGS+=("$DESC: expected='$EXPECTED' actual='$ACTUAL'")
        printf "  ${RED}✘${RESET} %s ${DIM}(expected='%s' got='%s')${RESET}\n" "$DESC" "$EXPECTED" "$ACTUAL"
    fi
}

assert_ok() {
    local DESC="$1"; shift
    TESTS_RUN=$((TESTS_RUN + 1))
    if "$@" 2>/dev/null; then
        TESTS_PASS=$((TESTS_PASS + 1))
        printf "  ${GREEN}✔${RESET} %s\n" "$DESC"
    else
        TESTS_FAIL=$((TESTS_FAIL + 1))
        FAIL_MSGS+=("$DESC: command returned non-zero")
        printf "  ${RED}✘${RESET} %s ${DIM}(returned non-zero)${RESET}\n" "$DESC"
    fi
}

PRE_INSTALL="${PROJECT_ROOT}/halfin/pre_install.sh"
INIT_SH="${PROJECT_ROOT}/halfin/lib/init.sh"
AUTO_SH="${PROJECT_ROOT}/var/auto.sh"

printf "\n${BOLD}${CYAN}═══ Test Suite: Halfin Install Flow ═══${RESET}\n\n"

# ══════════════════════════════════════════════════════════════════════════════
# Section 1: File Integrity
# ══════════════════════════════════════════════════════════════════════════════
printf "${BOLD}  Section: File Integrity${RESET}\n"

assert_ok "halfin/pre_install.sh exists" test -f "$PRE_INSTALL"
assert_ok "halfin/pre_install.sh is non-empty" test -s "$PRE_INSTALL"
assert_ok "halfin/lib/init.sh exists" test -f "$INIT_SH"
assert_ok "var/auto.sh exists" test -f "$AUTO_SH"

# ══════════════════════════════════════════════════════════════════════════════
# Section 2: Syntax Validation — pre_install.sh
# ══════════════════════════════════════════════════════════════════════════════
printf "\n${BOLD}  Section: Syntax Validation — pre_install.sh${RESET}\n"

# bash -n checks syntax without executing
SYNTAX_RESULT=$(bash -n "$PRE_INSTALL" 2>&1)
SYNTAX_RC=$?
assert_eq "pre_install.sh parses without syntax errors" "0" "$SYNTAX_RC"

if [ "$SYNTAX_RC" -ne 0 ]; then
    printf "  ${DIM}  Syntax error output: %s${RESET}\n" "$SYNTAX_RESULT"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Section 3: Function Declarations — etapa_* 
# ══════════════════════════════════════════════════════════════════════════════
printf "\n${BOLD}  Section: Function Declarations — etapa_*${RESET}\n"

EXPECTED_FUNCTIONS=(
    "etapa_usuario"
    "etapa_sourcelist"
    "etapa_remove_docker"
    "etapa_hostname"
    "etapa_update"
    "etapa_ferramentas"
    "etapa_alias_wifi"
    "etapa_orange3"
    "etapa_extras"
    "etapa_dashboard"
    "etapa_aliases"
    "etapa_remove_legado"
    "etapa_chown"
    "main"
)

for FUNC in "${EXPECTED_FUNCTIONS[@]}"; do
    FOUND=$(grep -c "^${FUNC}()" "$PRE_INSTALL" 2>/dev/null || echo "0")
    assert_ok "Function '${FUNC}()' declared in pre_install.sh" test "$FOUND" -gt 0
done

# ══════════════════════════════════════════════════════════════════════════════
# Section 4: etapa_extras is a proper function
# ══════════════════════════════════════════════════════════════════════════════
printf "\n${BOLD}  Section: etapa_extras() Integrity${RESET}\n"

# etapa_extras must have a function declaration line, not just loose code
# Verify the pattern "etapa_extras() {" exists (with space before brace)
EXTRAS_DECL=$(grep -cE '^etapa_extras\(\)\s*\{' "$PRE_INSTALL" 2>/dev/null || echo "0")
assert_ok "etapa_extras() has proper function declaration" test "$EXTRAS_DECL" -gt 0

# The function should contain _run_extra calls
EXTRAS_CALLS=$(sed -n '/^etapa_extras()/,/^}/p' "$PRE_INSTALL" 2>/dev/null | grep -c '_run_extra' || echo "0")
assert_ok "etapa_extras() contains _run_extra calls" test "$EXTRAS_CALLS" -gt 0

# ══════════════════════════════════════════════════════════════════════════════
# ═════════════════════════════════════════════════════════════════════════════
# Section 4b: bridge activation idempotency
# ═════════════════════════════════════════════════════════════════════════════
printf "\n${BOLD}  Section: Bridge Activation Idempotency${RESET}\n"

# An active bridge already holding the configured address must not be brought up
# again through ifup; ifupdown returns an error in that state.
BRIDGE_FUNCTION=$(sed -n '/^_configurar_bridge()/,/^}/p' "$PRE_INSTALL")
assert_ok "active bridge address is detected before ifup" bash -c 'printf "%s\n" "$1" | grep -Fq '\''ip -4 addr show dev "$BRIDGE_IFACE" | grep -Fq "${BRIDGE_IP}/"'\''' _ "$BRIDGE_FUNCTION"
assert_ok "active bridge uses link-up without rerunning ifup" bash -c 'printf "%s\n" "$1" | grep -Fq '\''ip link set "$BRIDGE_IFACE" up'\''' _ "$BRIDGE_FUNCTION"
# ═════════════════════════════════════════════════════════════════════════════
# Section 4c: operational user access
# ═════════════════════════════════════════════════════════════════════════════
printf "\n${BOLD}  Section: Operational User Access${RESET}\n"

# Archive deployment may make only GN_ROOT inaccessible. The contained code
# directories already retain their published modes; no recursive permission change.
CHOWN_FUNCTION=$(sed -n '/^etapa_chown()/,/^}/p' "$PRE_INSTALL")
assert_ok "project root is traversable for the menu user" bash -c 'printf "%s\n" "$1" | grep -Fq '\''chmod 0755 "$GN_ROOT"'\''' _ "$CHOWN_FUNCTION"
assert_ok "ghostnode entrypoint remains executable" bash -c 'printf "%s\n" "$1" | grep -Fq '\''chmod 0755 "$GN_ROOT/ghostnode"'\''' _ "$CHOWN_FUNCTION"
# ═════════════════════════════════════════════════════════════════════════════
# Section 4d: menu runtime log location
# ═════════════════════════════════════════════════════════════════════════════
printf "\n${BOLD}  Section: Menu Runtime Log Location${RESET}\n"

# The menu runs as GN_USER after the code archive is installed root-owned.
# Its writable log must therefore be held in the user's private runtime state.
GHOSTNODE="$PROJECT_ROOT/ghostnode"
assert_ok "menu log uses the private Halfin state directory" grep -Fq 'LOG_DIR="${GN_LOG_DIR:-/home/${GN_USER}/.local/state/halfin/logs}"' "$GHOSTNODE"
# Section 5: halfin/lib/init.sh loads correctly
# ══════════════════════════════════════════════════════════════════════════════
printf "\n${BOLD}  Section: Library Loading — init.sh${RESET}\n"

assert_ok "halfin/lib/init.sh sources without error" bash -c "source '$INIT_SH'" 

# ══════════════════════════════════════════════════════════════════════════════
# Section 6: End-to-End — OrangePi Zero 3 → pre_install.sh
# ══════════════════════════════════════════════════════════════════════════════
printf "\n${BOLD}  Section: E2E — OrangePi Zero 3 → pre_install.sh${RESET}\n"

E2E_RESULT=$(bash -c "
    source '$AUTO_SH'
    GN_HW_MODEL='Orange Pi Zero 3'
    GN_HW_ARCH='arm64'
    GN_HW_OS='Debian GNU/Linux 12 (bookworm)'
    GN_ROOT='${PROJECT_ROOT}'
    
    if gn_find_preinstall 'halfin'; then
        if [ -f \"\$_GN_FOUND_SCRIPT\" ]; then
            echo 'SCRIPT_EXISTS'
        else
            echo 'SCRIPT_MISSING'
        fi
    else
        echo 'NO_MATCH'
    fi
" 2>/dev/null)
assert_eq "E2E: OrangePi → find → script exists" "SCRIPT_EXISTS" "${E2E_RESULT:-FAIL}"

# ══════════════════════════════════════════════════════════════════════════════
# Section 7: main() is called at end of script
# ══════════════════════════════════════════════════════════════════════════════
printf "\n${BOLD}  Section: Script Entry Point${RESET}\n"

# Last meaningful non-empty line should be 'main' (calls the main function)
LAST_CALL=$(tail -20 "$PRE_INSTALL" | grep -v '^#' | grep -v '^$' | grep -v '^\s*$' | tail -1 | sed 's/^[[:space:]]*//')
assert_eq "pre_install.sh forwards arguments to main" 'main "$@"' "$LAST_CALL"

# ── Results ───────────────────────────────────────────────────────────────────
echo ""
printf "${BOLD}${CYAN}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
printf "  Tests: ${BOLD}%d${RESET}  Pass: ${GREEN}${BOLD}%d${RESET}  Fail: " "$TESTS_RUN" "$TESTS_PASS"
if [ "$TESTS_FAIL" -gt 0 ]; then
    printf "${RED}${BOLD}%d${RESET}\n" "$TESTS_FAIL"
    echo ""
    for MSG in "${FAIL_MSGS[@]}"; do
        printf "  ${RED}  ✘ %s${RESET}\n" "$MSG"
    done
else
    printf "${GREEN}${BOLD}0${RESET}\n"
fi
printf "${BOLD}${CYAN}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n"

exit "$TESTS_FAIL"
