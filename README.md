# Ghost Nodes - NodeNation

<div align="center">
  <img src="https://img.shields.io/badge/Status-Beta-blue.svg" alt="Status">
  <img src="https://img.shields.io/badge/Platform-OrangePi%20%7C%20RaspberryPi-ff69b4.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Script-Bash-4EAA25.svg?logo=gnu-bash" alt="Bash">
</div>

<br>

**NodeNation** is a complete and modular ecosystem designed to facilitate the installation, configuration, and monitoring of local infrastructures for digital protection and sovereignty.

## 🛠 Quick Installation

```bash
curl -fsSL https://raw.githubusercontent.com/greycitizen/ghostnodes/refs/heads/main/nodenation | sudo bash
```

Or download the complete project:

```bash
wget https://github.com/greycitizen/ghostnodes/archive/refs/tags/beta.tar.gz
tar -xzf beta.tar.gz
mv ghostnodes-beta nodenation
sudo bash nodenation/nodenation
```

## EStructure

```
nodenation/
├── nodenation              ← root menu + pre-install + hardware detection
├── var/
│   └── hardware.env        ← compatibility detected (generated at runtime)
├── halfin/                 ← Subproject: OrangePi AP/Router
│   ├── lib/                ← modular library(cores, UI, banner, log)
│   ├── tools/              ← System and network tools
│   ├── var/                ← globals.env, banco wifi, logs
│   ├── docker/
│   ├── ghostnode           ← Halfin Node control command
│   └── install.sh
├── satoshi/                ← Subproject: Bitcoin Node
│   ├── scripts/
│   └── install.sh
├── nick/                   ← Coming Soon
├── adam/                   ← Coming Soon
├── fiatjaf/                ← Coming Soon
├── nash/                   ← Coming Soon
└── craig/                  ← Coming Soon
```

## 📦 Projects

Ghost Nodes is divided into modular subprojects. Currently in operation and under development are:

- [x] **Halfin Node:** The backbone. Focused on initial setup, hardware diagnostic tools, Wi-Fi, and stack installation via Docker and Portainer on boards like the Orange Pi Zero 3.
- [x] **Satoshi Node:** Dedicated purely to the Bitcoin base layer. Reliably downloads binaries (Bitcoin Core or Knots), supports x86 and ARM architectures, and starts the synchronization panel.
- [ ] **Nick Node:** *(Under development)*
- [ ] **Nash Node:** *(Under development)*
- [ ] **Adam Node:** *(Under development)*
- [ ] **Fiatjaf Node:** *(Under development)*
- [ ] **Craig Node:** *((For fun and Lying)*

---

## Modular Library (`halfin/lib/`)

All project scripts import the library with one line:

```bash
source "${HALFIN_DIR}/lib/init.sh"
```

Available Modules:

- `colors.sh` — color palette and symbols
- `ui.sh` — interface functions (sep, section, step_*, confirm...)
- `banner.sh` — banner, header, status_bar, print_motd
- `log.sh` — centralized logging system

## 🎮 Global Variables (`halfin/var/globals.env`)

All paths, users, and settings are centralized in globals.env. No hardcoded paths — everything uses variables.

---

<p align="center">
  <i>Built under maximum Sovereignty and Privacy.</i><br>
  <b>Ghost Nodes - NodeNation © 2026</b>
</p>



---
portuguese
# Ghost Nodes - NodeNation

<div align="center">
  <img src="https://img.shields.io/badge/Status-Beta-blue.svg" alt="Status">
  <img src="https://img.shields.io/badge/Platform-OrangePi%20%7C%20RaspberryPi-ff69b4.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Script-Bash-4EAA25.svg?logo=gnu-bash" alt="Bash">
</div>

<br>

O **NodeNation** é um ecossistema completo e modular desenhado para facilitar a instalação, configuração e o monitoramento de infraestruturas locais para proteção e soberania digital.

## 🛠 Instalação Rápida

```bash
curl -fsSL https://raw.githubusercontent.com/greycitizen/ghostnodes/refs/heads/beta/nodenation | sudo bash
```

Ou baixe o projeto completo:

```bash
wget https://github.com/greycitizen/ghostnodes/archive/refs/tags/beta.tar.gz
tar -xzf beta.tar.gz
mv ghostnodes-beta nodenation
sudo bash nodenation/nodenation
```

## Estrutura

```
nodenation/
├── nodenation              ← menu raiz + pre-install + detecção de hardware
├── var/
│   └── hardware.env        ← compatibilidade detectada (gerado em runtime)
├── halfin/                 ← Subprojeto: AP/Roteador OrangePi
│   ├── lib/                ← biblioteca modular (cores, UI, banner, log)
│   ├── tools/              ← ferramentas de sistema e rede
│   ├── var/                ← globals.env, banco wifi, logs
│   ├── docker/
│   ├── ghostnode           ← comando de controle do Halfin Node
│   └── install.sh
├── satoshi/                ← Subprojeto: Bitcoin Node
│   ├── scripts/
│   └── install.sh
├── nick/                   ← Coming Soon
├── adam/                   ← Coming Soon
├── fiatjaf/                ← Coming Soon
├── nash/                   ← Coming Soon
└── craig/                  ← Coming Soon
```

## 📦 Projetos

O Ghost Nodes é dividido em subprojetos modulares. Os atualmente em operação e em desenvolvimento são:

- [x] **Halfin Node:** A espinha dorsal. Focado no setup inicial, ferramentas de diagnóstico de hardware, Wi-Fi e instalação da stack via Docker e Portainer em placas como a Orange Pi Zero 3.
- [x] **Satoshi Node:** Dedicado puramente à camada base do Bitcoin. Baixa binários confiavelmente (Bitcoin Core ou Knots), suporta arquiteturas x86 e ARM, e inicia o painel de sincronização.
- [ ] **Nick Node:** *(Under development)*
- [ ] **Nash Node:** *(Under development)*
- [ ] **Adam Node:** *(Under development)*
- [ ] **Fiatjaf Node:** *(Under development)*
- [ ] **Craig Node:** *(Para se divertir e apagar em seguida)*

---

## Biblioteca Modular (`halfin/lib/`)

Todos os scripts do projeto importam a biblioteca com uma linha:

```bash
source "${HALFIN_DIR}/lib/init.sh"
```

Módulos disponíveis:

- `colors.sh` — paleta de cores e símbolos
- `ui.sh` — funções de interface (sep, section, step_*, confirm...)
- `banner.sh` — banner, header, status_bar, print_motd
- `log.sh` — sistema de log centralizado

## 🎮 Variáveis Globais (`halfin/var/globals.env`)

Todos os paths, usuários e configurações estão centralizados em `globals.env`.
Nenhum script hardcoda caminhos — tudo usa variáveis.

---

<p align="center">
  <i>Construído sob máxima Soberania e Privacidade.</i><br>
  <b>Ghost Nodes - NodeNation © 2026</b>
</p>
