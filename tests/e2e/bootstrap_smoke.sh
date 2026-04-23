#!/bin/bash

set -euo pipefail

BOOTSTRAP_URL="${BOOTSTRAP_URL:-http://host.docker.internal:18080/nodenation-test}"

echo "[bootstrap-smoke] detect hardware"
curl -fsSL "$BOOTSTRAP_URL" | bash -s -- --detect-hw

echo "[bootstrap-smoke] download-only"
curl -fsSL "$BOOTSTRAP_URL" | bash -s -- --download-only

test -f /tmp/ghostnodes_staging/nodenation
test -f /tmp/ghostnodes_var/auto.sh

echo "[bootstrap-smoke] ok"
