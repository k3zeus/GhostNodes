# Halfin: AP Wi-Fi e recuperacao

## Diagnostico realizado em 2026-09-08

Equipamento autorizado: Orange Pi Zero3, Debian Bookworm, kernel vendor
6.1.31-sun50iw9. AP em `wlan0` (unisoc_wifi), bridge `br0` em
10.21.21.1/24, WAN Ethernet `end0`. Adaptador USB `wlan1` usado somente como
cliente descartavel de teste. Credenciais nao fazem parte desta documentacao.

Foram confirmados problemas diferentes que podem apresentar sintomas parecidos
no celular: SSID visivel, mas associacao/autenticacao ou obtencao de IP falha.

1. NetworkManager gerenciava `wlan0` ao mesmo tempo que hostapd. A interface
   aparecia como desconectada no NM e como AP no `iw`. Isso permite disputa
   pelo radio, principalmente durante inicializacao e buscas de redes.
2. O preset antigo forcava 5 GHz/80 MHz e capacidades HT/VHT que nao correspondiam
   integralmente ao radio. Foi aplicado um perfil conservador 2.4 GHz, canal 6,
   WPA2-PSK/CCMP, preservando SSID e senha. Nao houve troca automatica de senha.
3. O primeiro reboot do teste reproduziu uma falha concreta: dnsmasq iniciava
   sem `br0` pronta (`unknown interface br0`) e depois competia com Pi-hole FTL
   pela porta DHCP 67 (`Address already in use`). Ambos estavam habilitados.
4. Nao havia socket de controle para verificar readiness real do hostapd nem
   uma sequencia de boot que garantisse bridge antes do DHCP.

Nao foi capturado o handshake original do celular antes da correcao. Portanto,
nao se afirma que toda mensagem de "senha incorreta" era causada pelo DHCP.
Os conflitos acima foram observados; autenticacao e DHCP sao testados separados.

## Protecao instalada

- `/etc/halfin/ap.json`: interfaces, endereco e dono do DNS/DHCP.
- `halfin-ap-prepare.service`: reserva AP/bridge, prepara IP e bridge antes de
  hostapd e do servico DNS/DHCP. Nao reinicia a WAN.
- `99-halfin-ap.conf`: acrescenta AP/bridge aos dispositivos nao gerenciados
  pelo NetworkManager, preservando outras exclusoes.
- hostapd: unico dono do radio; controle em `/run/hostapd`.
- Pi-hole FTL: escolhido quando ja tem DHCP configurado. dnsmasq separado e
  desabilitado, sem apagar seus arquivos. Na ausencia desse Pi-hole, usa dnsmasq.
- `halfin-ap-health.timer`: primeira verificacao aos 45 segundos do boot e
  repeticao a cada 60 segundos, com pequena tolerancia do systemd.
- Recuperacao limitada: verifica radio, NM, hostapd ENABLED, membro/IP da bridge,
  dono do DHCP, socket UDP 67 e consulta DNS local. Corrige falhas recuperaveis
  sem trocar senha, reiniciar WAN ou descarregar drivers.
- Tentativas automaticas tem intervalo minimo de cinco minutos, para nao
  derrubar clientes em uma tempestade de reinicios. Reparo manual nao consome
  esse intervalo. AP saudavel ou ausencia de clientes nao causam restart.
- O menu de conexao Wi-Fi nao pode selecionar o radio reservado ao AP; usa uma
  segunda interface para conexoes como cliente.

O submenu Wi-Fi pede `sudo` antes de operar o NetworkManager em `wlan1`; o
restante da TUI continua sem privilegios. Isso evita uma regra Polkit ampla e
impede que falta de autorizacao pareca senha WPA incorreta. A TUI deve mostrar
a causa retornada pelo NM, em especial `ssid-not-found` quando a rede nao esta
no scan.

## Contrato de ownership no boot

O WAN `end0` e exclusivamente configurado por `ifupdown`. O cliente Wi-Fi
`wlan1` e exclusivamente configurado pelo NetworkManager; ele nao pode ter
estrofe em `/etc/network/interfaces`, nem receber `wpa_supplicant` ou
`dhclient` diretamente por cron, boot hook ou TUI. `wlan0` e `br0` permanecem
fora do NetworkManager para hostapd/bridge. O instalador grava esse contrato em
`99-halfin-network-ownership.conf` e o teste de regressao o valida.

Em instalacoes antigas, remover qualquer recuperador que execute
`wpa_supplicant -i wlan1`, `dhclient wlan1` ou `ifup wlan1`. Esses comandos
criam uma segunda sessao WPA/DHCP e fazem o NetworkManager perder o radio.
Tambem nao usar um gancho global `if-up.d` para restaurar regras de firewall;
ele roda para cada interface, inclusive `lo`, e deve ser substituido pelo
`halfin-routing.service` dedicado.

## DNS e Tailscale

Este equipamento e servidor DNS local: Pi-hole FTL escuta em `127.0.0.1` e na
bridge do AP. Portanto, Tailscale deve ser configurado neste host com
`tailscale set --accept-dns=false`; aceitar DNS do tailnet reescreve
`/etc/resolv.conf` para o resolvedor virtual Tailscale e remove o resolvedor
local. O servico `halfin-local-resolver.service` restaura `127.0.0.1` no boot
apos Pi-hole e Tailscale. O dispatcher
`90-halfin-local-resolver` tambem reaplica a politica depois de eventos DHCP ou
link do NetworkManager. Ele nao desativa a VPN, apenas a administracao de DNS
do tailnet neste servidor. Validar com:

