# Installation recovery audit

## Estado em 2026-09-05: parcial, nao aprovado para producao

As correcoes estao no working tree, sem commit/push. Esta auditoria encontrou
falhas reais que a suite antiga nao detectava, mas NAO comprovou que todas as
telas, instalacoes, servicos e hardware funcionam. Nao usar os resultados abaixo
como selo de aprovacao integral. Os testes Linux precedem alguns dos ultimos
ajustes; falta executar a matriz sobre a arvore final.

Base local auditada: `57745323476e5323c61e22a44845b4527bb332ac`.
`git fetch origin` foi executado nesta retomada, sem merge/reset/rebase.
GitHub `origin/main`: `0c653412a512a9d171ccea08ce53ecc047341081`, cinco commits
a frente da base local. Incluem Vault/Hermes/Tailscale/Nostr, documentacao e
alteracoes no `nodenation`. Nao foram sobrescritos nem integrados sem testes.
Portanto o sincronismo solicitado ainda NAO esta concluido.

## Objective and constraints

Validate Halfin first, then Satoshi, on disposable Debian and Ubuntu systems.
Preserve the public curl-pipe-bash entrypoint, existing data, SSH access and
unrelated firewall rules. Optional installations must require an affirmative
choice. Do not publish changes during this audit.

## Historical acceptance criteria

Source: conversation `GhostNodes - Projeto`, retrieved 2026-09-05.

- The public main-branch bootstrap must open the menu, including through a pipe.
- Every submenu must offer back and quit; cancelled work must not run installers.
- Wi-Fi status, scan, connection and saved-network database must work together.
- Docker, Portainer and Cockpit must not install without the user's choice.
- Satoshi must have its own Core/Knots, version, full/pruned selection and action.
- Automatic Satoshi uses full with at least 1 TB free, pruned otherwise; manual
  pruning offers 10 GB, 30 GB and a custom value.
- Installed `ghostnode` must keep the banner and find the correct libraries.

## Execution plan

1. Inventory all active Halfin/Satoshi installers, tools and bootstrap paths.
2. Run the existing baseline and capture new failing behavioral regressions.
3. Fix failure propagation, platform handling, installation state and navigation.
4. Validate generated configuration using real parsers and installed packages.
5. Exercise public entrypoints through a PTY on Debian 12 and Ubuntu 24.04.
6. Test service lifecycle, reruns and isolation of unrelated configuration.
7. Record exact results and explicitly unresolved hardware/external dependencies.

## Evidence policy

Mocks prove failure handling only. Syntax checks do not prove installation.
Container results do not prove physical Wi-Fi AP/USB driver support, DHCP leases
on a real LAN, remote SSH survival or a full Bitcoin mainnet synchronization.
Those require separate evidence and must remain listed if not performed.

## Falhas corrigidas e alcance da evidencia

