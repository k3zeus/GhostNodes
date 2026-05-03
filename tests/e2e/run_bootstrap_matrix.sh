#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

docker_mount_path() {
    local path="$1"
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -m "$path"
    else
        printf "%s" "$path"
    fi
}

build_and_run() {
    local distro="$1"
    local dockerfile="${SCRIPT_DIR}/Dockerfile.${distro}"
    local image="ghostnodes-e2e:${distro}"
    local mount_root

    mount_root="$(docker_mount_path "$PROJECT_ROOT")"

    echo "[host] building ${image}"
    docker build -t "${image}" -f "${dockerfile}" "${SCRIPT_DIR}"

    echo "[host] running ${image}"
    docker run --rm \
        -e WORKSPACE=/workspace \
        -v "${mount_root}:/workspace" \
        "${image}" \
        bash /workspace/tests/e2e/container_bootstrap_matrix.sh "${distro}"
}

build_and_run debian
build_and_run ubuntu
