# SDD - perfil padrao Orange Pi Zero 3: APT, usuario e radios Halfin

## Status

`implemented-and-validated` - implementacao aprovada e validada no Orange Pi Zero 3 de referencia em 2026-09-13.

## Understanding

O Halfin possui dois comportamentos que precisam voltar a ser automatizados sem ampliar o escopo do instalador:

1. Somente o perfil padrao detectado como Orange Pi Zero 3, arm64, Debian Bookworm deve trocar as fontes APT para o espelho aprovado e concluir a migracao de `orangepi` para `pleb`.
2. Todo Halfin deve descobrir radios Wi-Fi e produzir nomes persistentes: `wlan0` para AP e, quando existir segundo radio, `wlan1` para cliente.

Menus existentes, a rota generica Halfin, opcoes manuais de sources.list e alias, regras de rede ja validadas e projetos fora do Halfin ficam fora do escopo.

## Update: fatos confirmados

- `var/auto.sh` ja reconhece Orange Pi Zero 3 + arm64 + Bookworm como perfil protegido e direciona para `halfin/pre_install.sh`.
- `etapa_sourcelist` hoje somente valida Debian/Ubuntu e preserva fontes.
- O node de referencia utiliza Bookworm pelo espelho Huawei Cloud; a lista Docker ARM64 fica em arquivo separado.
- `_cfg_sourcelist` e `_cfg_alias_interface` existem somente no menu manual; eles nao devem ser modificados.
- `etapa_alias_wifi` hoje nao nomeia radios. O restante da rede pressupoe AP em `wlan0` e, quando presente, cliente em `wlan1` controlado apenas pelo NetworkManager.
- A recuperacao operacional validada exige que `wlan0` e `br0` fiquem fora do NetworkManager; `wlan1` e somente cliente do NetworkManager.

## Confront

A ordem de interfaces retornada por `iw dev` nao e uma identidade estavel. Uma implementacao que simplesmente escolhesse a primeira interface como AP poderia inverter os radios apos reboot ou replug. A regra deve gravar Udev por MAC e definir a escolha uma unica vez, com evidencia no log.

Tambem nao e seguro apagar `orangepi` na mesma sessao que executa o instalador. A exclusao precisa ocorrer apenas depois que `pleb` existir, tiver home, grupo sudo e um teste de sudo nao interativo concluido; se a sessao atual ou algum processo ativo ainda pertencer a `orangepi`, a exclusao deve ser adiada para uma unidade one-shot no proximo boot.

## Architecture

### A. Perfil exclusivo Orange Pi Zero 3

Uma funcao interna `is_orangepi_zero3_baseline` devera retornar sucesso somente quando todos os itens forem verdadeiros:

- modelo corresponde ao registro Orange Pi Zero 3;
- arquitetura normalizada e `arm64`;
- sistema corresponde a Debian Bookworm.

Nenhum outro Halfin, inclusive Orange Pi Zero 2W, Raspberry Pi, AMD64, Ubuntu ou a rota generica, executara os passos APT ou de substituicao de usuario abaixo.

#### APT no perfil padrao

1. Criar backup datado e restrito de `/etc/apt/sources.list` e de toda a arvore `sources.list.d` em `/etc/ghostnodes/backups/apt/`.
2. Preservar fontes de terceiros, incluindo Docker; alterar somente as entradas Debian Bookworm administradas pelo Halfin.
3. Escrever o conjunto aprovado Huawei Cloud para `bookworm`, `bookworm-updates` e `bookworm-backports`, com `main contrib non-free non-free-firmware`.
4. Executar `apt-get update` com falha estrita.
5. Se a atualizacao falhar, restaurar o backup integral e executar novo `apt-get update`; a etapa falha visivelmente se a recuperacao nao funcionar.
6. Registrar no log: perfil detectado, backup, espelho selecionado, resultado e rollback se aplicavel. Nunca registrar credenciais nem conteudo de fontes privadas.

#### Migracao de usuario no perfil padrao

1. Criar e validar `pleb` antes de qualquer remocao.
2. Verificar home existente e pertencente a `pleb`, alem do grupo `sudo`, antes de qualquer remocao.
3. Remover `orangepi` e sua home somente se nao for o usuario da sessao ativa e nao possuir processos ativos.
4. Caso contrario, criar uma unidade one-shot restrita que executa apos o primeiro boot bem-sucedido, revalida os mesmos criterios e remove o usuario. A unidade remove a si propria somente apos sucesso.
5. A falha de migracao de usuario nao reverte APT, rede ou instalacao; ela deixa estado e instrucao objetiva no log.

### B. Descoberta e aliases Wi-Fi em todo Halfin

A etapa ocorre antes da configuracao de AP e nao edita menu algum.

1. Enumerar interfaces por `/sys/class/net`, reconhecendo radios por `wireless` ou `phy80211`; validar que cada interface possui MAC e dispositivo correspondente.
2. Preservar imediatamente nomes ja estaveis `wlan0` e `wlan1`, desde que apontem para MACs distintos.
3. Para interfaces sem nomes estaveis, escolher AP por esta ordem deterministica:
   - interface ja nomeada `wlan0`;
   - radio integrado identificado pelo caminho de barramento;
   - menor caminho persistente de dispositivo como desempate.
