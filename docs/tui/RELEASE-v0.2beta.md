# TUI v0.2beta

- Data: 2026-09-14
- Estado: base visual registrada para validacao em .92 e .132.
- Escopo: motor TUI do Halfin em `ghostnode` e `lib/tui_engine.sh`.

## Baseline

A v0.2beta registra o menu principal com selecao por setas e numeros, cards de largura fixa, banner Ghost Nodes e transicao limpa para submenus.

## Contrato visual

1. A familia de bordas da TUI e `╔═╗║╚═╝`. Nenhum painel interativo usa `+`, `-` ou `|`.
2. O banner e a barra de status sao centralizados quando o terminal e mais largo que o conteudo.
3. O numero entre colchetes e o unico atalho de cada card.
4. Cards podem exibir um icone semantico ao lado direito do numero; o numero continua sendo a unica forma de acionamento.
5. A ajuda mostra explicitamente `↑ UP`, `↓ DOWN`, `← LEFT` e `→ RIGHT`.
6. O TDD deve verificar sintaxe, UTF-8 sem CRLF, bordas padrao, ausencia de atalhos alfabeticos e transicao limpa antes dos submenus.

## Evidencia anterior

- .92: ARM64
- .132: AMD64
- Navegacao ANSI/SS3, ENTER e preview haviam sido validados antes deste baseline.
