# Padrão de Rede Halfin e Registro Operacional

## Referência validada

- **Perfil:** Halfin em Orange Pi Zero 3, arm64, Debian Bookworm.
- **Host em uso:** `halfin`.
- **Acesso administrativo:** `ssh pleb@192.168.101.50`.
- **Data da confirmação:** 2026-09-11.

A senha inicial de laboratório não é registrada no repositório, documentação, logs ou controle de versão. Durante a operação ela deve ser solicitada de forma interativa ou recuperada de um cofre de credenciais. A troca obrigatória no primeiro início continua sendo requisito da versão final.

A chave SSH observada neste IP já existia também no inventário local para `192.168.101.41`. Antes de automatizar acessos sem supervisão, confirmar pelo console ou inventário que ambos os endereços representam o mesmo equipamento; uma chave coincidente por si só não substitui essa validação de identidade.

## Estado observado no equipamento

A verificação foi somente de leitura. Não houve atualização, reinicialização, reparo ou mudança de configuração.

| Verificação | Resultado |
| --- | --- |
| Kernel | `6.1.31-sun50iw9` |
| Serviços ativos | `NetworkManager`, `hostapd`, `halfin-ap-prepare.service`, `halfin-ap-health.timer`, `pihole-FTL`, `halfin-uplink-failover.timer` |
| Serviço inativo | `dnsmasq` |
| Cliente Wi-Fi | `wlan1` conectado a `Vivo5091` pelo NetworkManager |
| Rede de acesso | `wlan0` reservado ao AP; `br0` e `end0` não gerenciados pelo NetworkManager |
| Rotas | `end0` com métrica 100; `wlan1` com métrica 600 e tabela `halfin-wlan1` |
| Tailscale | `CorpDNS: false` |
| Diagnóstico Halfin | sem problemas; AP em `wlan0`, bridge `br0`, `10.21.21.1/24`, hostapd pronto e Pi-hole FTL como dono DHCP/DNS |

A instalação em execução foi encontrada em `/home/pleb/nodenation`, incluindo `halfin/tools/ap_health.py`. Esse diretório não contém metadados Git. Portanto, o estado de execução confirma que as proteções de rede foram aplicadas, mas ainda não permite afirmar qual commit do GitHub ou Forgejo foi implantado.

## Prática padrão de rede

1. `end0` é WAN exclusiva do `ifupdown`.
2. `wlan1` é cliente Wi-Fi exclusivo do NetworkManager. Não pode ter estrofe em `/etc/network/interfaces`, nem receber `wpa_supplicant`, `dhclient` ou `ifup` diretamente por scripts, cron, boot hook ou TUI.
3. `wlan0` e `br0` ficam fora do NetworkManager. O `hostapd` é o único dono do rádio AP e a bridge é preparada antes de DHCP/DNS.
4. Há somente um dono de DHCP/DNS: Pi-hole FTL quando instalado e configurado; caso contrário, dnsmasq. Os dois nunca ficam ativos juntos.
5. `halfin-ap-prepare.service` vem antes do AP e do serviço DHCP/DNS. `halfin-ap-health.timer` apenas diagnostica e recupera falhas delimitadas; não reinicia WAN, não troca senha e não reinicia um AP saudável.
6. A WAN cabeada tem preferência. `wlan1` é rota de contingência com métrica maior e tabela de política própria; a proteção de failover remove rota padrão inválida após perda de portadora.
7. O servidor preserva seu resolvedor local: `tailscale set --accept-dns=false`. Eventos de DHCP/link reaplicam essa política pelo resolvedor local do Halfin.
8. Manutenção de rede exige acesso alternativo por Ethernet ou console e uma checagem pós-alteração com `sudo halfin-ap check`.

O detalhamento de diagnóstico, testes e reversão permanece em [HALFIN_AP_RECOVERY.md](HALFIN_AP_RECOVERY.md).

## Recuperação do uplink cabeado

Em 2026-09-12, no Orange Pi de teste, confirmou-se que `end0` continua deliberadamente fora do NetworkManager e pertence ao `ifupdown`. Portanto, transferi-la ao NetworkManager não é a correção: isso quebraria a separação entre WAN, AP e cliente Wi-Fi.

A lacuna confirmada no instalador era a ausência de uma verificação de boot para `end0`. O instalador passa a instalar `halfin-end0-ensure.service`, que verifica a existência de IPv4 e de rota padrão em `end0`; somente quando uma das duas estiver ausente ele executa `ifup --force end0`, registra o resultado no journal e falha de forma visível se a recuperação não completar. A unidade executa antes de `network-online.target` e não altera `wlan0`, `wlan1` ou `br0`.

A recuperação manual do alvo usava IP estático em `/etc/network/interfaces`, mas tinha as chaves `gatrway` e `dna-nameservers`. As chaves válidas são `gateway` e `dns-nameservers`; os erros explicam a ausência de rota padrão e DNS naquele estado. A correção deve preservar a política escolhida para o uplink (DHCP ou estático) e corrigir essas chaves, nunca substituir silenciosamente uma configuração estática por DHCP.

A origem exata da primeira falha de boot não pôde ser provada porque a sessão de atualização perdeu conectividade antes de disponibilizar os logs privilegiados. O fato verificável é que a versão anterior não garantia uma nova tentativa de `ifupdown`; a unidade adicionada cobriu esse caso e foi validada após reboot controlado no Orange Pi de teste em 2026-09-12; ela é o padrão para instalações Halfin futuras.

## WAN DHCP obrigatória

O Halfin instala o uplink cabeado com DHCP explícito. `configure_wan_dhcp.sh` remove definições antigas da interface WAN nos arquivos `interfaces` e seus fragmentos, preserva as demais interfaces e cria `/etc/network/interfaces.d/halfin-wan` com `allow-hotplug`, DHCP e métrica 100. A validação física no Orange Pi em 2026-09-12 confirmou lease, rota, DNS, AP e acesso SSH após reboot.
