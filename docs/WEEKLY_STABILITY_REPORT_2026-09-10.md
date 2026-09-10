# Relatorio de estabilidade - 2026-09-10

## Escopo

Esta semana consolidou a recuperacao do instalador Halfin, da TUI, do AP Wi-Fi,
do DHCP/DNS local, da administracao de rede e dos testes portaveis de Halfin e
Satoshi. O foco operacional foi o Orange Pi com Debian Bookworm, AP em `wlan0`,
bridge `br0`, Ethernet `end0` e Wi-Fi cliente `wlan1`.

## Incidentes e correcoes

| Area | Falha observada | Causa confirmada | Correcao permanente | Regressao |
| --- | --- | --- | --- | --- |
| Ownership de rede | Dois leases e perda intermitente de LAN/SSH | ifupdown e NetworkManager administravam `end0`; hooks antigos tambem administravam `wlan1` | ifupdown e dono de `end0`; NetworkManager e dono exclusivo de `wlan1`; AP/bridge permanecem unmanaged | Template sem `wlan1` em interfaces e contrato validado em teste |
| AP Halfin | SSID visivel sem conexao ou DHCP | hostapd, bridge, dnsmasq e FTL iniciavam sem ordem; radio tinha configuracao 5 GHz incompativel | preparo de AP antes de hostapd/FTL, perfil WPA2/CCMP 2.4 GHz, health timer | `ap_health.py`, TUI de diagnostico e testes de unidade |
| DHCP/DNS | Porta 67 disputada e lease falhava | dnsmasq e Pi-hole FTL habilitados simultaneamente | FTL e unico DHCP quando Pi-hole esta ativo; dnsmasq fica desabilitado | checagem de socket UDP 67 e DNS local |
| DNS/Tailscale | DNS local desaparecia apos boot/link | Tailscale e depois NetworkManager sobrescreviam `resolv.conf` | `accept-dns=false`, resolvedor local, servico de boot e dispatcher NM | consulta local e `CorpDNS=false` verificadas |
| TUI Wi-Fi | Senha correta reportada como erro | NetworkManager recusava a operacao antes do WPA por falta de autorizacao | submenu pede `sudo -v`; apenas `nmcli` recebe privilegio temporario; Polkit amplo removido | mensagens distinguem permissao, SSID ausente e WPA |
| WLAN de backup | IP obtido, mas Internet caia ao remover Ethernet | end0 e wlan1 usam a mesma rede; retorno da WLAN era roteado por end0 | tabela `halfin-wlan1`, regra por origem, `rp_filter=2` e teste HTTPS vinculado a interface | `end0` metrica 100, WLAN 600/50 e NAT nos dois uplinks |
| Failover | WLAN nao assumia quando cabo caia | rota DHCP de metrica 0 em end0 permanecia `linkdown`, mas vencia a rota WLAN | timer remove a rota default metrica zero antes de aplicar metricas administradas | teste operacional: rota generica e HTTPS passaram pela WLAN |
| Firewall | `networking.service` falhava no boot | hook global restaurava regras invalidas via `iptables-restore` | regras isoladas nas chains HALFIN e servico dedicado | hook legado retirado sem apagar regras de terceiros |
| Instaladores | etapas podiam declarar sucesso apos falha | scripts permissivos e checkpoints antigos | subprocessos Bash estritos, lock e checkpoints v2 | testes de erro de APT, extras e integridade |
| Satoshi | pipeline de senha, versao e download fragil | SIGPIPE, release nao validado e checksum ausente | validacao de release, checksum e fluxo guiado | regtest/Core e testes de instalacao |

## Estado operacional confirmado

- `end0` e a rota primaria enquanto possui conectividade.
- `wlan1` pode assumir o uplink; a politica por origem e obrigatoria porque os
  dois links usam a mesma sub-rede.
- O AP continua em `wlan0`; a bridge `br0` usa NAT para ambos os uplinks.
- Pi-hole FTL responde DNS/DHCP; dnsmasq nao disputa a porta DHCP.
- Tailscale permanece ativo sem assumir o DNS local.
- O perfil Wi-Fi deve estar associado a um SSID presente no scan; `ssid-not-found`
  nao e erro de senha.

## Verificacao executada

- Sintaxe Bash dos instaladores, roteamento, failover e TUI.
- Suite portavel: testes de AP, Wi-Fi, shell e instalacao.
- Fluxo Halfin de instalacao: arquivos, funcoes, biblioteca e entrada do script.
- Host real: AP, hostapd, bridge, FTL, DHCP, DNS local, Tailscale, ownership e
  rotas foram verificados durante as correcoes.
- No failover real, o acesso HTTPS vinculado a `wlan1` retornou HTTP 200 apos
  instalar a rota por origem; a rota default de `end0` sem metrica foi removida.

## Pendencias controladas

- Repetir ciclo fisico completo: desconectar e reconectar `end0`, aguardando o
  timer de 20 segundos e confirmando trafego de cliente pelo AP em cada sentido.
- Testar o perfil Wi-Fi desejado quando o SSID estiver presente no scan.
- `postfix@-.service` e `smartmontools.service` estavam falhos no host, fora do
  caminho Halfin/AP. Devem ser analisados separadamente antes de afirmar saude
  total do sistema operacional.

## Regra de manutencao

Nao restaurar interfaces Wi-Fi cliente no ifupdown, nao iniciar
`wpa_supplicant`/`dhclient` diretamente em `wlan1`, nao habilitar dnsmasq junto
ao FTL e nao reintroduzir rota default DHCP de metrica zero. Alteracoes de
rede devem passar pelos testes e pelo health/failover do Halfin.
