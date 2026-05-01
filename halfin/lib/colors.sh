#!/bin/bash

[ -n "${_GN_COLORS_LOADED:-}" ] && [ -n "${BOLD:-}" ] && return 0
_GN_COLORS_LOADED=1

RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"

BLACK="\e[30m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
WHITE="\e[37m"

CHECK="${GREEN}OK${RESET}"
WARN="${YELLOW}WARN${RESET}"
CROSS="${RED}ERR${RESET}"
ARROW="${CYAN}>${RESET}"
BULLET="${CYAN}-${RESET}"
