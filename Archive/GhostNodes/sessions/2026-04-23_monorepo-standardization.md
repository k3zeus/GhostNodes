# 2026-04-23 - Monorepo standardization

## Objective

Padronizar GhostNodes como monorepo com bootstrap unico, TUI consistente, Satoshi/Halfin instalaveis e stack web validavel.

## Key findings

- `git status` segue quebrado por objetos tree ausentes em `HEAD`
- `var/auto.sh` quebrava parsing por usar `|` como delimitador interno
- `halfin/lib/*.sh` estavam corrompidos por CRLF e `colors.sh` duplicado incorretamente
- `satoshi` nao tinha `pre_install.sh`
- frontend dependia de `http://localhost:8000` e falhava em cenarios shell/docker

## What was changed

- correcoes shell em `halfin`, `satoshi`, `nodenation` e libs compartilhadas
- stack web padronizada para host mode e compose mode
- docs/blueprint adicionados para onboarding de novos subprojetos
- teste dedicado do `satoshi` adicionado
- artefatos `sync-conflict` e temporarios movidos para `Archive/GhostNodes/obsolete/2026-04-23/`

## Proof

- `python -m py_compile ...` passou
- `npm run build` em `web/frontend` passou
- `docker compose -f web/docker-compose.yml config` passou
- `docker compose -f web/docker-compose.yml build` passou
- `docker compose -f web/docker-compose.yml up -d` subiu e respondeu:
  - `http://localhost:8000/api/health`
  - `http://localhost:80`
- testes Debian Bookworm em Docker passaram:
  - `tests/test_auto_registry.sh`
  - `tests/test_halfin_install.sh`
  - `tests/test_satoshi_install.sh`

## Remaining risks

- Git metadata precisa reparo dedicado
- validacao em hardware real OrangePi Zero 3 ainda deve ser executada fora deste host Windows
