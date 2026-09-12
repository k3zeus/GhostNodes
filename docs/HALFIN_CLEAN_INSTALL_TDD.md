# TDD — Instalação Limpa Halfin no Orange Pi Zero 3

## Status

**Aprovado para DHCP, recuperação de `end0`, bootstrap e elevação única de privilégios; uma nova imagem limpa deve repetir o fluxo completo como regressão de lançamento.**

Data: 2026-09-12
Alvo: `192.168.101.92` (`orangepizero3`)
Revisão testada: `b8e178a1813b88e58a3bb622c5d1b2c676316e09`

## Pré-condições aprovadas

| ID | Resultado |
| --- | --- |
| TDD-P01 | OrangePi Zero3, arm64, Orange Pi OS / Debian Bookworm identificado pelo `nodenation`. |
| TDD-P02 | 1 GiB de RAM e 57 GiB livres; `end0` como uplink inicial. |
| TDD-P03 | Adaptador USB de MAC `90:de:80:f9:44:3b` renomeado por regra udev para `wlan1`; persistência validada após reboot. |
| TDD-P04 | GitHub e Forgejo `main` apontavam para a mesma revisão fixada. O alvo recebeu HTTPS 200 para o bootstrap dessa revisão. |
| TDD-P05 | Testes locais iniciais: registro de hardware 9/9, fluxo Halfin 24/24 e AP 11/11. |
| TDD-P06 | Guard de boot de nd0: 3 testes de unidade/integração e 11 testes de saúde AP aprovados (14 no total). |

## Execução observada

1. O bootstrap fixado detectou corretamente o perfil e gravou `hardware.env` no estágio.
2. O download da árvore fixada foi concluído, extraído em `/tmp/ghostnodes_staging` e passou na verificação de integridade.
3. A confirmação do fluxo Halfin criou o usuário `pleb` e promoveu o projeto para `/home/pleb/nodenation`.
4. A etapa `etapa_sourcelist` preservou os repositórios Orange Pi.
5. `etapa_update` iniciou atualização de 174 pacotes da imagem-base.

## Falhas e desvios

| ID | Severidade | Evidência | Próxima ação |
| --- | --- | --- | --- |
| TDD-F01 | Alta | O primeiro bootstrap baixou o staging, mas retornou código 1 antes de abrir o menu. | Corrigir e cobrir a retomada automática depois do download. |
| TDD-F02 | Média | Em terminal sem `TERM`, `clear` sob `set -e` encerra o `nodenation` antes de desenhar o menu. O mesmo script funcionou com `TERM=xterm`. | Tornar a TUI tolerante a `TERM` ausente e adicionar regressão. |
| TDD-B01 | Resolvido para investigação | Durante `etapa_update`, o ambiente de controle perdeu rota/SSH para todo o segmento `192.168.101.*`, incluindo o Halfin de referência `.50`. A sessão de instalação não reportou sucesso nem falha. O alvo voltou após intervenção local. | Validar a correção de boot abaixo e registrar o reboot controlado. |
| TDD-F03 | Alta | O código anterior mantinha nd0 fora do NetworkManager, como previsto, mas não instalava um guard que reexecutasse ifupdown se o boot não criasse IPv4 e rota padrão. No estado recuperado, a configuração estática manual também continha gatrway e dna-nameservers, chaves inválidas que explicam a ausência de rota/DNS. | Instalar halfin-end0-ensure.service, corrigir as chaves sem trocar a política do uplink e validar após reboot. |

## Evidência de recuperação `end0` — aprovada

Em 2026-09-12, o Orange Pi `.92` recebeu a unidade `halfin-end0-ensure.service` e a correção das chaves de rede estática, mantendo `end0` fora do NetworkManager. Uma cópia da configuração anterior foi preservada no equipamento antes da troca.

| Verificação | Resultado |
| --- | --- |
| Primeiro reparo | Com IP estático presente e rota ausente, a unidade aplicou o `gateway` declarado e recuperou a rota padrão. |
| Reboot controlado | SSH retornou; `end0` voltou com `192.168.101.92/24` e rota padrão por `192.168.101.1`. |
| Unidade | Habilitada e ativa; no boot registrou que IPv4 e rota padrão já estavam presentes. |
| DNS | Resolução externa aprovada. |
| Rede/AP | `NetworkManager`, `networking` e `hostapd` ativos; `halfin-ap check` sem problemas, bridge `10.21.21.1/24`, `dnsmasq` como único dono DHCP/DNS. |
| Pacotes | `dpkg --audit` sem pendências. |
| Ownership | `end0`, `wlan0` e `br0` permanecem não gerenciados pelo NetworkManager; `wlan1` fica disponível como cliente. |

A causa confirmada é uma lacuna de recuperação após boot, somada às chaves inválidas na configuração estática manual. A origem exata do primeiro boot que falhou não é atribuída de forma conclusiva à atualização, pois os logs privilegiados daquela transição não ficaram disponíveis.
## Critérios pendentes

- Confirmar a saúde de `dpkg` e a acessibilidade SSH antes de retomar etapas pendentes.
- Confirmar conclusão do `pre_install.sh` e os checkpoints em `var/preinstall_halfin.v2.state`.
- Validar `halfin-ap check`, `br0` em `10.21.21.1/24`, hostapd, DHCP/DNS com um único dono, failover e política de rota.
- Reboot controlado e retorno de SSH, AP, DNS/DHCP e rota padrão: **aprovado para a correção de `end0`**.
- Corrigir e testar TDD-F01 e TDD-F02 antes de uma nova instalação limpa integral.

Nenhuma senha, PSK, `.env` ou conteúdo de configuração sensível foi registrado neste documento.

## Fechamento DHCP e bootstrap — 2026-09-12

| Item | Evidência TDD | Resultado |
| --- | --- | --- |
| DHCP explícito de `end0` | O migrador removeu estrofes antigas, escreveu `/etc/network/interfaces.d/halfin-wan`, reiniciou o Orange Pi e recebeu lease DHCP. | **Aprovado** |
| Boot DHCP | Após reboot, `end0` retornou com endereço dinâmico, rota padrão, lease `dhclient.end0.leases`, DNS funcional e serviços de rede/AP ativos. | **Aprovado** |
| TDD-F01 | Sem TTY, o bootstrap retorna código `2` e uma mensagem explícita de que a instalação interativa requer terminal; falha de download automático também não é mascarada. | **Resolvido** |
| TDD-F02 | Com `TERM` ausente, a TUI foi renderizada no Orange Pi e retornou código `0`; `clear` é opcional e não encerra o processo. | **Resolvido** |

A validação DHCP foi feita com o endereço concedido pelo servidor da rede local, sem depender do IP estático anterior. O backup da configuração estática anterior permanece no Orange Pi para auditoria e reversão controlada.