| Area | Causa / correcao | Evidencia / limite |
| --- | --- | --- |
| Pre-instalacao Halfin | APT/extras podiam falhar e ainda registrar sucesso. Etapas em subprocessos Bash estritos; erro propagado; checkpoint v2 distingue falha; lock contra instalacoes simultaneas. | Regressao de falha de APT, pacote e extra; etapas reais selecionadas. Fluxo completo depende de AP fisico. |
| Repositorios e contexto | Fontes Debian sobrescritas, runtime redefinido por globals legado e URL Beta. Fontes do SO preservadas, defaults main e raiz/usuario exportados respeitados. | Falhas reproduzidas em Debian/Ubuntu; testes de preservacao aprovados. |
| Instalacao permanente | Copias concorrentes do dashboard e caminhos pleb fixos. Comando global delega ao dashboard canonico; wrappers antigos delegam ao instalador atual. | `ghostnode --help` real e navegacao em PTY. |
| Dados existentes | Promocao do projeto removia a arvore instalada; chown recursivo atingia dados dos servicos. Atualiza arquivos de codigo sem apagar dados/envs e limita chown. | Sentinela de dados/env preservada no teste; nao equivale a migracao de todos os servicos. |
| Rede/NAT | Regras globais substituidas e interfaces assumidas. Chains proprias HALFIN-FWD/HALFIN-NAT, WAN detectada, validacao previa de AP e configuracao propria da bridge. | Netfilter real: regra NAT alheia preservada e repeticao idempotente; AP ausente falha sem alterar interfaces. Sem teste de radio/lease real. |
| Fail2ban | Jail duplicada/invalida e dependencias incompletas. Arquivo proprio, parser real e espera pela jail sshd. | Instalacao repetida e `fail2ban-client -t` em ambas as distros. |
| Docker/Portainer | Instalacao automatica sem escolha e repositorio incorreto em Ubuntu. Menu explicito, repo por distro, Compose plugin e verificacao do daemon/Portainer. | Instalacao real e repetida em Debian/Ubuntu, Docker aninhado isolado. Stack completa e Cockpit real nao comprovados. |
| Wi-Fi | Parsing fragil de SSID/INI/SQL, banco ausente e loops recursivos. Helper Python compartilhado, SQL parametrizado, navegacao iterativa e senha salva somente apos conexao bem-sucedida. | SQLite real; NetworkManager simulado para parsing/falhas. Quatro testes portaveis adicionais de conexao/cancelamento; sem associacao a radio real. |
| Satoshi | Pipeline de senha gerava SIGPIPE; Knots customizado preso a 29.x; versao nao validada; download sem checksum. Geracao limitada de bytes, major derivado, validacao e SHA256. Caminho RPC env do Compose corrigido. | Core 29.1 real em regtest Debian, config/prune/permissoes/RPC/restart. Knots apenas resolucao de URL; Compose nao executado. |
| TUI | EOF podia aceitar confirmacao; submenus/quit inconsistentes. EOF cancela, dashboard canonico e propagacao de quit do Wi-Fi. | 20 testes PTY iniciais; expansao descrita abaixo. Nao cobre todas as folhas do menu. |
| Painel de sistema | `read UID` escrevia em variavel readonly; HOME/SHELL sobrescritos; FOUND perdido em subshell. Variaveis locais e process substitution, retorno explicito de sucesso. | Dois testes portaveis falharam antes e passaram depois, com saida de SO sintetica; falta PTY do painel inteiro. |
| Pi-hole/Web | DNS interrompido sem recuperacao e pip global/porta 80. Pi-hole baixa antes de parar DNS e tenta restaurar dnsmasq em falha; Web usa venv e 8088. | Somente revisao/sintaxe nesta arvore: execucao real bloqueada. Nao considerar corrigido/validado de ponta a ponta. |

Outros ajustes de baixa abrangencia: shebang na primeira linha em quatro scripts
legados; `fix_docker.sh` propaga falhas; `script_orange3.sh` usa LF. Isso nao valida
os drivers, o atualizador Portainer ou o lifecycle desses componentes.

## Resultados executados

Nao somar as linhas como cobertura unica: varias execucoes repetem os mesmos
casos. Os resultados Linux foram observados nas saidas de execucao anteriores
ao esgotamento do armazenamento. Seus logs brutos ficaram nos containers e nao
foi possivel recupera-los nesta retomada; nao foram recriados artificialmente.

| Execucao | Resultado observado | Interpretacao |
| --- | --- | --- |
| Novos testes de instalacao, base original, Debian 12 | 16 falharam / 1 passou | RED: suite antiga nao detectava essas falhas. |
| Mesma base original, Ubuntu 24.04 | 16 falharam / 1 passou | RED tambem em Ubuntu. |
| Wi-Fi antes do helper | 3 falharam | RED de parsing/banco. |
| Debian, comportamento + Wi-Fi apos correcoes | 20 passaram | Mistura de injecao de falhas e comandos/configuracoes reais. |
| Debian, PTY inicial | 20 passaram | Menu instalado, voltar/sair, cancelar energia, bootstrap e `curl` local pipado ao Bash. |
| Debian, etapas reais | 2 passaram; Docker falhou inicialmente | Falha do laboratorio: overlay aninhado. |
| Debian, Docker apos VFS | 1 passou / 2 deselecionados | Docker e Portainer reais, instalados duas vezes. |
| Ubuntu, comportamento + Wi-Fi + PTY inicial + etapas reais | 43 passaram / 1 warning, 188.81 s | Warning de forkPTY com thread do servidor HTTP de teste. |
| Debian, PTY expandido | 27 passaram / 2 falharam | Harness nao respondia a confirmacoes opcionais nas paginas de rede/Docker. Harness ajustado, SEM reexecucao Linux posterior. |
| Debian, Core 29.1 real | 1 passou, 20.13 s | Regtest, prune 10 GiB, bitcoin.conf 0600, systemd, RPC e restart; sem sincronizar mainnet. |
| Web runtime | Nao executado | Copia para container interrompida por filesystem somente leitura. |
| Retomada, executor seguro | 1 falhou / 4 passaram, depois 5 passaram | RED/GREEN: `.env` sem sufixo escapava do filtro; corrigido. |
| Retomada, painel sistema | 2 falharam, depois 2 passaram | RED/GREEN: UID readonly e falso estado de processos. |
| Retomada, testes portaveis consolidados | 11 passaram | Executor, painel e estados de conexao Wi-Fi. |
| Retomada, suites shell antigas via Git Bash | 91 passaram: 9 + 18 + 24 + 40 | Checks estruturais/parciais; NAO 91 instalacoes/telas reais. |
| Retomada, sintaxe final | 61 arquivos Bash e 24 Python sem erro | Bash com os bytes reais do working tree, sem CRLF; Python AST; `git diff --check` limpo. ShellCheck final nao reexecutado. |

