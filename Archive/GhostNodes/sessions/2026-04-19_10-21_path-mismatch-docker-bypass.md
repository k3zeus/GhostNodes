---
title: "Correções Sistêmicas de Path Mismatch e Automação Docker"
date: "2026-04-19"
type: "bugfix, sysadmin, docker"
status: "concluído"
---

# Resumo da Sessão

Esta sessão concentrou-se inteiramente na cura de um efeito cascata que estava destruindo múltiplos sub-elementos da instalação GhostNodes / Halfin, referenciado como "Path Mismatch" provocado por uma má localização de varáveis em scripts e falhas na automação de inputs interativos.

## 🎯 Objetivo Declarado
Atender à solicitação do Comandante de corrigir o sistema auto-download via "curl" onde:
1. As ferramentas extras e Containers Docker (Portainer, Heimdall, Syncthing) não se instalavam corretamente.
2. A cópia do diretório central do Halfin não se ancorava corretamente, causando erros de atalho de "File Not Found".
3. O Menu da Centralização `ghostnode` fechava/destruía seu design (TUI quebrado) pela falta da pasta `lib/`.

## 🛠️ Modificações Realizadas

### 1. `halfin/ghostnode` (TUI e Core Paths)
* **O Bug Raiz:** O módulo definia `_GN_ROOT` usando `dirname "${BASH_SOURCE[0]}"`. Ao ser instalado globalmente (i.e. `/usr/local/bin/ghostnode`), o `dirname` virava `/usr/local/bin`, impossibilitando as injeções das propriedades Modulares via `source lib/init.sh`.  Em segunda instância, a `HALFIN_DIR` esperava basear-se em `/home/pleb/halfin` cego.
* **Solução Implementada:** Troca total na base da variável determinando o path original verdadeiro do usuário: `HALFIN_DIR="/home/pleb/nodenation/halfin"`. Substituído a invocação do bash pelo path direto real do TUI (`_GN_ROOT="$HALFIN_DIR"`). Devidamente "Root-Safe", preparado para updates de string de "pleb" pelo engine via regex.

### 2. `halfin/docker/docker.sh` (Auto Bypass e Compositor)
* **O Bug Raiz:** O arquivo de deploy do Docker tinha `read resp` hardcoded que não admitia bypass. Ferramentas rodando por baixo dos panos pelo Pipeline de Pipe Catcher (`curl | sudo bash`) injetavam caracteres ocultos vazios bloqueando e ignorando o download do Docker sem log aparente. O Orquestrador também **não executava o arquivo docker-compose** principal.
* **Solução Implementada:** Adicionado uma injeção explícita suportando a detecção passiva de `"GN_AUTO_INSTALL=true"`. Se o Pipeline detecta o bootstrap, ele descarta todas as perguntas `y/N` e baixa imediatamente tudo de forma agressiva. Ao final do deploy local, adicionado um gatilho engatilhado chamando `docker compose -f path_dinamico up -d`, subindo instantaneamente o Swarm Completo.

### 3. `halfin/pre_install.sh` (Globais)
* **Ajuste Menor:** Propagado a Flag master de `GN_AUTO_INSTALL` próximo as globais para unificar a compatibilidade de silenciamento.

## 🧪 Gates Validados
- [x] Pre-planejamento aprovado via SDD framework.
- [x] Lógica implementada limpa seguindo referencial de substituição sed posterior dos sub-scripts.
- [x] Lote Commitado via Git-Hybrid Padrão.

## 🔗 Tarefas Conectadas e Next Steps
- A testagem de ponta-a-ponta manual deve ser validada na branch `dev` na nova estrutura ou placa Raspberry Zero usando o Payload Automático do CURL atualizado.
