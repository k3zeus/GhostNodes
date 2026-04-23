#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  tests/test_auto_registry.sh                                 ║
# ║  Unit tests for var/auto.sh — Hardware Registry              ║
# ║  Ghost Nodes - NodeNation                                    ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Validates:
#   - auto.sh loads without errors
#   - gn_register_preinstall creates entries
#   - gn_find_preinstall matches OrangePi Zero 3 correctly
#   - gn_find_preinstall matches generic arm64 as fallback
#   - gn_find_preinstall rejects x86 for halfin (no match)
#
# Usage: bash tests/test_auto_registry.sh
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

assert_fail() {
    local DESC="$1"; shift
    TESTS_RUN=$((TESTS_RUN + 1))
    if ! "$@" 2>/dev/null; then
        TESTS_PASS=$((TESTS_PASS + 1))
        printf "  ${GREEN}✔${RESET} %s\n" "$DESC"
    else
        TESTS_FAIL=$((TESTS_FAIL + 1))
        FAIL_MSGS+=("$DESC: expected failure but succeeded")
        printf "  ${RED}✘${RESET} %s ${DIM}(expected failure but succeeded)${RESET}\n" "$DESC"
    fi
}

# ── Setup ─────────────────────────────────────────────────────────────────────
AUTO_SH="${PROJECT_ROOT}/var/auto.sh"
printf "\n${BOLD}${CYAN}═══ Test Suite: auto.sh Registry ═══${RESET}\n\n"

# ── Test 1: auto.sh exists and loads ──────────────────────────────────────────
printf "${BOLD}  Section: File Integrity${RESET}\n"

assert_ok "auto.sh exists" test -f "$AUTO_SH"

# Source it in a subshell to avoid polluting test env
assert_ok "auto.sh sources without error" bash -c "source '$AUTO_SH'"

# ── Test 2: Entries are registered ────────────────────────────────────────────
printf "\n${BOLD}  Section: Entry Registration${RESET}\n"

ENTRY_COUNT=$(bash -c "
    source '$AUTO_SH'
    echo \${#_GN_AUTO_ENTRIES[@]}
" 2>/dev/null)
assert_ok "At least 1 entry registered" test "${ENTRY_COUNT:-0}" -gt 0

# Halfin entries specifically
HALFIN_COUNT=$(bash -c "
    source '$AUTO_SH'
    C=0
    for E in \"\${_GN_AUTO_ENTRIES[@]}\"; do
        [[ \"\$E\" == halfin* ]] && C=\$((C+1))
    done
    echo \$C
" 2>/dev/null)
assert_ok "At least 1 halfin entry registered" test "${HALFIN_COUNT:-0}" -gt 0

# ── Test 3: OrangePi Zero 3 match ────────────────────────────────────────────
printf "\n${BOLD}  Section: Hardware Matching — OrangePi Zero 3${RESET}\n"

MATCH_ORANGE=$(bash -c "
    source '$AUTO_SH'
    GN_HW_MODEL='Orange Pi Zero 3'
    GN_HW_ARCH='arm64'
    GN_HW_OS='Debian GNU/Linux 12 (bookworm)'
    GN_ROOT='${PROJECT_ROOT}'
    if gn_find_preinstall 'halfin'; then
        echo 'MATCH'
    else
        echo 'NO_MATCH'
    fi
" 2>/dev/null)
assert_eq "OrangePi Zero 3 + arm64 + bookworm matches halfin" "MATCH" "${MATCH_ORANGE:-NO_MATCH}"

# Check that it points to the right script
MATCH_SCRIPT=$(bash -c "
    source '$AUTO_SH'
    GN_HW_MODEL='Orange Pi Zero 3'
    GN_HW_ARCH='arm64'
    GN_HW_OS='Debian GNU/Linux 12 (bookworm)'
    GN_ROOT='${PROJECT_ROOT}'
    gn_find_preinstall 'halfin' && echo \"\$_GN_FOUND_SCRIPT\"
" 2>/dev/null)
EXPECTED_SCRIPT="${PROJECT_ROOT}/halfin/pre_install.sh"
assert_eq "Match points to halfin/pre_install.sh" "$EXPECTED_SCRIPT" "${MATCH_SCRIPT:-EMPTY}"

# ── Test 4: Generic arm64 Debian fallback ─────────────────────────────────────
printf "\n${BOLD}  Section: Hardware Matching — Generic arm64 Fallback${RESET}\n"

MATCH_GENERIC=$(bash -c "
    source '$AUTO_SH'
    GN_HW_MODEL='Some Random SBC'
    GN_HW_ARCH='arm64'
    GN_HW_OS='Debian GNU/Linux 12 (bookworm)'
    GN_ROOT='${PROJECT_ROOT}'
    if gn_find_preinstall 'halfin'; then
        echo 'MATCH'
    else
        echo 'NO_MATCH'
    fi
" 2>/dev/null)
assert_eq "Generic arm64 + bookworm matches halfin (fallback)" "MATCH" "${MATCH_GENERIC:-NO_MATCH}"

# ── Test 5: x86_64 should NOT match halfin (no x86 halfin entry) ─────────────
printf "\n${BOLD}  Section: Hardware Matching — x86_64 Reject${RESET}\n"

MATCH_X86=$(bash -c "
    source '$AUTO_SH'
    GN_HW_MODEL='Intel NUC'
    GN_HW_ARCH='x86_64'
    GN_HW_OS='Ubuntu 22.04'
    GN_ROOT='${PROJECT_ROOT}'
    if gn_find_preinstall 'halfin'; then
        echo 'MATCH'
    else
        echo 'NO_MATCH'
    fi
" 2>/dev/null)
assert_eq "x86_64 does NOT match halfin" "NO_MATCH" "${MATCH_X86:-NO_MATCH}"

# ── Test 6: Empty hardware vars should not match ──────────────────────────────
printf "\n${BOLD}  Section: Hardware Matching — Empty Vars Safety${RESET}\n"

MATCH_EMPTY=$(bash -c "
    source '$AUTO_SH'
    GN_HW_MODEL=''
    GN_HW_ARCH=''
    GN_HW_OS=''
    GN_ROOT='${PROJECT_ROOT}'
    if gn_find_preinstall 'halfin'; then
        echo 'MATCH'
    else
        echo 'NO_MATCH'
    fi
" 2>/dev/null)
assert_eq "Empty hw vars do NOT match halfin" "NO_MATCH" "${MATCH_EMPTY:-NO_MATCH}"

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