Logs novos preservados localmente em `tests/evidence/` (ignorado pelo Git):
`runner-red.log`, `runner-green.log`, `system-panel-red.log`,
`system-panel-green.log`, `portable-units.log`, `legacy-static.log`,
`final-syntax.log`, `preflight-blocked.log`.

## Bloqueio do laboratorio

O disco Windows `C:` chegou a zero bytes livres. O armazenamento Linux do
Docker passou a somente leitura durante os testes, depois os rootfs ficaram
inacessiveis. O `G:` ainda tinha mais de 60 GB livres. Copiar a arvore inteira
incluindo dependencias ignoradas e usar Docker aninhado contribuiu para a
pressao de armazenamento; esse procedimento nao deve ser repetido.

Nao foi feito `docker system prune`, reset do Docker, reboot, remount ou limpeza
de dados alheios. Ha outros servicos no daemon compartilhado. A remocao dos
containers `gn-tdd-debian12` e `gn-tdd-ubuntu24` e das respectivas imagens
`ghostnodes-tdd:debian12` / `ghostnodes-tdd:ubuntu24` NAO foi confirmada. Depois da
recuperacao do Docker, recuperar logs e remover somente esses recursos de teste.
Nao apresentar o laboratorio antigo como limpo ou a instalacao como concluida.

## Pendencias priorizadas

