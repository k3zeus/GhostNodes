# SwissKnife — módulo OSINT compartilhado

`services/osint/swissknife/` é um módulo manual de auditoria de LAN e Wi-Fi para projetos raiz que adotem o contrato Halfin. Seu inventário SHA-256 em `SWISSKNIFE.sha256` protege as versões revisadas do bundle.

## Estado

| Item | Estado |
|---|---|
| Catálogo OSINT compartilhado | Registrado |
| Perfil Halfin | Desativado por padrão; uso manual validado |
| TUI e pré-instalação Halfin | Sem integração automática |
| Instalação e varreduras | Manuais e dependentes de autorização |
| Persistência | `~/logs/osint/swissknife/` |

## Contrato Halfin

- Não há interface fixa: a execução descobre interfaces físicas ativas, com IPv4 e rota local.
- Interfaces do AP Halfin são recusadas pela configuração do NetworkManager e pelo modo wireless AP.
- A LAN automática usa a menor métrica entre interfaces elegíveis; uma escolha manual também é validada.
- O survey wireless exige adaptador físico distinto da LAN e fora do AP.
- `SCAN_RANGE` é limitado à sub-rede local selecionada.
- Cada fase propaga erro. Relatório obrigatório ausente encerra o fluxo sem êxito falso.
- O instalador não altera NetworkManager, rotas, aliases, Wi-Fi, arquivos de rede, repositórios externos ou o sistema inteiro.

## Capacidades

1. `01-wireless-survey.sh`: airodump-ng e wash, com adaptador externo em modo monitor.
2. `02-passive-listen.sh`: p0f, SSDP/DNS-SD, NetBIOS e mDNS.
3. `03-discovery.sh`: arp-scan e descoberta Nmap.
4. `04-deep-scan.sh`: versões e scripts Nmap `safe`; `VULN=1` habilita `vuln`.
5. `05-service-checks.sh`: sslscan, ssh-audit e whatweb.
6. `06-generate-report.py`: consolida relatórios Markdown e HTML.

Use somente em redes próprias ou formalmente autorizadas. Consulte o [README do módulo](./swissknife/README.md), a [especificação](./swissknife/SPECS.md) e o [SDD/TDD](../../docs/architecture/SWISSKNIFE_HALFIN_SDD_TDD.md).