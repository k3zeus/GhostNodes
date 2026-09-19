# 🔧 SwissKnife OPZ3 — Estação de Auditoria de Rede

Ferramenta de reconhecimento e auditoria de rede (Wi-Fi + LAN) para rodar em um **Orange Pi Zero 3**. Seis fases automatizadas — survey wireless, escuta passiva, descoberta de hosts, scan profundo, checagem de serviços e relatório consolidado (Markdown + HTML).

> Para a especificação técnica completa (arquitetura, limitações de hardware documentadas, modelo de risco e regras de engajamento), veja **[SPECS.md](./SPECS.md)**.

## ⚖️ Antes de começar

Audite **apenas redes que você administra** ou com **autorização por escrito**. No Brasil, varredura/intrusão sem autorização pode enquadrar na Lei 12.737/2012, e dados coletados de terceiros entram na LGPD. Texto completo em SPECS.md.

## 🧰 Hardware necessário

| Item | Recomendação |
|---|---|
| Placa | Orange Pi Zero 3 — **variante de 1,5GB RAM** |
| Armazenamento | MicroSD 32GB+, classe 10 ou superior |
| Adaptador Wi-Fi USB | Chipset com suporte a modo monitor no kernel: **MT7612U** (ex. Alfa AWUS036ACHM) ou **MT7601U**. RTL8812AU exige dkms — evite no começo |
| Fonte | USB-C 5V/3A |
| Rede | Porta Ethernet onboard (Gigabit) dedicada à LAN auditada |

⚠️ O Wi-Fi onboard da placa (chip Unisoc UWE5622/AW859A) **não faz modo monitor/injeção de forma confiável** — o adaptador USB externo acima é obrigatório para a fase de survey wireless, não opcional. Detalhes em SPECS.md.

## 🚀 Instalação rápida

1. Baixe a imagem **Ubuntu Server ou Debian** para Orange Pi Zero 3 diretamente do [wiki oficial](http://www.orangepi.org/orangepiwiki/index.php/Orange_Pi_Zero_3) — confira se há um link específico para a variante **1,5GB**; imagens genéricas às vezes não reconhecem essa densidade de RAM corretamente (é um problema documentado no bootloader/DTB, não bug do seu cartão).
2. Grave com [balenaEtcher](https://etcher.balena.io/) (não use `dd` a menos que saiba o que está fazendo).
3. Primeiro boot: conecte um monitor/teclado ou use os pinos UART. Login padrão costuma ser `root` / `1234` (Armbian) — o sistema força a troca de senha e criação de usuário no primeiro login. Se usar uma imagem Orange Pi OS oficial, o padrão costuma ser `oem` / `oem`. **Confirme sempre na documentação da imagem específica que você baixou.**
4. Conecte a placa à internet (Ethernet) e rode:
   ```bash
   git clone <este-repositorio> ~/swissknife-src
   cd ~/swissknife-src
   chmod +x install.sh audit-all.sh serve-reports.sh services/*.sh
   ./install.sh
   ```
5. Identifique seu adaptador Wi-Fi USB:
   ```bash
   iw dev
   # normalmente aparece como wlx<MAC>, ex.: wlx00c0ca123456
   ```

## ▶️ Uso

```bash
tmux new -s audit
export IFACE_LAN=eth0          # interface conectada à LAN auditada
export IFACE_WLAN=wlx00c0ca... # seu adaptador USB (deixe vazio para autodetecção)
export SCAN_RANGE=192.168.1.0/24   # opcional — autodetectado a partir de IFACE_LAN
export VULN=0                  # 1 = scripts --script vuln do nmap, SÓ com autorização por escrito

./audit-all.sh
```

Cada fase também roda isoladamente (útil para depurar ou repetir só um passo):

```bash
./services/01-wireless-survey.sh reports/minha-rodada
./services/02-passive-listen.sh  reports/minha-rodada
./services/03-discovery.sh       reports/minha-rodada
./services/04-deep-scan.sh       reports/minha-rodada
./services/05-service-checks.sh  reports/minha-rodada
python3 services/06-generate-report.py reports/minha-rodada
```

Para publicar os relatórios na sua rede de gerência (nunca na rede auditada):

```bash
./serve-reports.sh
```

## 📁 Estrutura

```
swissknife-opz3/
├── README.md
├── SPECS.md
├── install.sh              # dependências, zram, NetworkManager, Caddy
├── audit-all.sh             # orquestrador — roda as 6 fases em sequência
├── serve-reports.sh         # publica reports/ via Caddy na interface de gerência
└── services/
    ├── 01-wireless-survey.sh
    ├── 02-passive-listen.sh
    ├── 03-discovery.sh
    ├── 04-deep-scan.sh
    ├── 05-service-checks.sh
    └── 06-generate-report.py
```

## ⚠️ Limitações conhecidas deste hardware

- **1 única porta USB 2.0** — fica dedicada ao adaptador Wi-Fi de auditoria; não sobra porta para storage externo (por isso tudo grava no próprio microSD).
- **Wi-Fi onboard sem modo monitor** — usado só como interface de gerência (SSH), nunca para a fase de survey.
- **1,5GB de RAM** é justo para nmap + tshark + kismet rodando perto um do outro — o `install.sh` configura `zram` para dar folga sem desgastar o cartão SD.
- Há um bug documentado do driver Wi-Fi onboard (Unisoc UWE5622) que derruba a conexão após um tempo, exigindo `sudo rmmod/modprobe` ou reboot. Não afeta a auditoria em si (que usa o adaptador USB + Ethernet), só o acesso de gerência via Wi-Fi onboard.

## 📈 Roadmap

1. Kismet contínuo (`:2501`) → IDS wireless com alerta de rogue AP/evil twin.
2. Suricata no `eth0` → IDS de tráfego com regras Emerging Threats.
3. Inventário SNMP/mDNS periódico com diff entre auditorias.
4. Integração com Shodan CLI/dnsrecon para checar exposição externa.
5. Lynis agendado para auto-auditoria da própria placa.
6. Notificação Telegram/e-mail ao fim de cada rodada.
