#!/bin/sh
#
# Script de instalação do Node Halfin - v0.2
#

#echo "##### Atualizando o Sistema #####"
#sudo apt update && sudo apt upgrade -y

#echo "##### Instalando as Ferramentas Básicas #####"
#sudo apt install htop vim net-tools nmap tree lm-sensors openssh-server iptraf-ng -y

#echo "###### Update e Upgrade de firmwares do sistema ######"
#
#sudo fwupdmgr refresh
#
# Update
#sudo fwupdmgr update -y

echo "##### criando Aliases #####"
echo '# Agora ls é colorido, frufru.
alias ls="ls -la --color"
# IP mais detalhado
alias ip="ip -c -br -a"
# Update simples
alias update="sudo apt update && sudo apt upgrade"
# Verificando Portas
alias ports="sudo netstat -tulanp"
# Mostrando tamanho dos arquvios
alias filesize="du -sh * | sort -h"
# Ultimos comandos
alias gh="history|grep"
# ?
alias nf="neofetch"
# cd ..
alias ..="cd .."
#
alias c="clear"
# VIM
alias vi="vim"
# Sudo
alias root="sudo -i"
#
' >> $HOME/.bash_aliases

#echo "###### Atualizando ########"

echo "###### Configurando Comando Global e MOTD ######"
INSTALL_DIR="/usr/local/bin"
CMD_NAME="ghostnode"
MOTD_SCRIPT="/etc/profile.d/ghostnode-motd.sh"
# Assumindo que o pos_install.sh e o menu.sh estão com a estrutura original do github
MENU_SRC="$(cd "$(dirname "$0")/.." && pwd)/menu.sh"

echo "-> Criando symlink global para menu.sh..."
sudo ln -sf "$MENU_SRC" "$INSTALL_DIR/$CMD_NAME"
# Garante que seja executável
sudo chmod +x "$MENU_SRC"

echo "-> Criando MOTD no login..."
sudo bash -c "cat > \"$MOTD_SCRIPT\" << 'MOTD'
#!/bin/bash
# ghostnode MOTD — exibido em todo login de shell interativo

[[ \$- != *i* ]] && return 0

BOLD=\"\e[1m\"; RESET=\"\e[0m\"; DIM=\"\e[2m\"
GREEN=\"\e[32m\"; CYAN=\"\e[36m\"; YELLOW=\"\e[33m\"; WHITE=\"\e[97m\"

# Temperatura
TEMP=\"N/A\"
for TFILE in /sys/class/thermal/thermal_zone0/temp /sys/devices/virtual/thermal/thermal_zone0/temp; do
    [ -f \"\$TFILE\" ] && TEMP=\"\$(( \$(cat \"\$TFILE\") / 1000 ))°C\" && break
done

printf \"\n\"
printf \"\${BOLD}\${CYAN}\"
printf \"  ╔══════════════════════════════════════════════════════════════╗\n\"
printf \"  ║ ════════════════════════════════════════════════════════════ ║\n\"
printf \"  ║   ██████╗ ██╗  ██╗ ██████╗  ██████╗ ████████╗                ║\n\"
printf \"  ║  ██╔════╝ ██║  ██║██╔═══██╗██╔════╝ ╚══██╔══╝                ║\n\"
printf \"  ║  ██║  ███╗███████║██║   ██║╚█████╗     ██║                   ║\n\"
printf \"  ║  ██║   ██║██╔══██║██║   ██║ ╚═══██╗    ██║                   ║\n\"
printf \"  ║  ╚██████╔╝██║  ██║╚██████╔╝██████╔╝    ██║                   ║\n\"
printf \"  ║   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝     ╚═╝                   ║\n\"
printf \"  ║ ════════════════════════════════════════════════════════════ ║\n\"
printf \"  ║      ███╗   ██╗ ██████╗ ██████╗ ███████╗███████╗             ║\n\"
printf \"  ║      ████╗  ██║██╔═══██╗██╔══██╗██╔════╝██╔════╝             ║\n\"
printf \"  ║      ██╔██╗ ██║██║   ██║██║  ██║█████╗  ███████╗             ║\n\"
printf \"  ║      ██║╚██╗██║██║   ██║██║  ██║██╔══╝  ╚════██║             ║\n\"
printf \"  ║      ██║ ╚████║╚██████╔╝██████╔╝███████╗███████║             ║\n\"
printf \"  ║      ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝╚══════╝             ║\n\"
printf \"  ║                                                              ║\n\"
printf \"  ╠══════════════════════════════════════════════════════════════╣\n\"
printf \"\${RESET}\"
printf \"  \${DIM}║\${RESET}  \${YELLOW}🌡  Temp  :\${RESET} %-15s  \${DIM}│\${RESET}  \${CYAN}📅  Data  :\${RESET} %-16s  \${DIM}║\${RESET}\n\" \"\$TEMP\" \"\$(date '+%d/%m/%Y %H:%M')\"
printf \"  \${DIM}║\${RESET}  \${WHITE}💻  Host  :\${RESET} %-15s  \${DIM}│\${RESET}  \${GREEN}⏱   Uptm  :\${RESET} %-16s  \${DIM}║\${RESET}\n\" \"\$(hostname)\" \"\$(uptime -p 2>/dev/null | sed 's/up //' | cut -c1-16)\"
printf \"  \${DIM}║\${RESET}  \${WHITE}👤  User  :\${RESET} %-15s  \${DIM}│\${RESET}  \${CYAN}💾  Disco :\${RESET} %-16s  \${DIM}║\${RESET}\n\" \"\$(whoami)\" \"\$(df -h / 2>/dev/null | awk 'NR==2{print \$3\"/\"\$2\" (\"\$5\")\"}')\"
printf \"\${BOLD}\${CYAN}\"
printf \"  ╠══════════════════════════════════════════════════════════════╣\n\"
printf \"  ║                                                              ║\n\"
printf \"  ║  \${RESET}\${BOLD}\${WHITE}%-58s\${RESET}\${BOLD}\${CYAN}  ║\n\" \"Execute ghostnode para abrir o menu do sistema.\"
printf \"  ║                                                              ║\n\"
printf \"  ╚══════════════════════════════════════════════════════════════╝\n\"
printf \"\${RESET}\n\"
MOTD"

sudo chmod +x "$MOTD_SCRIPT"

# ── Verifica se /usr/local/bin está no PATH ───────────────────────────────────
if ! echo "$PATH" | grep -q "/usr/local/bin"; then
    if ! grep -q "/usr/local/bin" /etc/environment 2>/dev/null; then
        sudo sed -i 's|PATH="|PATH="/usr/local/bin:|' /etc/environment 2>/dev/null || true
    fi
fi

# Link secundário para compatibilidade caso o pleb use sudo
if [ -d /root ]; then
    sudo ln -sf "$INSTALL_DIR/$CMD_NAME" /root/ghostnode 2>/dev/null || true
fi
if id pleb &>/dev/null && [ -d /home/pleb ]; then
    sudo ln -sf "$INSTALL_DIR/$CMD_NAME" /home/pleb/ghostnode 2>/dev/null || true
fi

echo ""
echo "Execute: source ~/.bashrc para aplicar os aliases, ou reinicie a sessão para ver o MOTD!"