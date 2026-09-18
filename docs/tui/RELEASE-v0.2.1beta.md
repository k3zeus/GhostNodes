# TUI v0.2.1beta

- Data: 2026-09-14
- Base: v0.2beta
- Estado: baseline registrada antes da auditoria de privilegios dos menus.

## Escopo da versao

Esta versao preserva o visual v0.2beta e abre a auditoria TDD para garantir que cada rota do menu:

1. executa leitura sem elevar privilegio quando isso e suficiente;
2. solicita sudo uma vez, de forma explicita, antes de uma operacao que exige administracao;
3. reutiliza somente o ticket sudo ja confirmado durante a sessao;
4. nao grava estado de execucao em diretorios de codigo pertencentes a root;
5. nao executa instalacao, reinicio, desligamento ou mudanca de rede durante TDD de navegacao.

## Evidencia que iniciou a auditoria

O submenu 2.1 tentou gravar log e banco de Wi-Fi sob a arvore do projeto sem permissao para o operador. O erro confirma que a separacao entre codigo, estado do usuario e privilegio de NetworkManager precisa ser verificada ponta a ponta.
