#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  tests/test_dashboard_navigation.sh                          ║
# ║  Unit tests for nodenation — Dashboard TUI Navigation        ║
# ║  Ghost Nodes - NodeNation                                    ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Validates:
#   - nodenation script parses without syntax errors
#   - HAS_PRE variable is defined before use in launch_subproject
#   - check_compat handles empty arch gracefully (no crash)
#   - check_compat returns 0 for arm64 halfin
#   - check_compat returns 1 for non-arm64 halfin
#   - menu functions exist and are declared
#   - _menu_read, _sair, banner_root are declared
#
# Usage: bash tests/test_dashboard_navigation.sh
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

NODENATION="${PROJECT_ROOT}/nodenation"
printf "\n${BOLD}${CYAN}═══ Test Suite: Dashboard Navigation (nodenation) ═══${RESET}\n\n"

# ══════════════════════════════════════════════════════════════════════════════
# Section 1: Syntax Validation
# ══════════════════════════════════════════════════════════════════════════════
printf "${BOLD}  Section: Syntax Validation${RESET}\n"

assert_ok "nodenation file exists" test -f "$NODENATION"

# bash -n checks syntax without executing
assert_ok "nodenation parses without syntax errors (bash -n)" bash -n "$NODENATION"

# ══════════════════════════════════════════════════════════════════════════════
# Section 2: HAS_PRE Variable Definition
# ══════════════════════════════════════════════════════════════════════════════
printf "\n${BOLD}  Section: HAS_PRE Variable Definition${RESET}\n"

# Check that HAS_PRE is defined (assigned) inside launch_subproject
HAS_PRE_DEFINED=$(grep -c 'HAS_PRE=' "$NODENATION" 2>/dev/null || echo "0")
assert_ok "HAS_PRE is assigned at least once in nodenation" test "$HAS_PRE_DEFINED" -gt 0

# Check that HAS_PRE is assigned BEFORE it's tested with -eq
# The assignment must come before the test in the file
HAS_PRE_ASSIGN_LINE=$(grep -n 'HAS_PRE=' "$NODENATION" 2>/dev/null | head -1 | cut -d: -f1)
HAS_PRE_TEST_LINE=$(grep -n 'HAS_PRE.*-eq' "$NODENATION" 2>/dev/null | head -1 | cut -d: -f1)

if [ -n "${HAS_PRE_ASSIGN_LINE:-}" ] && [ -n "${HAS_PRE_TEST_LINE:-}" ]; then
    assert_ok "HAS_PRE assigned before first test" test "$HAS_PRE_ASSIGN_LINE" -lt "$HAS_PRE_TEST_LINE"
else
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ -z "${HAS_PRE_ASSIGN_LINE:-}" ]; then
        TESTS_FAIL=$((TESTS_FAIL + 1))
        FAIL_MSGS+=("HAS_PRE assignment not found in nodenation")
        printf "  ${RED}✘${RESET} HAS_PRE assigned before first test ${DIM}(no assignment found)${RESET}\n"
    else
        # HAS_PRE_TEST_LINE is empty — that's fine, maybe it's not tested anymore
        TESTS_PASS=$((TESTS_PASS + 1))
        printf "  ${GREEN}✔${RESET} HAS_PRE assigned before first test ${DIM}(no -eq test found)${RESET}\n"
    fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# Section 3: check_compat — Empty Variable Safety
# ══════════════════════════════════════════════════════════════════════════════
printf "\n${BOLD}  Section: check_compat() — Empty Variable Safety${RESET}\n"

