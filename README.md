# GhostNodes 👻🛰️

> Orquestrador soberano monorepo para infraestrutura self-hosted.  
> Bootstrap via `curl | bash`, TUI padronizado e módulos isolados em Docker.

[![Version](https://img.shields.io/badge/version-2.0.0-cyan?style=flat-square)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-ARM64%20%7C%20x86__64-blue?style=flat-square)](ARCHITECTURE.md)

---

## Instalação Rápida

```bash
# Bootstrap remoto (Debian/Ubuntu limpos)
sudo curl -fsSL https://raw.githubusercontent.com/k3zeus/GhostNodes/refs/heads/main/nodenation | bash

# Local
sudo bash ./nodenation
```

---

## Módulos

### 🟢 Core (Estáveis)

| Módulo | Descrição | Status |
|--------|-----------|--------|
| `nodenation` | Bootstrap manager — ponto de entrada único | ✅ Estável |
| `halfin/` | Node AP/Router — OrangePi Zero 3 — arm64 | ✅ Estável |
| `satoshi/` | Bitcoin Full/Pruned Node — Bitcoin Core/Knots | ✅ Estável |
| `web/` | Dashboard Web — FastAPI + React | ✅ Estável |

### 🧩 Extras (v2.0 — Módulos Adicionais)

> Instaláveis via menu `[e] Extras` no NodeNation ou via CLI.

| Módulo | Descrição | Acesso |
|--------|-----------|--------|
| `vault/` | 🔐 SSH Gateway + Vaultwarden (gerenciador de senhas) | Tailscale / Cloudflare Tunnel |
| `hermes/` | 🤖 AI Assistant — Open WebUI + Telegram Bot | Tailscale / Telegram |
| `tailscale/` | 🌐 Mesh VPN — Subnet Router — acesso remoto seguro | WireGuard P2P |
| `nostr/` | 📡 Relay Nostr Privado — nostr-rs-relay (whitelist) | Tailscale / Cloudflare Tunnel |

### 🔵 Em Desenvolvimento

| Módulo | Descrição |
|--------|-----------|
| `nick/` | Nick Node — Coming Soon |
| `adam/` | Adam Node — Coming Soon |
| `fiatjaf/` | Fiatjaf Node — Coming Soon |
| `nash/` | Nash Node — Coming Soon |
| `craig/` | Craig Node — Coming Soon |

---

## Instalação dos Módulos Extras

### Via Menu (Interativo)
```bash
sudo bash ./nodenation
# → selecione [e] Extras
# → selecione [a] Instalar TODOS, ou [1-4] individual
```

### Via CLI (Headless)
```bash
# Instalar todos (interativo)
sudo bash ./nodenation --extras

# Instalar todos (automático)
sudo bash ./nodenation --extras --yolo

# Ver status dos módulos
sudo bash ./nodenation --extras-status

# Instalar módulo individual
sudo bash vault/install.sh
sudo bash hermes/install.sh
sudo bash tailscale/install.sh
sudo bash nostr/install.sh
```

---

## Mapa de Serviços (v2.0)

| Serviço | Porta Interna | Porta Nginx SSL | Protocolo |
|---------|--------------|-----------------|-----------|
| Vaultwarden | 80 | 8812 | HTTPS |
| Open WebUI (Hermes) | 8080 | 8813 | HTTPS |
| Nostr Relay | 8080 | 8814 | WSS |
| Dashboard | 5173 | — | HTTP |
| Cockpit | 9090 | — | HTTPS |
| Syncthing | 8384 | — | HTTPS |

---

## Padrão do Projeto

- Bootstrap único pelo `nodenation`
- Subprojetos com `pre_install.sh`, `install.sh`, `docker/`, `README.md`
- Módulos extras com `docker/docker-compose.yml`, `docker/.env.example`, `install.sh`
- TUI com navegação padronizada: `(1) ...`, `(q) Exit`, `(0) Back`
- Variáveis globais prefixadas com `GN_`
- Shell em `set -euo pipefail`
- Rede Docker compartilhada: `ghostnet` (external bridge)
- Acesso externo: Cloudflare Tunnel (zero-port) | Acesso interno: Tailscale

---

## Documentação

| Arquivo | Conteúdo |
|---------|----------|
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Arquitetura v2.0, rede, módulos, port map |
| [`PROJECT_BRIEF.md`](PROJECT_BRIEF.md) | Visão geral e filosofia do projeto |
| [`TECH_PATTERN.md`](TECH_PATTERN.md) | Padrões técnicos e stack |
| [`docs/SUBPROJECT_BLUEPRINT.md`](docs/SUBPROJECT_BLUEPRINT.md) | Blueprint para novos subprojetos |
| [`vault/README.md`](vault/README.md) | SSH Gateway + Vaultwarden |
| [`hermes/README.md`](hermes/README.md) | AI Assistant + Telegram |
| [`tailscale/README.md`](tailscale/README.md) | Mesh VPN + Subnet Router |
| [`nostr/README.md`](nostr/README.md) | Nostr Relay Privado |

---

## Validação

```bash
# Frontend
cd web/frontend && npm run build

# Backend
python -m py_compile web/backend/main.py web/backend/routers/*.py

# Shell tests
bash tests/test_auto_registry.sh
bash tests/test_halfin_install.sh
bash tests/test_satoshi_install.sh

# Docker compose
docker compose -f web/docker-compose.yml config

# Módulos extras (lint básico)
bash -n vault/install.sh
bash -n hermes/install.sh
bash -n tailscale/install.sh
bash -n nostr/install.sh
bash -n modules-install.sh
```

---

## Histórico de Versões

| Versão | Data | Mudanças |
|--------|------|----------|
| v2.0.0 | 2026-05-11 | Módulos Extras: Vault, Hermes, Tailscale, Nostr. Menu `[e]` no NodeNation. |
| v1.2.2t | 2026-04-14 | Dashboard Web, testes E2E, Satoshi Node estável. |
| v1.0.0 | 2026-01-01 | Bootstrap inicial, Halfin Node, NodeNation CLI. |

---

*GhostNodes — Sovereignty first. Your hardware, your rules.* 🛰️
