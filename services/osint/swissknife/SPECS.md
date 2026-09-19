# Especificação SwissKnife no GhostNodes

SwissKnife é um módulo OSINT manual, utilizável em hosts Debian/Ubuntu ARM64 e AMD64. Ele não integra automaticamente o Halfin.

## Contrato de interface

1. Uma interface só é elegível quando existe em `/sys/class/net`, está ativa, possui IPv4 global e rota local.
2. Interfaces declaradas pelo Halfin como AP (`interface-name:*` em NetworkManager) ou com modo wireless `AP` são recusadas.
3. A seleção automática escolhe a menor métrica de rota. Uma seleção manual é revalidada.
4. A faixa de scan precisa estar contida na rede local da interface escolhida.
5. Survey wireless requer um adaptador wireless físico distinto da LAN e fora do AP Halfin.

## Persistência e instalação

Relatórios, logs de instalação e instruções de publicação são salvos em `~/logs/osint/swissknife/`. O instalador somente instala dependências sob `SWISSKNIFE_APPLY=1`; não atualiza o sistema, não instala repositórios externos e não toca NetworkManager, rotas ou arquivos de rede.

## Falhas

Todos os scripts usam `set -euo pipefail`. Pré-requisito ausente, interface não elegível, relatório obrigatório ausente ou fase anterior incompleta encerram a execução com erro.