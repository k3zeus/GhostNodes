#!/bin/bash
#
# Installation Script Docker - Halfin Node - Debian Bookworm - v.0.7 20032026 
#
_GN_DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HALFIN_DIR="${HALFIN_DIR:-$(dirname "$_GN_DOCKER_DIR")}"
GN_ROOT="${GN_ROOT:-$(dirname "$HALFIN_DIR")}"
echo "#############################################################"
echo "############ Choose Extra Services to Install ###############"
echo "#############################################################"

echo ""
echo "#"
echo "### You would like to install the services: Docker and Portainer? ###"
echo "#"
echo "Install? [y/N]"

read -r resp

if [ "$resp" != "y" ] && [ "$resp" != "Y" ] && [ "$resp" != "s" ] && [ "$resp" != "S" ]; then
    echo "Install skipped."
    exit 0
fi

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

#
echo "######### Instalando Docker e Ferramentas ###########"
#
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
#
echo "########### Criação e Configuração do Portainer"
#
docker volume create portainer_data
#
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:lts
#
sudo systemctl enable docker
######
COMPOSE_FILE="${HALFIN_DIR}/docker/docker-compose.yml"
COMPOSE_DIR="$(dirname "$COMPOSE_FILE")"

if [ -f "${COMPOSE_DIR}/.env.example" ] && [ ! -f "${COMPOSE_DIR}/.env" ]; then
    echo "Gerando novo .env a partir de .env.example com senhas aleatorias seguras..."
    S_PASS="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16 || true)"
    W_PASS="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16 || true)"
    P_PASS="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16 || true)"
    if [ -z "$S_PASS" ] || [ -z "$W_PASS" ] || [ -z "$P_PASS" ]; then
        echo "Erro: falha ao gerar senhas aleatorias para o .env"
        exit 1
    fi

    cp "${COMPOSE_DIR}/.env.example" "${COMPOSE_DIR}/.env"

    # Path dynamic replace for DOCKER_ROOT in .env.example
    sed -i "s|DOCKER_ROOT=/home/pleb/nodenation/halfin/docker|DOCKER_ROOT=${COMPOSE_DIR}|g" "${COMPOSE_DIR}/.env"

    sed -i "s/SYNCTHING_PASS=Mudar123/SYNCTHING_PASS=${S_PASS}/g" "${COMPOSE_DIR}/.env"
    sed -i "s/WG_PASSWORD=Mudar123/WG_PASSWORD=${W_PASS}/g" "${COMPOSE_DIR}/.env"
    sed -i "s/POSTGRES_PASSWORD=Mudar123/POSTGRES_PASSWORD=${P_PASS}/g" "${COMPOSE_DIR}/.env"

    cat <<EOF > "${COMPOSE_DIR}/pass_auto_generated.txt"
======================================================
  SENHAS GERADAS AUTOMATICAMENTE (GhostNodes)
======================================================
  Syncthing:                ${S_PASS}
  Wireguard:                ${W_PASS}
  Postgres/Nextcloud DB:    ${P_PASS}

  Guarde estas senhas!
  O arquivo ".env" agora estah configurado.
======================================================
EOF
    echo ""
    echo -e "\e[1;33mATENCAO: SENHAS GERADAS E SALVAS EM ${COMPOSE_DIR}/pass_auto_generated.txt\e[0m"
    cat "${COMPOSE_DIR}/pass_auto_generated.txt"
    echo ""
    sleep 3
fi

echo ""
echo "########### Orquestrando o Resto dos Serviços (Docker Compose) ..."
echo "Subir os containers agora? [y/N]"
read -r compose_resp

if [ "$compose_resp" = "y" ] || [ "$compose_resp" = "Y" ] || [ "$compose_resp" = "s" ] || [ "$compose_resp" = "S" ]; then
    if [ -f "$COMPOSE_FILE" ]; then
        (cd "$COMPOSE_DIR" && docker compose up -d)
    else
        echo "Aviso: docker-compose.yml não encontrado em $COMPOSE_FILE"
    fi
else
    echo "Compose skipped."
fi
########

echo ""
echo "Deseja instalar a interface Web? (Cockpit)"
echo "Instalar? [y/N]"
read -r cockpit
if [ "$cockpit" != "y" ] && [ "$cockpit" != "Y" ] && [ "$cockpit" != "s" ] && [ "$cockpit" != "S" ]; then
    echo "Cockpit skipped."
    exit 0
fi

echo "######### Instalação do Cockpit ##########"

sudo apt install cockpit -y
sudo systemctl enable cockpit
sudo systemctl start cockpit

echo ""
echo "########## Instalação Concluída ##########"
echo ""
echo "###### Acesse a Interface Web do Cockpit: "
echo "########## Através do endereço ###########"
echo ""
echo "######## http://10.21.21.1:9090 ##########"