```sh
tailscale debug prefs | grep CorpDNS
cat /etc/resolv.conf
systemctl status halfin-local-resolver pihole-FTL tailscaled
getent ahostsv4 cloudflare.com
```

O timer nao promete acesso ininterrupto: ha tempo de boot/deteccao/recuperacao.
Falha de hardware, firmware ou radio ausente exige intervencao. DNS local e
readiness nao provam, sozinhos, handshake WPA, lease por cliente ou Internet.

## TUI e comandos

No comando instalado `ghostnode`: **2. Rede -> 4. AP Halfin**.
Opcoes: diagnostico, reparo confirmado, logs e instalacao/reaplicacao da protecao.
`0` volta; `q` sai. Confirmacoes de alteracao assumem NAO.

```sh
sudo halfin-ap check
sudo halfin-ap repair
systemctl status halfin-ap-prepare hostapd halfin-ap-health.timer
journalctl -b -u halfin-ap-prepare -u hostapd -u halfin-ap-health
sudo hostapd_cli -i wlan0 status
sudo hostapd_cli -i wlan0 all_sta
sudo ss -lunp 'sport = :67'
```

O primeiro comando retorna codigo nao zero quando encontra problemas. Nao
publique o conteudo de hostapd.conf: contem a senha/PSK. Logs de clientes tambem
podem revelar identificadores de dispositivos.

## Instalacao e reversao

O pre-instalador integra a protecao apos configurar roteamento/AP. Reexecutar
nao deve recriar dnsmasq se o Pi-hole ja tem DHCP ativo. O extra Pi-hole transfere
a configuracao da protecao para FTL apos sua instalacao bem-sucedida.

```sh
sudo python3 halfin/tools/ap_health.py install \
  --ap wlan0 --bridge br0 --address 10.21.21.1/24
```

Antes de alterar, o instalador guarda arquivos originais e informacao de ausencia
em `/var/backups/halfin-ap/<data-pid>`, restrito a root. Arma reversao em cinco
minutos, cancelada somente se a verificacao final ficar saudavel. Uma instalacao
rejeitada nao deve ser declarada concluida. Consultar timers pendentes antes de
uma nova tentativa; nao sobrepor instalacoes manuais concorrentes.

Para reversao manual, usar o `recovery.py` do backup desejado:

```sh
sudo python3 /var/backups/halfin-ap/SEU-BACKUP/recovery.py restore \
  --backup /var/backups/halfin-ap/SEU-BACKUP
```

A reversao completa de estados de servicos e cenarios de queda de energia ainda
precisa de teste dedicado. Nao tratar a existencia de backup como prova de
rollback integral. Manter acesso Ethernet/console durante manutencao de rede.

## Evidencias e limites

Evidencias desta execucao ficam fora do Git em `E:/Codex_Tests/`.

| Evidencia | Resultado observado |
| --- | --- |
| `ap-before.log` | Concorrencia NM/hostapd e preset de radio antigo. |
| `ap-client-green.log` | Chave incorreta nao conecta; correta completa WPA2/CCMP; DHCPACK 10.21.21.103, gateway 10.21.21.1; estacao AUTHORIZED. |
| `ap-fault-recovery-green.log` | Falha provocada em hostapd detectada e recuperada; verificar AP saudavel preserva o PID. |
| `ap-after-reboot.log` | RED: primeiro reboot revelou dnsmasq/FTL concorrentes e bridge indisponivel no inicio. |
| `ap-dns-fix-green.log` | FTL unico dono DHCP, dnsmasq desabilitado, bridge como dependencia; DNS upstream responde. |
| `ap-second-reboot-green.log` | GREEN: novo boot ID 3c44a7cc-33c4-4664-96f0-e305b15f67fa; AP ENABLED, NM unmanaged, DHCP/DNS saudaveis; SSH no IP original. |
| `ap-tui.log` | PTY real: principal -> rede -> AP -> diagnostico -> voltar -> voltar -> sair, exit 0. |

O probe `tests/e2e/dhcp_probe.py` realiza DHCP por frames no adaptador de teste,
sem alterar IP, rotas ou DNS do host. Ele e restrito a `wlan1`, requer root/Linux
e associacao previa. Nao e um teste de NAT/Internet pelo cliente. O driver USB
nao aceitou network namespace; nao foi forcada a migracao do radio.

Pendencias: repetir varios ciclos frios/energia, clientes celulares/laptops,
trafego NAT/DNS pelo cliente, testes de rollback e hotplug/firmware. O kernel
registrou avisos de firmware/regulatory database; nao foi atualizado. A WAN
apresentou concorrencia legada ifupdown/NM (dois leases em um boot), e ficaram
unidades legadas networking/ifup, postfix e smartmontools falhas. Nao foram
alteradas durante a manutencao do AP para nao comprometer administracao remota.

Referencia: [configuracao oficial do NetworkManager](https://networkmanager.pages.freedesktop.org/NetworkManager/NetworkManager/NetworkManager.conf.html).
