#!/bin/bash
# Make the Halfin wired uplink explicit and deterministic: ifupdown DHCP only.
set -euo pipefail

IFACE="${HALFIN_WAN_IFACE:-end0}"
ROOT_FILE="${HALFIN_INTERFACES_FILE:-/etc/network/interfaces}"
FRAGMENTS_DIR="${HALFIN_INTERFACES_DIR:-/etc/network/interfaces.d}"
METRIC="${HALFIN_WAN_METRIC:-100}"

[[ "$IFACE" =~ ^[a-zA-Z0-9_.-]{1,15}$ ]] || { echo "invalid WAN interface" >&2; exit 2; }
[[ "$METRIC" =~ ^[0-9]+$ ]] || { echo "invalid WAN metric" >&2; exit 2; }

mkdir -p "$FRAGMENTS_DIR"
[ -e "$ROOT_FILE" ] || : > "$ROOT_FILE"

python3 - "$IFACE" "$ROOT_FILE" "$FRAGMENTS_DIR" <<'PY'
import pathlib
import sys

iface, root, fragment_dir = sys.argv[1:]
paths = [pathlib.Path(root)] + [p for p in sorted(pathlib.Path(fragment_dir).glob('*')) if p.is_file() and p.name != 'halfin-wan']

def rewrite(path):
    lines = path.read_text(encoding='utf-8').splitlines(keepends=True)
    output, index = [], 0
    while index < len(lines):
        line = lines[index]
        tokens = line.split()
        if tokens and tokens[0] in ('auto', 'allow-hotplug') and iface in tokens[1:]:
            retained = [token for token in tokens[1:] if token != iface]
            if retained:
                output.append('{} {}\\n'.format(tokens[0], ' '.join(retained)))
            index += 1
            continue
        if len(tokens) >= 2 and tokens[0] == 'iface' and tokens[1] == iface:
            index += 1
            while index < len(lines) and (lines[index].startswith((' ', '\t')) or not lines[index].strip()):
                index += 1
            continue
        output.append(line)
        index += 1
    path.write_text(''.join(output), encoding='utf-8')

for path in paths:
    rewrite(path)
PY

cat > "$FRAGMENTS_DIR/halfin-wan" <<EOF
# Managed by Halfin: primary wired uplink must obtain its address through DHCP.
allow-hotplug ${IFACE}
iface ${IFACE} inet dhcp
    metric ${METRIC}
EOF