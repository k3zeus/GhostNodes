#!/bin/bash
set -euo pipefail
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/../docker" && pwd)/docker.sh" "$@"
