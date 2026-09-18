# Análise da conversa inicial de design da TUI

> Estado: levantamento técnico para a especificação
> Fonte: [`../../tui_design_specs.md`](../../tui_design_specs.md)

## Entendimento

A conversa propõe um design system completo: aparência, controle por teclado, estados de risco, componentes reutilizáveis e um motor que receba a descrição de menus em vez de cada submenu desenhar a própria tela. Esse é o escopo correto para esta pasta.

## Fatos confirmados

| Área | Estado observado |
| --- | --- |
| Linguagem | A TUI e o bootstrap são Bash. |
| Aparência | ANSI básico, banner, status, seções e feedback já existem. |
| Paleta atual | Cyan, magenta, branco, amarelo, verde e vermelho. |
| Entrada | Menus leem texto com `read`; seleção numérica é repetida em vários pontos. |
| Convenções existentes | `q` sai; `0` volta; `ENTER` é usado para continuar em telas de resultado. |
| Componentes | `halfin/lib/ui.sh`, `colors.sh` e `banner.sh` já concentram parte da apresentação, mas não existem cards, cursor ou controlador único. |
| Compatibilidade | O projeto precisa funcionar por SSH e em terminal pequeno; não pode exigir mouse, UTF-8 ou 256 cores. |

## Decisões derivadas

- O motor será Bash e sem dependências externas de runtime. YAML pode servir de exemplo e intercâmbio documental, mas não será exigido para instalar ou abrir o menu.
- O catálogo de menus terá uma representação declarativa shell-native; o formato lógico está em `MENU_SCHEMA.md`.
- O renderer escolhe lista compacta, grade de duas colunas ou grade de três colunas conforme largura e altura disponíveis.
- Setas e `ENTER` coexistem com acesso direto por número. Assim, o menu atual continua utilizável enquanto a experiência ganha foco visual.
- Toda operação de risco usa o mesmo diálogo do motor, em vez de cada menu inventar sua confirmação.
- Fallback ASCII e sem cor é uma capacidade obrigatória, não uma variação decorativa.

## Pontos que exigem validação na implementação

1. Leitura de teclas deve funcionar tanto localmente quanto em SSH, sem bloquear entrada usada por instaladores ou comandos `curl | bash`.
2. A troca entre renderer em lista e renderer em grade deve manter o mesmo item selecionado e as mesmas teclas.
3. O motor deve delegar ações a funções já existentes sem avaliar texto arbitrário vindo da tela.
4. Menus legados devem poder ser migrados gradualmente; a primeira versão não pode exigir reescrever todos os submenus.
5. Títulos, ícones e descrições precisam caber em 80×24 sem truncamento silencioso de ações críticas.

## Decisão de arquitetura recomendada

A proposta de um menu declarativo é aprovada como direção, com um ajuste: usar YAML diretamente no runtime criaria um parser e uma dependência extra em instalação limpa. O contrato será independente de formato; a primeira implementação o materializa em Bash. YAML permanece útil para documentação, exportação e futura ferramenta de geração.