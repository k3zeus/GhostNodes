#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker compose --project-directory "$SCRIPT_DIR" config --quiet
docker compose --project-directory "$SCRIPT_DIR" pull
docker compose --project-directory "$SCRIPT_DIR" up -d --wait --wait-timeout 180
