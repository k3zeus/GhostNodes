# SwissKnife OPZ3 — módulo preservado

`services/osint/swissknife/` é uma estação portátil de auditoria de Wi-Fi e LAN voltada ao Orange Pi Zero 3 com 1,5 GB de RAM. O conteúdo foi incorporado sem alteração; [SWISSKNIFE.sha256](./SWISSKNIFE.sha256) guarda a impressão de cada arquivo entregue.

## Estado no GhostNodes

| Item | Estado |
|---|---|
| Catálogo OSINT compartilhado | Registrado |
| Perfil Halfin | Desativado por padrão |
| TUI e pré-instalação Halfin | Sem integração |
| Instalação e varreduras | Manual, nunca automática |
| Arquivos em `swissknife/` | Preservados sem modificação |

## Capacidades inventariadas

1. `01-wireless-survey.sh`: modo monitor, airodump-ng e wash; exige adaptador USB externo `wlx*`.
2. `02-passive-listen.sh`: p0f, SSDP/DNS-SD, NetBIOS e mDNS na LAN.
3. `03-discovery.sh`: arp-scan e descoberta Nmap.
4. `04-deep-scan.sh`: Nmap de SO, versões e scripts `safe`; `VULN=1` habilita scripts `vuln`.
5. `05-service-checks.sh`: sslscan, ssh-audit e whatweb.
6. `06-generate-report.py`: consolida evidências em Markdown e HTML.

O instalador original declara Nmap, arp-scan, aircrack-ng, reaver, tcpdump, tshark, p0f, sslscan, ssh-audit, whatweb, Lynis, zram e Caddy. Ele também executa atualização completa de pacotes e escreve uma regra do NetworkManager que deixa interfaces `wlx*` não gerenciadas. Essas ações permanecem fora do fluxo Halfin.

## Limites e pré-requisitos

- Uso restrito a redes próprias ou formalmente autorizadas.
- Requer Orange Pi Zero 3, Ethernet para a rede auditada e adaptador Wi-Fi USB com modo monitor; o rádio onboard não é adequado para a fase wireless.
- Relatórios contêm inventário sensível e devem permanecer em armazenamento protegido.
- O bundle recebido está achatado: `audit-all.sh` chama `services/01-*.sh`, porém as fases estão diretamente em `swissknife/`. Por decisão de preservação, essa diferença não foi alterada. A ativação futura exige uma especificação separada de layout e teste físico.

Consulte [README do módulo](./swissknife/README.md) e [SPECS](./swissknife/SPECS.md) para instruções e limites originais.