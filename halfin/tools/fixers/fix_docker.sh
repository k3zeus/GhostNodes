#!/bin/bash
# Script de auto-cura externalizado (Reutilizável)
# Pode ser chamado pelo Python (self_healing.py) ou pelo Menu UI (ghostnode).

CONTAINER="$1"

if [ -z "$CONTAINER" ]; then
    echo "Uso: fix_docker.sh <nome_do_container>"
    exit 1
fi

echo "Iniciando processo de cura para Docker Container: $CONTAINER"
# Tenta reiniciar o container de forma crua
docker restart "$CONTAINER" >/dev/null 2>&1

# Em cenários mais complexos (se compose.yml estiver caído inteiro)
# docker-compose -f ${GN_ROOT}/halfin/docker/docker-compose.yml up -d $CONTAINER

exit 0
