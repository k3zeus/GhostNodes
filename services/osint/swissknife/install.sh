#!/usr/bin/env bash
# SwissKnife OPZ3 - Instalador de dependências
# Alvo: Orange Pi Zero 3 (Allwinner H618, 1,5GB RAM), Ubuntu/Debian (Armbian ou Orange Pi OS)
set -uo pipefail   # sem -e: um pacote ausente não deve travar a instalação dos demais

BASE="$HOME/swissknife"
LOG="/tmp/swissknife-install.log"
: > "$LOG"

echo "[*] Atualizando o sistema..."
sudo apt update && sudo apt -y upgrade | tee -a "$LOG"

install_group() {
  local label="$1"; shift
  echo "[*] Instalando grupo: $label"
  if ! sudo apt install -y --no-install-recommends "$@" >>"$LOG" 2>&1; then
    echo "[!] Falha ao instalar o grupo '$label' de uma vez. Tentando pacote a pacote..."
    for pkg in "$@"; do
      if sudo apt install -y --no-install-recommends "$pkg" >>"$LOG" 2>&1; then
        echo "    [+] $pkg"
      else
        echo "    [!] $pkg indisponível nesta imagem/versão — pulei (veja $LOG)."
      fi
    done
  fi
}

install_group "reconhecimento de rede" nmap arp-scan netdiscover nbtscan avahi-utils smbclient snmp
install_group "wireless"               aircrack-ng reaver iw wireless-tools
install_group "captura/análise"        tcpdump tshark p0f
install_group "checagem de serviços"   sslscan ssh-audit whatweb
install_group "utilitários"            jq xmlstarlet tmux git curl python3-pip python3-venv ieee-data lynis

# zram — 1,5GB de RAM é pouco pra nmap + tshark + kismet concorrendo; comprime RAM
# em vez de gravar swap no cartão SD (evita desgaste).
echo "[*] Configurando zram..."
if sudo apt install -y zram-tools >>"$LOG" 2>&1; then
  echo "PERCENT=50" | sudo tee /etc/default/zramswap >/dev/null
  sudo systemctl restart zramswap >>"$LOG" 2>&1 || true
  echo "    [+] zram configurado (50% da RAM)"
else
  echo "    [!] zram-tools indisponível — considere configurar swap manual."
fi

# Estrutura do projeto
mkdir -p "$BASE"/{reports,captures}
echo "[+] Estrutura criada em $BASE"

# NetworkManager: adaptadores USB (nomeados wlx<MAC> pela udev) ficam fora do
# controle do NetworkManager. Isso evita precisar de 'airmon-ng check kill'
# (que mataria o NetworkManager inteiro e derrubaria o wlan0 de gerência).
echo "[*] Configurando NetworkManager para ignorar adaptadores USB de auditoria..."
sudo mkdir -p /etc/NetworkManager/conf.d
sudo tee /etc/NetworkManager/conf.d/10-swissknife-unmanaged.conf >/dev/null <<'EOF'
# Interfaces cujo nome comece com "wlx" (convenção udev para adaptadores USB
# identificados pelo MAC) ficam fora do controle do NetworkManager.
[keyfile]
unmanaged-devices=interface-name:wlx*
EOF
sudo systemctl restart NetworkManager >>"$LOG" 2>&1 || true

# Caddy (repositório oficial via Cloudsmith)
echo "[*] Instalando Caddy..."
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl >>"$LOG" 2>&1
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list >>"$LOG"
sudo apt update >>"$LOG" 2>&1 && sudo apt -y install caddy >>"$LOG" 2>&1

echo ""
echo "[+] Instalação concluída. Log completo em $LOG"
echo "[+] Identifique seu adaptador Wi-Fi USB externo com: iw dev"
echo "[+] Próximo passo: tmux new -s audit && ./audit-all.sh"
