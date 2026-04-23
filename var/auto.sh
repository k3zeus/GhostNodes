#!/usr/bin/env bash

[ -n "${_GN_AUTO_LOADED:-}" ] && return 0
_GN_AUTO_LOADED=1

declare -a _GN_AUTO_ENTRIES=()
_GN_AUTO_SEP=$'\x1f'

gn_register_preinstall() {
    local subproject="$1"
    local hw_regex="$2"
    local arch="$3"
    local os_regex="$4"
    local script="$5"
    local desc="$6"

    _GN_AUTO_ENTRIES+=("${subproject}${_GN_AUTO_SEP}${hw_regex}${_GN_AUTO_SEP}${arch}${_GN_AUTO_SEP}${os_regex}${_GN_AUTO_SEP}${script}${_GN_AUTO_SEP}${desc}")
}

# Halfin Node
gn_register_preinstall \
    "halfin" \
    "Orange Pi Zero 3|OrangePi Zero3|orangepi zero3" \
    "arm64" \
    "Debian.*bookworm|bookworm" \
    "halfin/pre_install.sh" \
    "OrangePi Zero 3 - Debian Bookworm arm64"

gn_register_preinstall \
    "halfin" \
    "Orange Pi Zero 2W|OrangePi Zero2W" \
    "arm64" \
    "Debian.*bookworm|bookworm" \
    "halfin/pre_install.sh" \
    "OrangePi Zero 2W - Debian Bookworm arm64"

gn_register_preinstall \
    "halfin" \
    "Raspberry Pi 4|Raspberry Pi Model B Rev" \
    "arm64" \
    "Debian|Raspbian|bookworm|bullseye" \
    "halfin/pre_install_rpi4.sh" \
    "Raspberry Pi 4 - Debian/Raspbian arm64"

gn_register_preinstall \
    "halfin" \
    ".*" \
    "arm64" \
    "Debian|Ubuntu|Armbian" \
    "halfin/pre_install.sh" \
    "Debian/Ubuntu arm64 generic fallback"

# Satoshi Node
gn_register_preinstall \
    "satoshi" \
    ".*" \
    "x86_64" \
    "Debian|Ubuntu" \
    "satoshi/pre_install.sh" \
    "x86_64 - Debian/Ubuntu (Full or Pruned Node)"

gn_register_preinstall \
    "satoshi" \
    ".*" \
    "arm64" \
    "Debian|Ubuntu" \
    "satoshi/pre_install.sh" \
    "arm64 - Debian/Ubuntu (Pruned Node recommended)"

gn_find_preinstall() {
    local target_project="$1"
    local base_dir="${2:-$GN_ROOT}"

    _GN_FOUND_SCRIPT=""
    _GN_FOUND_DESC=""

    local model="${GN_HW_MODEL:-}"
    local arch="${GN_HW_ARCH:-}"
    local os="${GN_HW_OS:-}"
    local entry

    for entry in "${_GN_AUTO_ENTRIES[@]}"; do
        IFS="$_GN_AUTO_SEP" read -r e_proj e_hw_re e_arch e_os_re e_script e_desc <<< "$entry"

        [ "$e_proj" != "$target_project" ] && continue

        if [ "$e_arch" != "any" ] && [ "$e_arch" != "$arch" ]; then
            continue
        fi

        if ! echo "$model" | grep -qiE "$e_hw_re" 2>/dev/null; then
            continue
        fi

        if ! echo "$os" | grep -qiE "$e_os_re" 2>/dev/null; then
            continue
        fi

        _GN_FOUND_SCRIPT="${base_dir}/${e_script}"
        _GN_FOUND_DESC="$e_desc"
        return 0
    done

    return 1
}
