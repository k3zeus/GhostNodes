# OSINT defensivo compartilhado

Ferramentas genéricas: Lynis, debsecan, `systemd-analyze`, auditoria SSH, AIDE seletivo, Gitleaks e relatório de exposição com allowlist. Não há Shodan automático, varredura de terceiros ou firewall ativo.

Cada projeto raiz declara a ativação em `<raiz>/services/osint/manifest.env`.

## Módulo preservado

[SwissKnife OPZ3](./SWISSKNIFE.md) é uma estação de auditoria Wi-Fi/LAN manual e inativa por padrão. Seus arquivos não são alterados nem chamados pela instalação Halfin.
