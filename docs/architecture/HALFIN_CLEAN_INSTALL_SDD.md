# SDD — Instalação Limpa Halfin no Orange Pi Zero 3

## Status

**Execução autorizada; recuperação de uplink aprovada por TDD físico.**

Data da descoberta: 2026-09-12.

## Understanding

O objetivo é validar, a partir de um sistema limpo, o bootstrap único do GhostNodes e instalar o Halfin até o mesmo conjunto de rede e serviços validado no equipamento de referência. A execução deve deixar evidências TDD no repositório e não pode confundir uma simulação local com uma instalação física real.

## Update: fatos confirmados

| Item | Resultado |
| --- | --- |
| Alvo | `192.168.101.92`, hostname atual `orangepizero3` |
| Hardware | `OrangePi Zero3`, arm64, 1,4 GiB RAM, 56 GiB livres |
| Sistema real | Orange Pi OS 1.0.4 / **Debian 12 Bookworm**; não Ubuntu |
| Kernel | `6.1.31-sun50iw9` |
| WAN atual | `end0` por DHCP explícito do Halfin; lease, rota padrão e DNS validados após reboot. |
| Rádio AP | `wlan0` |
| Rádio cliente | `wlan1`, alias udev persistente do MAC `90:de:80:f9:44:3b`, validado após reboot |
| Registro automático | `var/auto.sh` reconhece Orange Pi Zero 3 + arm64 + Bookworm e aponta para `halfin/pre_install.sh` |
| Fonte remota | GitHub e Forgejo `main` na revisão `b8e178a1813b88e58a3bb622c5d1b2c676316e09` |
| Download pelo alvo | GitHub respondeu HTTPS 200 para o bootstrap fixado |
| Testes locais | registro 9/9, fluxo Halfin 24/24 e AP 11/11 aprovados |

## Confront

1. O equipamento informado como “Orange Pi Aero 3 com Ubuntu” identifica-se como Orange Pi Zero 3 com Debian Bookworm. O perfil protegido é compatível, mas essa divergência deve constar da evidência final.
2. O cliente Wi-Fi inicialmente se chamava `wlx90de80f9443b`. A opção de alias do nodenation foi reproduzida de forma limitada: uma regra udev persistente para o MAC confirmado foi criada, o host reiniciou e o adaptador voltou como `wlan1`.
3. Não há `--dry-run` no `nodenation` nem no `halfin/pre_install.sh`. A instalação completa cria usuário, atualiza pacotes, troca hostname, escreve rede/AP e habilita unidades. Logo, não existe simulação física completa sem alterar a máquina.
4. O TDD existente confirma comportamento portátil e o hardware de referência Debian, mas ainda lista AP real, DHCP/DNS, NAT, reconexão e reboot como validações físicas obrigatórias. O novo teste deve produzir essas evidências, não apenas repetir testes de sintaxe.

## Architecture

O `nodenation` é o único bootstrap. Ele baixa o projeto para estágio em `/tmp`, carrega `var/auto.sh` do estágio, detecta o perfil Halfin, pede confirmação e então executa `halfin/pre_install.sh`. O instalador preserva checkpoints e interrompe na primeira etapa com falha.

A fonte para este teste deve ser imutável e rastreável:

