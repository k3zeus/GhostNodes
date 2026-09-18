#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
assert() { grep -Fq "$2" "$1" || { echo "FAIL: $3" >&2; exit 1; }; }
bash -n "$ROOT/ghostnode"
bash -n "$ROOT/lib/tui_engine.sh"
assert "$ROOT/ghostnode" 'tui_render_main' 'main menu does not use renderer'
assert "$ROOT/ghostnode" 'tui_read_key' 'main menu does not use keyboard adapter'
assert "$ROOT/lib/tui_engine.sh" 'tui_capability' 'renderer has no capability fallback'
assert "$ROOT/lib/tui_engine.sh" 'tui_move_focus' 'renderer has no focus controller'
assert "$ROOT/lib/tui_engine.sh" 'TUI_BRIGHT_CYAN' 'renderer has no bright focus palette'
assert "$ROOT/lib/core_lib.sh" '\033[2J\033[H' 'renderer does not clear residual frame content'
for key_case in '[A:UP' '[B:DOWN' '[C:RIGHT' '[D:LEFT' 'OA:UP' 'OB:DOWN' 'OC:RIGHT' 'OD:LEFT'; do
    sequence=${key_case%%:*}; expected=${key_case##*:}
    set +e
    actual=$(printf "\033%s" "$sequence" | bash -c "source '$ROOT/lib/tui_engine.sh'; tui_read_key")
    key_rc=$?
    set -e
    [ "$key_rc" -eq 0 ] && [ "$actual" = "$expected" ] || { echo "FAIL: key $sequence expected $expected got $actual (rc=$key_rc)" >&2; exit 1; }
done

# ENTER must be normalized to the focused numeric option before action routing.
grep -Fq '[ "$key" = ENTER ] && key="$selected"' "$ROOT/ghostnode" || { echo 'FAIL: ENTER is not routed to focused option' >&2; exit 1; }
! grep -Fq 'ENTER) key="$selected" ;;&' "$ROOT/ghostnode" || { echo 'FAIL: invalid ENTER fallthrough remains' >&2; exit 1; }
OUT=$(GN_TUI_NO_CLEAR=1 GN_TUI_PREVIEW=1 COLUMNS=120 LINES=40 TERM=xterm bash "$ROOT/ghostnode" --tui-preview 2>&1)
[[ "$OUT" != *"command not found"* ]] || { echo "FAIL: preview emitted renderer error" >&2; exit 1; }
[[ "$OUT" == *'MENU PRINCIPAL'* ]] || { echo 'FAIL: preview missing MENU PRINCIPAL' >&2; exit 1; }
[[ "$OUT" == *'Sistema'* ]] || { echo 'FAIL: preview missing Sistema' >&2; exit 1; }
[[ "$OUT" == *'Satoshi Node'* ]] || { echo 'FAIL: preview missing Satoshi Node' >&2; exit 1; }
[[ "$OUT" == *'Sair do sistema'* ]] || { echo 'FAIL: preview missing Sair do sistema' >&2; exit 1; }
echo 'OK: TUI main menu preview'



grep -Fq 'screen_ready=0' "$ROOT/ghostnode" || { echo 'FAIL: main banner is not retained between movements' >&2; exit 1; }
grep -Fq 'printf '"'"'\033[u\033[J'"'"'' "$ROOT/ghostnode" || { echo 'FAIL: arrow redraw does not restore the menu origin' >&2; exit 1; }
echo 'OK: banner retention and partial redraw'

assert "$ROOT/lib/tui_engine.sh" '╔' 'cards do not use the canonical top border'
assert "$ROOT/lib/tui_engine.sh" '╚' 'cards do not use the canonical bottom border'
assert "$ROOT/lib/tui_engine.sh" '↑ UP  ↓ DOWN  ← LEFT  → RIGHT' 'help bar does not expose all arrow controls'
assert "$ROOT/lib/tui_engine.sh" 'icons=(⚙ ⌁ ▣ ₿ ↻ ⏻)' 'cards do not define semantic icons'
! grep -Fq 'markers=(' "$ROOT/lib/tui_engine.sh" || { echo 'FAIL: alphabetic menu markers remain' >&2; exit 1; }
! grep -Fq $'\r' "$ROOT/lib/tui_engine.sh" || { echo 'FAIL: TUI engine contains CR line endings that break wide layout on Linux' >&2; exit 1; }
[[ "$OUT" == *'⚙'* ]] || { echo 'FAIL: wide preview is missing the Sistema icon' >&2; exit 1; }
[[ "$OUT" == *'╔'* ]] || { echo 'FAIL: wide preview is missing canonical card borders' >&2; exit 1; }
echo 'OK: v0.2beta visual contract'
