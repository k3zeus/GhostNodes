# Swissknife no Halfin — SDD e TDD de compatibilidade

## Objetivo

Validar todos os scripts do bundle Swissknife em ARM64 e AMD64 sem modificar rede, serviços, pacotes, `/etc`, `/opt` ou o checkout do GhostNodes/Halfin.

## Fatos confirmados

- O instalador original faz `apt upgrade`, instala pacotes, configura zram, reinicia NetworkManager, adiciona uma origem Caddy e escreve em `/etc`.
- O bundle usa `eth0` como LAN por padrão; Halfin ARM64 usa `end0`, `wlan0` e `wlan1`, e o host AMD64 usa `enp0s3`.
- O bundle entregue está achatado: `audit-all.sh` chama `services/01-*.sh`, mas a pasta `services/` não existe. Sem `set -e`, ele também retorna sucesso após falhar em todas as fases, gerando um falso positivo.`n- Os scripts importados não possuem bit executável no Git; o harness aplica essa permissão apenas à cópia temporária para testar o conteúdo.

## Contrato de teste

`tests/swissknife/run_isolated_contract.sh` copia o bundle para `~/logs/osint/swissknife/<execução>/work`, fornece comandos simulados e registra cada operação privilegiada interceptada. Ele:

1. fotografa interface, estado do NetworkManager, configuração em `/etc/NetworkManager/conf.d` e hashes do bundle antes/depois;
2. confirma que o orquestrador original falha pelo layout achatado;
3. usa apenas uma adaptação temporária na cópia para testar o fluxo pretendido;
4. executa instalador, fases 1–6, orquestrador e publicação de relatórios com ferramentas simuladas;
5. exige todos os relatórios previstos e falha se o estado observado mudar.

Nenhum pacote é instalado, nenhum scan real é enviado e nenhuma alteração é aplicada ao host. A ativação operacional futura continua dependente de especificação própria, correção deliberada do layout e teste físico autorizado.
## Evidência de execução isolada

| Host | Arquitetura confirmada | Resultado |
|---|---|---|
| `192.168.101.92` | `aarch64` / ARM64 | PASS; relatórios em `~/logs/osint/swissknife/20260919T154329-188297/` |
| `192.168.101.132` | `x86_64` / AMD64 | PASS; relatórios em `~/logs/osint/swissknife/20260919T154336-84515/` |

Em ambos, o harness confirmou que `before.state` e `after.state` são idênticos. Foram criados os relatórios wireless, WPS, p0f, broadcast, NetBIOS, mDNS, ARP, descoberta XML, scan profundo, checagens TLS/SSH/Web e os relatórios Markdown/HTML consolidados. Todas as operações administrativas do instalador foram interceptadas em `mocked-privileged-operations.log`; nenhum pacote, serviço, arquivo de rede ou checkout foi alterado.

O resultado **não aprova** executar o bundle diretamente em Halfin: o layout achatado, o retorno zero enganoso do orquestrador, os padrões de interface incompatíveis e as mutações do instalador continuam bloqueadores para uma ativação operacional.
