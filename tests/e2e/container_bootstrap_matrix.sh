#!/usr/bin/env bash

set -Eeuo pipefail

DISTRO="${1:-debian}"
WORKSPACE="${WORKSPACE:-/workspace}"
SERVE_DIR="$(mktemp -d)"
LOG_DIR="$(mktemp -d)"
PORT="${SERVE_LOCAL_PORT:-18080}"

if [ "${KEEP_E2E_LOGS:-false}" = "true" ]; then
    echo "[${DISTRO}] SERVE_DIR=${SERVE_DIR}"
    echo "[${DISTRO}] LOG_DIR=${LOG_DIR}"
fi

cleanup() {
    if [ -n "${SERVER_PID:-}" ] && kill -0 "${SERVER_PID}" 2>/dev/null; then
        kill "${SERVER_PID}" 2>/dev/null || true
        wait "${SERVER_PID}" 2>/dev/null || true
    fi
    if [ "${KEEP_E2E_LOGS:-false}" != "true" ]; then
        rm -rf "${SERVE_DIR}" "${LOG_DIR}"
    fi
}
trap cleanup EXIT

on_error() {
    echo "[${DISTRO}] failure diagnostics"
    ls -la /tmp || true
    find /tmp -maxdepth 2 \( -name 'ghostnodes*' -o -name 'GhostNodes-main' \) -print 2>/dev/null || true
    if [ -d /tmp/ghostnodes_staging ]; then
        find /tmp/ghostnodes_staging -maxdepth 3 -type f | sort | head -50 || true
    fi
    if [ -f "${LOG_DIR}/download-only.log" ]; then
        echo "--- download-only.log ---"
        cat "${LOG_DIR}/download-only.log" || true
    fi
    if [ -f "${LOG_DIR}/detect-hw.log" ]; then
        echo "--- detect-hw.log ---"
        cat "${LOG_DIR}/detect-hw.log" || true
    fi
}
trap on_error ERR

create_snapshot() {
    local snapshot_root="${SERVE_DIR}/GhostNodes-main"
    mkdir -p "${snapshot_root}"
    cp "${WORKSPACE}/nodenation" "${SERVE_DIR}/nodenation"
    tar -C "${WORKSPACE}" -cf - \
        --exclude=.git \
        --exclude=.venv \
        --exclude=.gstack \
        --exclude=Archive \
        --exclude=Memory \
        --exclude=__pycache__ \
        . | tar -C "${snapshot_root}" -xf -
    tar -C "${SERVE_DIR}" -czf "${SERVE_DIR}/main.tar.gz" "GhostNodes-main"
}

start_server() {
    python3 -m http.server "${PORT}" --directory "${SERVE_DIR}" > "${LOG_DIR}/http.log" 2>&1 &
    SERVER_PID=$!
    sleep 1
}

run_bootstrap() {
    local url="http://127.0.0.1:${PORT}/nodenation"
    local bootstrap_file="/tmp/nodenation-bootstrap.sh"
    export GN_REPO_URL="http://127.0.0.1:${PORT}/main.tar.gz"
    export GN_REPO_DIR_NAME="GhostNodes-main"
    export GN_BOOTSTRAP_ALLOW_NONTTY="true"

    curl -fsSL "${url}" -o "${bootstrap_file}"
    chmod +x "${bootstrap_file}"

    echo "[${DISTRO}] bootstrap detect-hw"
    bash "${bootstrap_file}" --detect-hw > "${LOG_DIR}/detect-hw.log"

    echo "[${DISTRO}] bootstrap download-only"
    bash "${bootstrap_file}" --download-only > "${LOG_DIR}/download-only.log"

    test -f /tmp/ghostnodes_staging/nodenation
    test -f /tmp/ghostnodes_staging/satoshi/install.sh
    test -f /tmp/ghostnodes_staging/halfin/pre_install.sh
}

main() {
    create_snapshot
    start_server
    run_bootstrap

    echo "[${DISTRO}] shell contract tests"
    bash "${WORKSPACE}/tests/test_auto_registry.sh"
    bash "${WORKSPACE}/tests/test_halfin_install.sh"
    bash "${WORKSPACE}/tests/test_satoshi_install.sh"
    bash "${WORKSPACE}/tests/test_nodenation_bootstrap.sh"

    echo "[${DISTRO}] ok"
}

main "$@"
