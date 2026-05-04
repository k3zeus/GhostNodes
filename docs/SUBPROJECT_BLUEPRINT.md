# GhostNodes Subproject Blueprint

## Objetivo

Padronizar qualquer novo subprojeto do monorepo para que ele entre no bootstrap do `nodenation`, siga a UX TUI comum e tenha prova minima antes de ser tratado como pronto.

## Estrutura minima

Cada subprojeto novo deve nascer com:

- `<project>/pre_install.sh`
- `<project>/install.sh`
- `<project>/README.md` ou `README.txt`
- `<project>/docker/` quando houver servicos containerizados
- `<project>/extras/` para extensoes opcionais
- entradas correspondentes em `var/auto.sh`

## Contrato de instalacao

### `pre_install.sh`

Responsabilidades:

- garantir usuario/runtime
- instalar dependencias base
- preparar diretorios persistentes em `${GN_ROOT}`
- nao assumir paths legados fora de `${GN_ROOT}`

Regras:

- `#!/bin/bash`
- `set -euo pipefail`
- source de `halfin/lib/init.sh` ou biblioteca comum equivalente
- deve funcionar tanto via staging quanto depois do move final

### `install.sh`

Responsabilidades:

- instalar binarios/servicos do subprojeto
- gravar configuracoes persistentes
- registrar `systemd` quando aplicavel
- expor um modo automatico por `GN_AUTO_INSTALL=true`

## Padrao TUI

Todo menu novo deve seguir:

- titulo com `main_banner`
- opcoes numeradas iniciando em `1`
- `0` para voltar
- `q` para sair
- mensagens claras do que sera alterado

Exemplo esperado:

```text
(1) Install X
(2) Configure X
(q) Exit
(0) Back
```

## Padrao web

- backend em `web/backend`
- frontend em `web/frontend`
- chamadas sempre por `/api/...` ou `VITE_GHOSTNODES_API_BASE`
- builds precisam funcionar tanto no host quanto em Compose
- se o backend rodar em container e o node no host, preferir `host.docker.internal` + `host-gateway`

## Padrao de testes

Minimo obrigatorio por subprojeto:

- parse/syntax do shell
- checagem de funcoes obrigatorias
- registry match em `var/auto.sh`
- cenario Debian Bookworm reproducivel em Docker quando possivel

## Nao-goals

- nao duplicar managers paralelos ao `nodenation`
- nao criar caminhos hardcoded tipo `/home/pleb/halfin`
- nao misturar artefatos temporarios e arquivos de release na raiz

## Checklist de entrada para novos nodes

1. Registrar hardware/os em `var/auto.sh`
2. Criar `pre_install.sh`
3. Criar `install.sh`
4. Padronizar menu TUI
5. Documentar `curl | bash` e uso local
6. Adicionar teste dedicado
7. Validar no minimo em Debian Bookworm