4. A outra interface, quando existir, e o cliente `wlan1`.
5. Gravar regras Udev por MAC, nunca por nome temporario; salvar um manifesto nao secreto dos MACs e papeis em `var/hardware.env` e no log.
6. Aplicar nomes sem derrubar uma sessao de administracao. Quando o kernel nao puder renomear ao vivo, usar os nomes reais nesta execucao e informar que a persistencia entra no proximo boot. A configuracao de AP nunca deve assumir que uma troca ao vivo ocorreu.

| Radios detectados | Acao | Resultado esperado |
| --- | --- | --- |
| 0 | Nao altera interfaces, NetworkManager ou hostapd. | Mensagem e log: nenhum radio encontrado; AP nao pode ser configurado. A instalacao para na etapa de AP, sem tocar rede existente. |
| 1 | Define o unico radio como `wlan0` e cria regra Udev por MAC. | Configura AP e acesso Wi-Fi direto. Mensagem e log: `wlan1` ausente; conectar segundo adaptador e configurar depois manualmente. |
| 2 | Define AP como `wlan0` e cliente como `wlan1`; cria duas regras por MAC. | AP fora do NetworkManager; cliente exclusivamente no NetworkManager e disponivel para failover. |
| Mais de 2 | Nao adivinha papeis adicionais. | Usa somente os dois selecionados, lista os excedentes no log e nao os altera. |

## Step-by-step plan

1. Criar funcoes puras de deteccao do perfil Orange Pi e de inventario Wi-Fi, sem chamadas de menu.
2. Criar fixtures para 0, 1, 2 e 3 radios, incluindo nomes temporarios e MACs estaveis.
3. Implementar o contrato APT apenas atras do guard do perfil completo, com backup, verificacao e rollback.
4. Implementar a migracao adiada de `orangepi` com unidade one-shot auditavel.
5. Implementar regras Udev e manifesto por MAC; manter nomes reais enquanto o reboot nao ocorrer.
6. Integrar as novas funcoes somente nas etapas existentes `etapa_sourcelist`, `etapa_usuario` e `etapa_alias_wifi` do Halfin; nao tocar no menu `nodenation`.
7. Executar testes unitarios e uma instalacao limpa no Orange Pi Zero 3 com console/Ethernet disponivel.
8. Validar reboot: espelho APT, login `pleb`, ausencia de `orangepi`, AP `wlan0`, cliente `wlan1` quando houver segundo radio, DHCP de `end0`, SSH, DNS e health check.

## TDD acceptance criteria

| ID | Criterio |
| --- | --- |
| APT-01 | Perfil Orange Pi Zero 3 arm64 Bookworm troca somente fontes Debian aprovadas e mantem fontes de terceiros. |
| APT-02 | Qualquer perfil diferente preserva byte a byte as fontes APT. |
| APT-03 | Falha de `apt-get update` restaura backup e falha de forma visivel. |
| USR-01 | `orangepi` nao e removido antes de `pleb` e sudo serem validados. |
| USR-02 | Sessao ou processo ativo de `orangepi` adia a remocao; reboot executa a unidade uma unica vez. |
| WIFI-00 | Zero radios nao altera rede e informa bloqueio de AP. |
| WIFI-01 | Um radio torna-se `wlan0`; AP inicia; ausencia de `wlan1` aparece em tela e log. |
| WIFI-02 | Dois radios recebem MACs persistentes para `wlan0` e `wlan1`; reboot conserva papeis. |
| WIFI-03 | `wlan1` nao recebe ifupdown, wpa_supplicant ou dhclient fora do NetworkManager. |
| REG-01 | Menus atuais, selecao generica, Raspberry Pi, Orange Pi Zero 2W e AMD64 nao mudam de comportamento. |

## Risks and rollback

- Trocar APT pode interromper atualizacoes: backup e rollback automatico sao obrigatorios.
- Remover usuario pode cortar SSH: a unidade adiada e a validacao de `pleb` sao obrigatorias.
- Renomear radio pode interromper AP ou cliente: regras por MAC, uso de nomes reais na sessao corrente e reboot controlado evitam depender de renomeacao ao vivo.
- A ausencia de radio e uma condicao de hardware, nao uma falha a ser mascarada por criar interfaces falsas.

## Assumptions

- Huawei Cloud continua sendo o espelho aprovado para a imagem Orange Pi Zero 3 Bookworm.
- O perfil padrao mantem Ethernet ou console disponivel durante a primeira instalacao.
- `pleb` continua sendo o usuario administrativo oficial do Halfin.

## Approval status

`approved and executed` - autorizacao explicita recebida para TDD no node `.92` e publicacao somente apos aprovacao dos testes.

## Review

A implementacao restaura somente as duas automacoes solicitadas. APT e migracao de usuario ficaram restritos ao perfil padrao completo. A descoberta de radios e geral para Halfin, mas nao modifica menus nem inventa interfaces quando o hardware nao existe. A evidencia de TDD esta em `docs/architecture/HALFIN_ORANGEPI_APT_WIFI_TDD.md`.
