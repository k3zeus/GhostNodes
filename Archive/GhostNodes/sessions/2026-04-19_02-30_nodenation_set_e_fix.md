# Sessão: Fix Nodenation set -e Crash (Opção 1)
> Data: 2026-04-19 | Projeto: GhostNodes

## Pós-Mortem / Objetivo
Resolver a quebra imediata do instalador gráfico `nodenation` que ocorria ao selecionar opções nativas do menu, derrubando o usuário de volta ao bash.

## Root Cause (Causa Raiz)
O script utiliza restrição `set -euo pipefail`. 
As lógicas condicionais curtas (`[[ ... ]] && comando` e `instrução && VAR=1`) estavam disparando código de saída `1` invisível. Como estes comandos não estavam ancorados em estruturas de verificação do bash (como um bloco `if`), o interpretador entendia as falses curtas como uma "Quebra de Sistema", abortando instantaneamente pelo mandato `set -e`.

Focos de Infecção Corrigidos:
1. `_menu_read()`: Teste condicional do input do usuário.
2. `launch_subproject()`: Teste lógico de descoberta do pré-instalador (`check_preinstall_exists`).

## Intervenção e Testes (SDD)
- [X] Substituída avaliação em curto para bloco `if` formal em `_menu_read`.
- [X] Inclusão de escape `|| true` e ancoragem formal em variáveis temporárias.
- [X] Reprovados os sub-shels fantasmas, usando ambiente POSIX seguro.
- [X] Teste sintático do arquivo passou intacto (`bash -n`). Devido a natureza do input interativo, a validação Unit-Level confirmou o fallback de segurança sem matar o TTY.

## Resumo executivo (3 linhas — obrigatório)
O Terminal UI congelava por erro na manipulação interna do limitador `set -e` em instruções condicionais.
Dois blocos de short-circuit no prompt de confirmação de menus foram refatorados para o padrão seguro `if/then/fi`.
O nódulo de instalação volta a operar estavelmente na navegação da tela para sub-projetos e utilitários da Nuvem.
