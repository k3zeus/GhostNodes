# Linha de Base Operacional — Halfin

Data: 2026-09-12

## Perfil validado

| Item | Estado aprovado |
| --- | --- |
| Hardware | Orange Pi Zero 3, arm64, Debian Bookworm / Orange Pi OS |
| WAN | `end0`, controlada por `ifupdown`, DHCP explícito no fragmento `halfin-wan`, métrica 100 |
| Recuperação WAN | `halfin-end0-ensure.service` habilitada; verifica IPv4 e rota padrão no boot antes de recuperar por `ifupdown` |
| AP | `wlan0` e `br0` fora do NetworkManager; bridge em `10.21.21.1/24` |
| Cliente Wi-Fi | `wlan1`, gerenciada somente pelo NetworkManager |
| DHCP/DNS AP | Um único dono: Pi-hole FTL quando selecionado; caso contrário `dnsmasq` |
| Bootstrap | Sem TTY retorna erro explícito; TUI tolera `TERM` ausente |

## Checagem em cada execução ou atualização

No Node, executar como administrador:

```sh
ip -4 addr show dev end0
ip -4 route show default
systemctl is-enabled --quiet halfin-end0-ensure.service
systemctl is-active --quiet halfin-end0-ensure.service
journalctl -u halfin-end0-ensure.service -b --no-pager
halfin-ap check
dpkg --audit
```

Critérios: `end0` tem endereço dinâmico e rota padrão; a unidade está habilitada e ativa; `halfin-ap check` não apresenta problemas; `dpkg --audit` não apresenta pendências. Confirmar também que `end0`, `wlan0` e `br0` permanecem fora do NetworkManager e que `wlan1` é o único rádio cliente gerenciado por ele.

## Regressões obrigatórias no repositório

```sh
python -B -m unittest tests.test_wan_dhcp tests.test_nodenation_bootstrap tests.test_end0_bootstrap tests.test_ap_health -v
bash tests/test_auto_registry.sh
bash tests/test_halfin_install.sh
bash -n nodenation halfin/pre_install.sh halfin/tools/configure_wan_dhcp.sh
```

Essas verificações cobrem a migração DHCP, recuperação do uplink, bootstrap sem TTY, TUI sem `TERM`, registro do perfil Orange Pi e fluxo de instalação Halfin.

Segredos, chaves, PSKs e senhas não fazem parte desta linha de base.
## Execução inicial

O comando público de instalação é:

```sh
curl -fsSL https://raw.githubusercontent.com/k3zeus/GhostNodes/refs/heads/main/nodenation | bash
```

Em terminal interativo, o bootstrap solicita autorização sudo uma única vez e mantém todas as etapas no mesmo processo root. `sudo su` não é necessário. Em automação sem TTY, usar somente os modos não interativos documentados; a instalação interativa falha de forma explícita antes de alterar o sistema.