| ID | Prioridade | Trabalho restante e criterio de aceite |
| --- | --- | --- |
| LAB-01 | Bloqueador | Recuperar espaco e saude do Docker sem remover dados alheios; recuperar evidencias antigas, encerrar recursos do teste e rodar matriz final sequencial. |
| SYNC-01 | Alta | Integrar os cinco commits de origin/main preservando os novos modulos e estas correcoes. Repetir TUI/bootstrap e validacao antes de commit/push. |
| AP-01 | Alta | OrangePi/ARM e radio real: AP, WAN separada, lease DHCP, DNS, NAT, reconexao, reboot e sobrevivencia da sessao SSH. Validar rollback se hostapd/dnsmasq falharem apos escrever configuracao. |
| DNS-01 | Alta | Pi-hole v6 real em Debian/Ubuntu: instalador interativo/unattended, BIND/loopback, resolucao upstream Unbound, DHCP, reinicio e rollback. Validar parametros de rede antes de tocar no DNS. |
| WEB-01 | Alta | Rodar `test_web_runtime.py`: venv, npm/build, usuario sem privilegios, permissoes de arquivos/auth, frontend, API e restart. `nodenation` ainda possui caminho alternativo de pip global; unificar sem perder alteracoes remotas. |
| STACK-01 | Alta | Halfin Compose nao aprovado: Nextcloud recebe variaveis MYSQL apesar do servico PostgreSQL; cloudflared/WG_HOST tem placeholders; PUID/PGID fixos; nginx depende de configuracao ausente na base auditada. Validar cada servico por endpoint e dados persistidos, nao apenas Running. |
| BTC-01 | Alta | Satoshi: preservar bitcoin.conf customizado em repeticao, validar prune/mode antes de aritmetica, verificar readiness sem sucesso falso, e falhas de download/config sem abandonar navegacao. |
| BTC-02 | Alta | Mempool: env_file nao alimenta interpolacao CORE_RPC_* no Compose; RPC bitcoind ligado a loopback nao e acessivel pela bridge Docker. Corrigir mapeamento/rede sem expor RPC publicamente; validar API/frontend/banco real. |
| BTC-03 | Media | Instalar Knots real, verificar assinatura com chaves confiaveis (SHA256 no mesmo servidor nao autentica release), downloads interrompidos e rollback binario. Teste Core atual somente x86_64 regtest. |
| UI-01 | Alta | Reexecutar os 29 casos PTY expandidos, acrescentar painel 1.1/relogio, folhas restantes, erros/EOF/Ctrl-C, terminal 80x24, usuario sudo e latencia. Testes usam teclado textual; nao foi comprovado suporte a mouse. |
| WIFI-01 | Alta | Associacao real WPA/SSID oculto/especiais, no-network/offline/timeout; revisar importadores legados `halfin/nm_import.sh`, `halfin/wpa_import.sh`, `halfin/wifi_connect_debian.sh`, `tools/wpa_import.sh` ainda nao consolidados. |
| HW-01 | Media | Drivers AR9271/RTL8188GU: pacotes por distro, headers/kernel/DKMS e reconexao do USB. Shebang corrigido nao valida firmware Ubuntu nem compilacao ARM. |
| HEAL-01 | Alta | `agents/self_healing.py` chama fix_network/fix_gateway inexistentes, assume wlan0/br0 e Pi-hole em container. Definir inventario real e testar recuperacao, timeout e backoff sem alterar WAN indevidamente. |
| OPS-01 | Media | Atualizador Portainer remove container antes de garantir nova imagem; scan_net nao oferece volta/sair em todos os prompts e aceita ranges amplos/entrada pouco validada. Acrescentar testes de falhas e cancelamento antes de habilitar. |
| TEST-01 | Alta | Runner novo so teve preflight/unidades locais, nao ciclo Docker completo. Testar limites, cleanup, timeout, logs em falha, nova matriz e coleta de JUnit/PTY. Marcadores evitam execucao acidental, mas nao sao sandbox de seguranca. |

## Reproducao segura

Unidades portaveis (nao instalam servicos):

```text
python -B -m unittest discover -s tests -p "test_*.py" -v
```

Preflight do laboratorio, sem criar imagens/containers:

```text
python -B tests/e2e/run_install_matrix.py
```

Somente apos resolver LAB-01, em Docker local de desenvolvimento:

```text
python -B tests/e2e/run_install_matrix.py --run --distro debian12
python -B tests/e2e/run_install_matrix.py --run --distro ubuntu24
```

Linux exige `--docker-storage /caminho/do/filesystem-do-docker`. No Windows,
o padrao verifica C:; se Docker foi movido, informar o caminho real. O executor
continua verificando tambem o disco de sistema Windows.
O executor
exige 30 GiB livres por padrao (minimo configuravel 15), verifica espaco durante
os comandos e interrompe ao cair abaixo do limite. Recusa contexto Docker
remoto, executa uma distro por vez, usa nomes/labels exclusivos, tenta remover
somente seus containers/imagens e conserva logs em `tests/evidence/<run-id>`.
O daemon aninhado usa VFS; nao monta o socket Docker do host nem a arvore
do projeto com escrita. A imagem executa systemd com privilegios, portanto
nao e uma fronteira segura para codigo hostil.

Snapshot inclui somente arquivos versionados/nao ignorados, excluindo dados,
venvs, logs, senhas, chaves e envs locais, salvo `var/globals.env` de defaults.
Build recebe apenas Dockerfile e daemon.json. Os testes de instalacao recusam
execucao fora da imagem marcada com `GN_TDD_DISPOSABLE=1`.

Aceite final: matriz final verde apos integrar origin/main, evidencias de
instalacao/reinstalacao/servicos e hardware, pendencias altas resolvidas ou
funcionalidades explicitamente desabilitadas. Ate la, manter como WIP.

Referencias oficiais consultadas durante a correcao:
[Docker no Ubuntu](https://docs.docker.com/engine/install/ubuntu/) e
[configuracao Pi-hole FTL](https://docs.pi-hole.net/ftldns/configfile/).
Consulta de documentacao nao substitui os testes pendentes de DNS/Compose.
