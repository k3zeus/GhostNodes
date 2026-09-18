# Ghost Nodes TUI

> Estado: definição técnica e visual — rascunho para aprovação
> Escopo: design system, interação por teclado, contrato de menus e arquitetura do motor TUI.

Esta pasta é a fonte de verdade para toda tela interativa do Ghost Nodes. O objetivo é que Halfin, Satoshi e os projetos futuros pareçam e se comportem como partes do mesmo appliance, mesmo quando suas ações internas forem diferentes.

A criação desta documentação não altera `nodenation`, `menu.sh`, `halfin/lib/*` nem qualquer fluxo instalado.

## Fonte e fatos atuais

A conversa original está preservada em [`../../tui_design_specs.md`](../../tui_design_specs.md). A leitura do código atual e a separação entre fatos, propostas e lacunas estão em [SOURCE_ANALYSIS.md](SOURCE_ANALYSIS.md).

## Contratos propostos

| Documento | Define | Estado |
| --- | --- | --- |
| [TUI_DESIGN_SPEC.md](TUI_DESIGN_SPEC.md) | Identidade visual, interação, estados, arquitetura e transição. | Rascunho |
| [COMPONENT_CATALOG.md](COMPONENT_CATALOG.md) | Componentes reutilizáveis e referências ASCII/Unicode. | Rascunho |
| [MENU_SCHEMA.md](MENU_SCHEMA.md) | Dados que descrevem menus e opções para o motor único. | Rascunho |
| [SOURCE_ANALYSIS.md](SOURCE_ANALYSIS.md) | Evidências do projeto e decisões ainda abertas. | Pronto para revisão |

## Regra de implementação

Nenhum novo menu poderá desenhar bordas, cores, leitura de teclas ou confirmação diretamente. Ele declarará dados conforme `MENU_SCHEMA.md`; o motor TUI será o único responsável por renderizar, navegar e encaminhar ações.

A implementação só começa depois da aprovação deste conjunto e de um TDD próprio do motor. Até isso acontecer, estes documentos não alteram os menus existentes.