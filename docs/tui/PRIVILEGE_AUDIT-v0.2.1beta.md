# Auditoria de privilegios dos menus

Data: 2026-09-14
Versao: TUI v0.2.1beta

| Rota | Classe | Regra validada |
| --- | --- | --- |
| 1.1, 1.2 | leitura | nao pede sudo |
| 1.3 | reparo de sistema | solicita ticket sudo antes de modificar hostname, servicos ou sysctl |
| 1.4 | atualizacao APT | solicita ticket sudo antes do APT |
| 2.1, 2.2 | NetworkManager | solicita ticket sudo; banco fica no estado do usuario |
| 2.3 | diagnostico e reparo | leitura sem sudo; so pede sudo ao confirmar reparo |
| 2.4 | AP Halfin | submenu conserva confirmacao sudo por acao |
| 3.1 | leitura Docker | nao pede sudo |
| 3.2 | instalacao Docker | executa como root apos ticket sudo |
| 3.3 | compose up | pede sudo somente depois da confirmacao |
| 4.1, 4.3 | leitura Bitcoin | nao pede sudo |
| 4.2, 4.4, 4.5, 4.6 | instalacao, logs e controle Bitcoin | usam ticket sudo |
| 5, 6 | reboot e desligamento | usam ticket sudo somente apos confirmacao |

## Evidencia

- TDD de sintaxe e rotas locais aprovado.
- TDD real da rota 2.1 no Node .92 aprovado: banco em estado do usuario, sem erros de permissao.
- Rotas que instalam, alteram rede, iniciam servicos, reiniciam ou desligam foram testadas por roteamento e mocks; nao foram executadas no Node durante esta auditoria.
