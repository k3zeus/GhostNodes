# Ghost Nodes TUI Design Specification

> Versão: 0.1-draft
> Estado: piloto do menu principal em avaliação visual nos nodes .92 e .132
> Aplica-se a: `nodenation`, Halfin e menus de projetos futuros.

## 1. Objetivo

Definir um motor único de TUI e um design system de terminal que preserve operação por SSH, acesso numérico direto e consistência visual entre todos os projetos Ghost Nodes.

## 2. Princípios

1. **Estado antes de decoração.** Cor, borda e ícone comunicam foco, saúde ou risco.
2. **Teclado primeiro.** Nenhuma ação depende de mouse.
3. **Terminal degradável.** A mesma tarefa funciona com ASCII, sem cor e em 80×24.
4. **Dados separados de desenho.** Menus descrevem opções; o motor desenha e interage.
5. **Risco explícito.** Reboot, desligamento, remoção e reset jamais executam no primeiro acionamento.
6. **Migração sem quebra.** Listas numéricas existentes permanecem acessíveis durante a conversão.

## 3. Capacidades do terminal

| Perfil | Condição | Apresentação |
| --- | --- | --- |
| Seguro | `TERM=dumb`, sem TTY ou largura menor que 80 | Lista textual, ASCII, seleção numérica. |
| Compacto | 80×24 até 99×29 | Lista enriquecida; um item por linha. |
| Médio | 100×30 até 119×34 | Grade de duas colunas quando cada card couber. |
| Amplo | 120×35 ou maior | Grade de três colunas, até seis opções por página. |

A largura e a altura são obtidas no início de cada renderização. Se a capacidade UTF-8 ou cor não estiver confirmada, o renderer usa caracteres ASCII e marcadores textuais.

## 4. Anatomia obrigatória

```text
banner da identidade
faixa de estado: host | projeto | rede | horário
contexto: seção e caminho de navegação
conteúdo: lista ou grade de opções
barra de ajuda: teclas válidas no contexto
rodapé: retorno, saída ou resultado da operação
```

O banner pode ser compacto em submenus. Conteúdo nunca deve depender do banner para identificar a ação atual.

## 5. Linguagem visual

| Token | Uso | ANSI mínimo |
| --- | --- | --- |
| `identity` | marca, foco comum, links de navegação | cyan |
| `accent` | título e realce secundário | magenta |
| `text` | conteúdo principal | branco normal ou brilhante |
| `muted` | descrição, borda discreta, metadados | dim/white |
| `success` | operação concluída | verde |
| `warning` | cautela e atualização | amarelo |
| `bitcoin` | Bitcoin Core e Satoshi | amarelo/laranja quando disponível |
| `danger` | erro e ação destrutiva | vermelho |

Normal usa texto e borda discretos. Foco usa marcador textual, borda ou inversão, além de cor. Perigo usa rótulo textual; vermelho sozinho nunca é a única indicação.

## 6. Componentes

Os componentes e referências de desenho estão em `COMPONENT_CATALOG.md`. O motor precisa fornecer:

- `header`, `status_bar`, `breadcrumb` e `section_title`;
- `menu_option` em modos lista e card;
- `help_bar`, `footer` e `result_panel`;
- `confirmation_dialog` e `capability_warning`.

Nenhum submenu imprime sua própria versão desses elementos.

## 7. Estados de opção

| Estado | Significado | Representação obrigatória |
| --- | --- | --- |
| normal | disponível, sem foco | número, título e descrição discreta |
| focused | cursor atual | `>`/`▶` ou borda reforçada e contraste alto |
| disabled | indisponível no hardware ou instalação | marcador `INDISPONÍVEL`, motivo e nenhuma execução |
| running | ação em andamento | marcador de progresso e descrição da operação |
| success | última ação concluiu | `OK` e mensagem objetiva |
| warning | exige cautela | `ATENÇÃO` e amarelo |
| danger | altera ou remove estado | `PERIGO` e vermelho |
| critical | reboot, desligamento, reset, destruição | `CRÍTICO`, vermelho e confirmação reforçada |

## 8. Interação global

| Tecla | Contrato |
| --- | --- |
| `↑`, `↓`, `←`, `→` | move foco conforme o layout; sem efeito se não houver destino válido |
| `ENTER` | seleciona o item focado |
| `1`–`9` | executa diretamente a opção com aquele identificador, após regra de risco |
| `0` ou `b` | volta um nível; no topo não executa ação |
| `q` | pede saída quando houver ação em andamento; caso contrário encerra a TUI |
| `ESC` | equivale a voltar ou cancelar diálogo |
| `h` | abre ajuda contextual |

O foco circula dentro da página. Uma tecla não declarada produz feedback curto e não altera o estado. `r` não é global: só pode ser declarado por um menu, evitando reinício ou atualização acidental.

## 9. Risco e confirmação

| Risco | Primeiro acionamento | Confirmação |
| --- | --- | --- |
| `normal`, `info` | abre/executa | nenhuma |
| `warning` | abre diálogo | `s/n`, com padrão `n` |
| `danger` | abre diálogo | texto de ação e `s/n`, padrão `n` |
| `critical` | abre diálogo | host exibido e digitação do hostname; padrão cancelar |

O diálogo explica efeito, escopo e opção de cancelar. Ele não contém a lógica operacional; apenas chama a ação aprovada após confirmação positiva.

## 10. Arquitetura do motor

```text
Menu catalog -> Controller -> Renderer -> Terminal
                    |              ^
                    v              |
               Action gateway -----+
```

- **Menu catalog:** dados validados conforme `MENU_SCHEMA.md`.
- **Controller:** mantém menu atual, foco, página, histórico e estado transitório.
- **Renderer:** detecta capacidade, escolhe layout e desenha componentes.
- **Input adapter:** normaliza teclas em eventos sem conhecer ações de negócio.
- **Action gateway:** mapeia um `action_id` permitido para função Bash explícita; nunca executa texto de catálogo como shell.

O estado em memória contém somente navegação e feedback transitório. Dados de serviços, Wi-Fi e configurações permanecem nos arquivos e serviços já responsáveis por eles.

## 11. Catálogo e ações

Cada menu e opção usa identificadores estáveis, títulos, descrições, estado, risco e `action_id`. Ações são registradas pelo projeto que as possui. Um menu Halfin pode abrir um menu Bitcoin compartilhado, mas não duplica a tela nem altera a propriedade da ação.

A definição completa está em `MENU_SCHEMA.md`.

## 12. Transição dos menus atuais

1. Criar motor e renderer em biblioteca isolada, coberta por testes.
2. Migrar primeiro uma tela informativa sem ação destrutiva.
3. Migrar menus de rede e status preservando números atuais.
4. Migrar confirmações críticas para o diálogo único.
5. Remover desenho duplicado somente depois de equivalência TDD de cada menu.

## 13. Critérios de aceitação

- Renderização verificável em 80×24, 100×30 e 120×35.
- Todas as opções acessíveis por número e por foco/`ENTER`.
- ASCII sem cor mantém títulos, riscos, ajuda e saída compreensíveis.
- Uma ação crítica não roda com apenas uma tecla.
- Catálogo com ação ausente, id duplicado ou risco inválido falha antes de desenhar.
- Nenhuma tela legada perde `q`, `0` ou retorno após ação durante a migração.
