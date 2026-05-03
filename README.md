# GhostNodes

Orquestrador monorepo para instalacao soberana via `curl | bash`, dashboard TUI padronizado e camada web de controle para subprojetos de infraestrutura.

## Estado atual

- `nodenation`: bootstrap manager e ponto de entrada principal.
- `halfin/`: node de networking/AP router com fluxo automatizado e extras.
- `satoshi/`: node Bitcoin Core / Knots com pre-install, install e stack docker auxiliar.
- `web/`: backend FastAPI + frontend React para controle remoto.
- `tests/`: validacoes de registry, instalacao e cenarios E2E Debian Bookworm.

## Fluxo recomendado

Em hosts Debian/Ubuntu limpos:

```bash
curl -fsSL https://raw.githubusercontent.com/k3zeus/GhostNodes/refs/heads/main/nodenation | sudo bash
```

Uso local no repo:

```bash
sudo bash ./nodenation
```

## Padrao do projeto

- Bootstrap unico pelo `nodenation`
- Subprojetos com `pre_install.sh`, `install.sh`, `docker/`, `README`
- TUI com navegacao padronizada: `(1) ...`, `(q) Exit`, `(0) Back`
- Variaveis globais prefixadas com `GN_`
- Shell em `set -euo pipefail`
- Prova antes de declarar pronto: testes, build e checks reproduziveis

## Documentacao

- `ARCHITECTURE.md`
- `PROJECT_BRIEF.md`
- `TECH_PATTERN.md`
- `docs/SUBPROJECT_BLUEPRINT.md`
- `web/WEBAPP_SETUP.md`

## Validacao

- Frontend: `cd web/frontend && npm run build`
- Backend: `python -m py_compile web/backend/main.py web/backend/routers/*.py`
- Shell tests: `bash tests/test_auto_registry.sh`, `bash tests/test_halfin_install.sh`, `bash tests/test_satoshi_install.sh`
- Bootstrap/menu contract: `bash tests/test_nodenation_bootstrap.sh`
- Real bootstrap matrix: `bash tests/e2e/run_bootstrap_matrix.sh`
- Compose parse: `docker compose -f web/docker-compose.yml config`
