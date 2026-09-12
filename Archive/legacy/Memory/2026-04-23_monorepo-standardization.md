# 2026-04-23 — Monorepo standardization worklog

## Objective

Padronizar o monorepo GhostNodes para bootstrap unico, fluxos shell reproduziveis, web stack validavel e onboarding de novos subprojetos.

## What changed

- `halfin/install.sh`: corrigido para Bash strict mode real
- `halfin/pre_install.sh`: corrigida precedencia do fallback de staging
- `halfin/extras/webapp.sh`: refeito para source robusto, build do frontend e service systemd
- `satoshi/pre_install.sh`: criado
- `satoshi/install.sh`: refeito com auto mode, systemd, rpc env e verificacao
- `nodenation`: automatizacao ajustada para `satoshi`
- `menu.sh`: virou wrapper para `nodenation`
- `web/frontend`: requests padronizadas via `src/api.js`, `ApplicationsTab` restaurada, build validado
- `web/docker-compose.yml`: contexts corrigidos e RPC host padronizado para `host.docker.internal`

## Durable findings

- `git status` falha por corrupcao de objetos tree em `HEAD`; commits existem, trees faltam
- havia muitos artefatos `sync-conflict` e entrypoints legados competindo
- `menu.sh` era legado; `nodenation` e o manager correto
- `satoshi` nao tinha `pre_install.sh`, quebrando o auto-flow
- o frontend estava preso a `http://localhost:8000`

## Validation evidence

- `python -m py_compile` do backend passou
- `npm run build` do frontend passou apos reparo de dependencias
- `docker compose -f web/docker-compose.yml config` passou

## Remaining risks

- testes shell nativos no host Windows/WSL seguem limitados pelo ambiente
- validacao E2E completa Debian/OrangePi ainda depende de execucao em Docker Linux ou hardware alvo
- metadata Git continua corrompida e precisa reparo fora desta rodada
