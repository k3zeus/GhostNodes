#!/bin/bash
#
# Installation Script Docker - Halfin Node - Debian Bookworm - v.0.7 20032026 
#
echo "#############################################################"
echo "############ Choose Extra Services to Install ###############"
echo "#############################################################"

echo ""
echo "#"
echo "### You would like to install the services: Docker and Portainer? ###"
echo "#"
echo "Install? [y/N]"

if [ "$GN_AUTO_INSTALL" = "true" ] || [ "${AUTO_INSTALL:-false}" = "true" ]; then
    echo "Auto-install enabled. Proceeding quietly..."
    resp="y"
    cockpit="n"
else
    read resp
fi

if [ "$resp" != "y" ] && [ "$resp" != "Y" ] && [ "$resp" != "s" ] && [ "$resp" != "S" ]; then

echo ""
echo "####### Install Web Interface? (Cockpit) ###"
echo "#"
echo "Install? [y/N]"
        if [ "$GN_AUTO_INSTALL" != "true" ]; then
            read cockpit
        fi
        if [ "$cockpit" != "y" ] && [ "$cockpit" != "Y" ] && [ "$cockpit" != "s" ] && [ "$cockpit" != "S" ]; then
        exit 0
        fi
                #######
                echo "###### Starting Cockpit Install #######"

                sudo apt install cockpit -y
                sudo systemctl enable cockpit
                sudo systemctl start cockpit

                echo "###### Acess the Web Interface in: http://10.21.21.1:9090 ######"
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
echo "########### Orquestrando o Resto dos Serviços (Docker Compose) ..."
#
COMPOSE_FILE="/home/pleb/nodenation/halfin/docker/docker-compose.yml"
if [ -f "$COMPOSE_FILE" ]; then
    cd "$(dirname "$COMPOSE_FILE")"
    docker compose -f "$COMPOSE_FILE" up -d
else
    echo "Aviso: docker-compose.yml não encontrado em $COMPOSE_FILE"
fi
########

echo "Deseja instalar a interface Web? (Cockpit)
                #
                Instalar? [y/N]"
        if [ "$GN_AUTO_INSTALL" = "true" ] || [ "${AUTO_INSTALL:-false}" = "true" ]; then
            cockpit="n"
        else
            read cockpit
        fi
        if [ "$cockpit" != "y" ] && [ "$cockpit" != "Y" ] && [ "$cockpit" != "s" ] && [ "$cockpit" != "S" ]; then
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
