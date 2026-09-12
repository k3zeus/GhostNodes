# SDD/TDD — Seleção determinística do staging

## Fato confirmado

O bootstrap criava `/tmp/ghostnodes_var` antes do download. A busca genérica por diretórios `ghostnodes*` podia selecionar esse diretório temporário no lugar da raiz real `GhostNodes-main` do arquivo baixado. O resultado observado é staging sem `halfin/lib/init.sh`, `var/auto.sh` e `pre_install.sh`.

## Correção

O bootstrap seleciona exclusivamente `/tmp/${GN_REPO_DIR_NAME}` e exige os sentinelas `halfin/lib/init.sh` e `var/auto.sh` antes de mover a árvore para staging. Qualquer conteúdo inesperado falha antes de abrir opções de instalação.

## TDD

- Regressão estática: não há busca genérica por `ghostnodes*`.
- Regressão estática: a raiz exata e os dois sentinelas são exigidos.
- Validação física pendente: executar somente download/seleção na VM após confirmação da nova chave SSH.
## Arquitetura Halfin

O Halfin Base não possui limitação de arquitetura no instalador. O registro genérico aceita Debian, Ubuntu e Armbian em `arm64` ou `x86_64`. O perfil protegido Orange Pi continua específico por suas características de hardware, mas não bloqueia a base em AMD64. Rádios AP/cliente são validados na etapa de rede e constituem requisito físico separado.
