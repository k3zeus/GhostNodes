# Swissknife no Halfin — SDD e TDD de compatibilidade

## Objetivo

Disponibilizar o Swissknife como módulo OSINT manual, compatível com Halfin ARM64 e AMD64, sem modificar a topologia de rede que sustenta `end0`, `wlan0`, `wlan1` e o AP Halfin.

## Fatos confirmados

- O bundle anterior fixava `eth0`; esse nome não existe nos dois perfis testados.
- No Halfin ARM64, `wlan0` e `br0` pertencem ao AP e são declarados como não gerenciados pelo NetworkManager. As rotas de gestão observadas são `end0` (métrica 100) e `wlan1` (métrica 600).
- No host AMD64, a interface de gestão observada é `enp0s3`.
- O orquestrador anterior buscava `services/01-*.sh`, embora as fases estejam na própria raiz do bundle. Como ele não propagava todas as falhas, podia reportar êxito depois de falhar.
- O instalador anterior alterava componentes fora do escopo do módulo, inclusive rede. Isto viola a base imutável de rede do Halfin.

## Implementação aprovada

1. `network_discovery.sh` confirma que cada interface é física, existe, está ativa, tem IPv4 e rota local.
2. A seleção recusa qualquer interface definida como AP pela configuração Halfin ou em modo wireless `AP`.
3. Entre interfaces elegíveis, a seleção automática usa a menor métrica de rota. `IFACE_LAN`, `IFACE_WLAN`, `MGMT_INTERFACE` e `SCAN_RANGE` são revalidados; uma faixa externa à sub-rede local falha.
4. Todas as fases e o orquestrador usam `set -euo pipefail`; pré-requisito, comando ou relatório obrigatório ausente encerra a operação sem sucesso falso.
5. O orquestrador chama as fases na raiz correta do bundle.
6. O instalador apenas lista dependências por padrão e só chama o gerenciador de pacotes com `SWISSKNIFE_APPLY=1`. Ele não altera NetworkManager, rotas, aliases, Wi-Fi, `/etc` de rede, repositórios externos ou atualização integral do sistema.
7. Logs, capturas, relatórios e instruções de publicação usam exclusivamente `~/logs/osint/swissknife/`. A publicação gera um comando local e não instala Caddy nem escreve em `/etc`.

## TDD

O contrato `tests/swissknife/run_isolated_contract.sh` executa o bundle copiado para uma área temporária. As ferramentas de instalação e auditoria são simuladas, e o teste compara antes/depois:

- estado do NetworkManager;
- interfaces de rede;
- hashes de `/etc/NetworkManager/conf.d`;
- hashes do bundle de origem.

O teste exige relatórios de todas as fases, seleção de uma LAN física válida, exclusão do AP e `PASS` final. Nenhum scan real é enviado e nenhum pacote, serviço ou configuração de rede é alterado.

## Evidência atual

| Host | Arquitetura | Resultado |
|---|---|---|
| `192.168.101.92` | ARM64 / `aarch64` | PASS |
| `192.168.101.132` | AMD64 / `x86_64` | PASS |

As duas execuções concluíram com `before.state` idêntico a `after.state` e gravaram somente em `~/logs/osint/swissknife/<execução>/`.