# TDD — Piloto do menu principal TUI

> Estado: TDD de layout e teclado aprovado; aguardando nova avaliação visual do usuário.
> Data: 2026-09-14
> Escopo: somente `ghostnode` no Halfin dos nodes de teste.

## Nodes testados

| Node | Arquitetura | Resultado |
| --- | --- | --- |
| `.92` | arm64 / Orange Pi Zero 3 | Preview amplo, grade de seis opções, backup, foco por seta e saída segura aprovados. |
| `.132` | AMD64 / Ubuntu | Preview amplo, grade de seis opções, backup e saída segura aprovados. |

## Evidências técnicas

- `bash -n` passou para launcher e motor TUI antes de cada deploy.
- Preview em 120×40 confirmou título, seis destinos e saída.
- No `.92`, o teste enviou seta para a direita e `q`; o foco passou para **Conexões de Rede** e a saída ocorreu sem chamar ação alguma.`n- No `.132`, o teste de `q` concluiu com saída segura, sem chamar ação alguma.
- Cada node possui cópia anterior em `/var/backups/ghostnodes-tui/20260914-tui-pilot/ghostnode.before`.
- As ações de Sistema, Rede, Docker, Satoshi, reboot e shutdown não foram executadas pelo TDD.

## Correção aplicada após a primeira avaliação`n`n- Cards amplos passaram a ter largura máxima de 29 colunas; isso evita wrap em terminais menores que reportavam largura inconsistente.`n- A partir do segundo quadro, o renderer reposiciona o cursor no topo em vez de executar `clear`; isso remove o flash em branco/preto entre setas.`n- O foco agora usa a variante ANSI brilhante da cor semântica do card, além da borda reforçada.`n- As duas correções foram aplicadas no `.92` e `.132`, com backup em `/var/backups/ghostnodes-tui/20260914-tui-layout-fix/`.`n`n## Limitação conhecida

Os dois nodes mostram aviso de permissão ao gravar o log do `ghostnode`. O aviso já existia fora do piloto visual e não impede o renderer, a entrada nem as ações. Ele fica fora deste escopo para não misturar correção de permissões com a avaliação visual.

## Avaliação pendente

Abrir `ghostnode` em cada node e avaliar: composição, cores, legibilidade, comportamento de foco e fallback em janela menor. Não publicar nem propagar além dos nodes de teste até a aprovação visual.


## TDD adicional — teclado e colunas fixas

- Conteúdo de cada card foi fixado em 19 colunas visíveis; somente o vão entre cards varia, entre duas e três colunas vazias.
- Texto de card não focado é branco. Apenas o título do card focado assume a cor semântica brilhante; a borda focada usa moldura dupla e negrito.
- O decodificador aceita as oito sequências de cursor comuns: CSI (`ESC [ A/B/C/D`) e SS3 (`ESC O A/B/C/D`).
- Em `.92` e `.132`, a matriz de oito sequências e o preview passaram no próprio node.
- Em `.92` e `.132`, o fluxo `→`, `ENTER`, `q` não gerou tecla/opção inválida e retornou com segurança, sem chamar operação de rede.
- Backup do renderer final: `/var/backups/ghostnodes-tui/20260914-tui-fixed-columns/tui_engine.sh.before`.

## Correcao de codificacao e bordas - 2026-09-14

- Causa confirmada: o renderer chegou ao Bash com caracteres Unicode corrompidos e alguns finais de linha Windows.
- Padrao corrigido: cards e molduras usam ASCII; largura fixa de 23 colunas por card e apenas os espacos entre cards variam.
- Foco: borda `=` em negrito e titulo colorido; demais textos permanecem brancos.
- TDD local: sintaxe, previsualizacao, oito sequencias ANSI/SS3 e navegacao passam.
- TDD remoto: .92 ARM64 e .132 AMD64 retornaram `TDD_ASCII_RENDERER_OK`; o teste confirmou bytes ASCII, sintaxe, previsualizacao e oito setas.
- Publicacao permanece pendente de aprovacao visual do usuario.

## Correcao do ciclo de redesenho - 2026-09-14

- Regressao identificada: o renderer novo nao chamava o banner canonico e redesenhava a tela inteira a cada tecla.
- Correcao: `banner` e executado uma vez por sessao; a posicao abaixo do topo e salva. As setas restauram essa posicao e limpam somente a area do menu.
- TDD local: `tests/test_tui_main_menu.sh` aprovado, incluindo retencao do banner e redesenho parcial.
- Aplicado nos Nodes .92 e .132; sintaxe do executavel aprovada. A validacao visual continua pendente.
