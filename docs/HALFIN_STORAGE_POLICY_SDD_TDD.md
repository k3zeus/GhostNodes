# Halfin - politica de armazenamento e desgaste (SDD/TDD)

## Decisao aprovada

O Bitcoin Core prunado continua opcional no Halfin. A presenca de um cartao MicroSD nao bloqueia a instalacao: o motor identifica `mmcblk`, explica que prune nao elimina as escritas de sincronizacao e chainstate, e exige que a pessoa digite `MICROSD` antes da confirmacao normal.

Um SSD e recomendado para o diretorio de dados do Core. Quando o diretorio estiver em outro filesystem, o calculo de espaco e a identificacao de midia usam esse filesystem, nao a raiz do sistema.

## Configuracao aplicada pelo pre-instalador

`etapa_armazenamento` executa antes da configuracao de rede e e idempotente:

| Ajuste | Implementacao | Limite consciente |
| --- | --- | --- |
| Swap | preserva ZRAM ja ativo fornecido pela imagem; caso contrario instala `zram-tools`, com ZRAM LZ4 de 50% da RAM e prioridade 100; desativa `/swapfile` e `dphys-swapfile` quando presentes | Nao altera swap externo nem promete eliminar escrita do banco Bitcoin. |
| Acessos de arquivo | persiste `noatime` apenas na entrada existente de `/` no `fstab`, preservando uma copia anterior em `/etc/ghostnodes/backups/` | Se nao houver entrada da raiz, registra o fato e nao inventa uma. |
| Journal | mantem `Storage=auto`, com 100 MiB maximos, 14 dias de retencao e rotacao em arquivos de 16 MiB | Logs sobrevivem a reboot; nao sao descartados silenciosamente como seriam com `Storage=volatile`. |
| Memoria | `vm.swappiness=10` | ZRAM e reserva comprimida, nao substitui RAM nem um SSD. |
| Core Halfin | `disablewallet=1`, `persistmempool=0`, `debug=0`, `shrinkdebugfile=1` e `printtoconsole=0` | O Core permanece um no validador prunado; nao ha carteira local. |

`commit=600` nao e aplicado. O ganho potencial de escrita nao justifica ampliar a janela de perda de dados apos queda de energia em um no validador.

## TDD executavel

1. `python -B -m unittest tests.test_bitcoin_halfin -v` valida a confirmacao MicroSD, a ausencia de bloqueio e o registro do estagio de armazenamento.
2. `bash -n bitcoin/bitcoin-node.sh halfin/tools/storage_tuning.sh halfin/pre_install.sh` valida a sintaxe.
3. Em um Halfin limpo, executar o pre-instalador e verificar: `swapon --show`, `findmnt -no OPTIONS /`, `journalctl --disk-usage`, `sysctl vm.swappiness`.
4. No menu Bitcoin em midia MicroSD, confirmar que cancelar `MICROSD` nao instala nada e que a confirmacao seguida de `s` continua normalmente.

Nao existe teste de sincronizacao mainnet nesta alteracao. A instalacao do Core continua exigindo a confirmacao do operador e o download verificado pelo motor compartilhado.
