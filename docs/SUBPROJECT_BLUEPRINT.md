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

Todo subprojeto deve aceitar configuracao vinda do `nodenation` por variaveis de ambiente. Isso evita menus paralelos e permite que o mesmo plano seja usado pelo instalador, pelo `ghostnode` e pelo dashboard web.

Variaveis comuns:

- `GN_ROOT`: raiz final do monorepo instalado
- `GN_USER`: usuario operacional padrao
- `GN_AUTO_INSTALL=true`: executa sem novo menu interno
- `GN_INSTALL_MODE`: perfil escolhido pelo manager, por exemplo `standard`, `full` ou `pruned`

Variaveis especificas devem seguir prefixo do subprojeto. Exemplo Satoshi:

- `SATOSHI_VARIANT`: `core` ou `knots`
- `SATOSHI_VERSION`: versao escolhida ou padrao
- `SATOSHI_PRUNE_GB`: limite de prune em GB

Regra: o menu principal escolhe o plano; o `install.sh` executa o plano. O instalador pode ter menu proprio para uso manual, mas nao deve ignorar as variaveis exportadas pelo `nodenation`.

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
- cada subprojeto com servico nativo deve expor no backend: estado do servico, caminho de configuracao, modo instalado e dados minimos para o painel renderizar status sem hardcode legado

## Padrao ghostnode

- usar os mesmos paths e nomes de servico do `install.sh`
- nao assumir `/home/pleb` quando o instalador criou usuario tecnico especifico
- comandos de start/stop devem preferir o service name do subprojeto e manter fallback explicito
- logs exibidos no TUI devem apontar para o arquivo gerado pelo proprio instalador

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