# Extract check_compat function and test it in isolation
# We need to source only the function, not the whole script
CHECK_COMPAT_RESULT=$(bash -c "
    set -uo pipefail
    # Suppress UI — we only need check_compat
    BOLD=''; RESET=''; DIM=''; GREEN=''; YELLOW=''; RED=''; CYAN=''; MAGENTA=''; WHITE=''
    CHECK=''; CROSS=''; WARN=''; ARROW=''; BULLET=''
    step_ok()   { :; }
    step_warn() { :; }
    step_err()  { :; }
    step_info() { :; }

    # Extract and source only check_compat
    eval \"\$(sed -n '/^check_compat()/,/^}/p' '$NODENATION')\"

    # Test with EMPTY arch
    GN_HW_ARCH=''
    GN_HW_MODEL=''
    GN_HW_RAM_GB=0
    GN_HW_DISK_GB=0
    _COMPAT_MSG=''
    _COMPAT_WARNINGS=()
    _COMPAT_MODE=''

    check_compat 'halfin'
    RC=\$?
    echo \"RC=\${RC}|MSG=\${_COMPAT_MSG}\"
" 2>/dev/null)

CHECK_RC=$(echo "$CHECK_COMPAT_RESULT" | grep -o 'RC=[0-9]*' | cut -d= -f2)
# With empty arch, it should return RC=1 (warning, not crash) — NOT RC=2 (blocked)
# and NOT blank (which would mean it crashed)
assert_ok "check_compat with empty arch does not crash" test -n "${CHECK_RC:-}"
assert_eq "check_compat with empty arch returns RC=1 (warning)" "1" "${CHECK_RC:-CRASH}"

# ══════════════════════════════════════════════════════════════════════════════
# Section 4: check_compat — arm64 Halfin Compatibility
# ══════════════════════════════════════════════════════════════════════════════
printf "\n${BOLD}  Section: check_compat() — arm64 Halfin${RESET}\n"

CHECK_ARM64_RESULT=$(bash -c "
    set -uo pipefail
    BOLD=''; RESET=''; DIM=''; GREEN=''; YELLOW=''; RED=''; CYAN=''; MAGENTA=''; WHITE=''
    CHECK=''; CROSS=''; WARN=''; ARROW=''; BULLET=''
    step_ok()   { :; }
    step_warn() { :; }
    step_err()  { :; }
    step_info() { :; }

    eval \"\$(sed -n '/^check_compat()/,/^}/p' '$NODENATION')\"

    GN_HW_ARCH='arm64'
    GN_HW_MODEL='Orange Pi Zero 3'
    GN_HW_RAM_GB=1
    GN_HW_DISK_GB=30
    _COMPAT_MSG=''
    _COMPAT_WARNINGS=()
    _COMPAT_MODE=''

    check_compat 'halfin'
    echo \$?
" 2>/dev/null)
assert_eq "check_compat arm64 halfin returns RC=0 (compatible)" "0" "${CHECK_ARM64_RESULT:-CRASH}"

# ══════════════════════════════════════════════════════════════════════════════
# Section 5: check_compat — x86_64 Halfin Warning
# ══════════════════════════════════════════════════════════════════════════════
printf "\n${BOLD}  Section: check_compat() — x86_64 Halfin Warning${RESET}\n"

CHECK_X86_RESULT=$(bash -c "
    set -uo pipefail
    BOLD=''; RESET=''; DIM=''; GREEN=''; YELLOW=''; RED=''; CYAN=''; MAGENTA=''; WHITE=''
    CHECK=''; CROSS=''; WARN=''; ARROW=''; BULLET=''
    step_ok()   { :; }
    step_warn() { :; }
    step_err()  { :; }
    step_info() { :; }

    eval \"\$(sed -n '/^check_compat()/,/^}/p' '$NODENATION')\"

    GN_HW_ARCH='x86_64'
    GN_HW_MODEL='Intel NUC'
    GN_HW_RAM_GB=8
    GN_HW_DISK_GB=500
    _COMPAT_MSG=''
    _COMPAT_WARNINGS=()
    _COMPAT_MODE=''

    check_compat 'halfin'
    echo \$?
" 2>/dev/null)
assert_eq "check_compat x86_64 halfin returns RC=1 (warning)" "1" "${CHECK_X86_RESULT:-CRASH}"

# ══════════════════════════════════════════════════════════════════════════════
# Section 6: Key Functions Declared
# ══════════════════════════════════════════════════════════════════════════════
printf "\n${BOLD}  Section: Key Function Declarations${RESET}\n"

for FUNC in menu_principal launch_subproject check_compat detect_hardware \
            download_project check_preinstall_exists _executar_pre_install \
            banner_root _menu_read _sair; do
    assert_ok "Function '$FUNC' declared" grep -q "^${FUNC}()" "$NODENATION"
done

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
