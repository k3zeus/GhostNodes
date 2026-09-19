# SwissKnife — auditoria OSINT compatível com Halfin

Ferramenta manual de auditoria de LAN e Wi-Fi. Cada execução descobre interfaces físicas reais, descarta interfaces declaradas como AP Halfin e exige IPv4 e rota local para as fases de rede.

## Segurança de rede

- Não há nomes de interface fixos: `end0`, `wlan1`, `enp0s3` e equivalentes são avaliados no host real.
- O AP Halfin é excluído pela configuração NetworkManager e pelo modo wireless AP.
- Entre rotas válidas, a interface com menor métrica é escolhida. `IFACE_LAN` só é aceito após validação.
- `SCAN_RANGE` deve ser sub-rede da interface selecionada.
- O instalador não altera NetworkManager, rotas, aliases, Wi-Fi ou `/etc` de rede.
- Dados e relatórios ficam em `~/logs/osint/swissknife/`, nunca no checkout Git.

## Instalação

`bash install.sh` faz pré-verificação. Para instalar dependências explicitamente, use `SWISSKNIFE_APPLY=1 bash install.sh`.

## Execução

`bash audit-all.sh` valida a LAN antes de cada fase. A fase wireless exige adaptador externo ativo e fora do AP Halfin; informe `IFACE_WLAN=<adaptador>` se necessário.

`serve-reports.sh` não escreve Caddy ou `/etc`; ele gera em `~/logs/osint/swissknife/serve/` o comando manual para publicar relatórios na interface validada.