- revisão: [`b8e178a1813b88e58a3bb622c5d1b2c676316e09`](https://github.com/k3zeus/GhostNodes/tree/b8e178a1813b88e58a3bb622c5d1b2c676316e09)
- bootstrap: [`nodenation fixado`](https://raw.githubusercontent.com/k3zeus/GhostNodes/b8e178a1813b88e58a3bb622c5d1b2c676316e09/nodenation)

Comando de execução aprovado, a ser usado somente em terminal SSH/console interativo:

```sh
curl -fsSL https://raw.githubusercontent.com/k3zeus/GhostNodes/b8e178a1813b88e58a3bb622c5d1b2c676316e09/nodenation \
  | sudo bash
```

O menu deve apresentar o Halfin detectado e exigir confirmação. Não usar `main`, URL sem revisão ou um script paralelo para este teste.

## Step-by-step plan

1. Registrar estado inicial: SO, kernel, interfaces, rotas, espaço, hostname, revisão e hash do bootstrap.
2. Executar somente `--detect-hw` pelo bootstrap fixado e salvar sua saída como evidência de seleção de perfil.
3. Confirmar que `wlan0` é o AP e `wlan1` é o cliente persistente; manter Ethernet/console disponível durante toda a instalação.
4. Executar o bootstrap acima, selecionar Halfin e confirmar o plano uma única vez.
5. Acompanhar cada checkpoint do `pre_install.sh`: usuário, atualização, ferramentas, ownership de rede, bridge/AP, extras selecionados, dashboard e permissões.
6. Se uma etapa falhar, interromper; coletar logs e estado. Repetir somente a etapa indicada pelo checkpoint, sem reiniciar o instalador inteiro às cegas.
7. Depois da instalação, validar `halfin-ap check`, unidades, ownership de interfaces, FTL versus dnsmasq, rota/failover, Tailscale DNS, acesso SSH e `halfin-end0-ensure.service`.
8. Executar um reboot controlado, repetir as verificações e validar que a sessão administrativa retorna.
9. Registrar o TDD final com comandos, resultados, limites e a revisão exata. Não registrar senhas, PSKs, arquivos `.env` ou conteúdo de `hostapd.conf`.

## TDD acceptance criteria

| ID | Critério |
| --- | --- |
| TDD-01 | O bootstrap fixado detecta o Orange Pi Zero 3 e oferece Halfin. |
| TDD-02 | O instalador usa `wlan0` como AP e `wlan1` como cliente; o cliente não aparece em `interfaces` nem recebe `wpa_supplicant`/`dhclient` paralelo. |
| TDD-03 | `halfin-ap check` retorna sem problemas; bridge `br0` possui `10.21.21.1/24`; hostapd está pronto. |
| TDD-04 | Há um único dono de DHCP/DNS: FTL ou dnsmasq, nunca os dois. |
| TDD-05 | `end0` é primária com DHCP explícito; o cliente Wi-Fi só assume como contingência com tabela de política e métricas corretas. |
| TDD-06 | `tailscale --accept-dns=false` preserva o resolvedor local quando Tailscale for selecionado. |
| TDD-07 | Após reboot, `end0` tem IPv4 e rota padrão, e AP, DNS/DHCP, acesso SSH e health timer retornam sem reparo manual. |
| TDD-08 | Toda evidência identifica a revisão `b8e178a…`; segredos ficam fora do Git. |

## Risks and rollback

A etapa de rede pode interromper SSH. Ethernet ou console físico são obrigatórios. O instalador de AP cria cópia em `/var/backups/halfin-ap/<data-pid>` e arma rollback; validar esse backup antes de depender dele. Falha do driver, do rádio USB, do AP do cliente, Pi-hole ou Docker não deve ser mascarada como sucesso.

## Assumptions

- O endereço `192.168.101.92` continua acessível pela Ethernet durante o teste.
- O adaptador persistente `wlan1` é o rádio cliente desejado e possui driver/firmware funcional.
- As opções extras serão explicitamente selecionadas; Docker, Pi-hole, Tailscale e dashboard não são considerados aprovados apenas porque o bootstrap os apresenta.

## Approval status

**approved-with-constraints** — autorização recebida em 2026-09-12. A regra udev de alias e o reboot foram concluídos e validados. A execução deve usar somente a revisão fixada, manter Ethernet ou console disponível, parar na primeira falha e registrar os resultados TDD sem segredos.

## Review

A especificação preserva o bootstrap único e a seleção automática existente, fixa a revisão remota e corrige a única incompatibilidade detectada de interface. A recuperação de uplink, DHCP explícito e os desvios TDD-F01/F02 foram validados; uma nova imagem limpa deve repetir o fluxo completo como evidência de regressão de lançamento.
