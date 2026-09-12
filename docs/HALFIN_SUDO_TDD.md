# TDD — Elevação única de privilégios no bootstrap

## Objetivo

Permitir a execução de `curl -fsSL …/nodenation | bash` sem `sudo su` e sem repetir senha, mantendo todas as etapas Halfin no mesmo processo root.

## Contrato

1. O bootstrap em usuário comum chama `sudo -v` uma vez.
2. Após a autenticação, ele se reexecuta com `sudo -n`; uma segunda senha é falha explícita, nunca prompt oculto.
3. O processo root chama `pre_install.sh` e cada `etapa_*` por `bash`, preservando o UID root herdado.
4. Scripts chamados por etapas não recebem elevação parcial; eles executam no processo root já estabelecido.
5. A execução por pipe ainda transfere o script para `/tmp` e usa o TTY original antes da elevação.

## Casos TDD

| ID | Caso | Evidência esperada |
| --- | --- | --- |
| PRIV-01 | Usuário comum em terminal | Um único prompt sudo, seguido de reexecução `sudo -n`. |
| PRIV-02 | Todas as `etapa_*` Halfin | `require_root` no início e UID root herdado pelos subprocessos. |
| PRIV-03 | Sem TTY | Erro explícito antes de qualquer instalação. |
| PRIV-04 | `TERM` ausente | TUI renderiza sem erro. |

A validação física usa somente `--detect-hw`; não cria usuário, altera rede ou instala pacotes.
## Evidência física — Orange Pi `.92`

Em 2026-09-12, com o cache sudo invalidado antes do teste, o usuário comum executou a cópia temporária do bootstrap com `--detect-hw`. O processo mostrou uma única solicitação de autorização, reexecutou-se como root e detectou OrangePi Zero3 arm64 / Debian Bookworm com retorno `0`. Nenhum usuário, pacote, serviço ou configuração de rede foi alterado por esse teste.

**Resultado:** PRIV-01 e PRIV-02 aprovados no equipamento; PRIV-03 e PRIV-04 permanecem cobertos pelos testes físicos anteriores do bootstrap.
