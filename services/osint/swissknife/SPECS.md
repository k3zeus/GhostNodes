# System Specification — SwissKnife OPZ3

## 1. Objetivo

Estação de auditoria de rede portátil (Wi-Fi + LAN) rodando em um Orange Pi Zero 3, cobrindo seis fases: survey wireless passivo, escuta passiva de broadcast/mDNS, descoberta de hosts, scan profundo (OS/versões/scripts), checagem de serviços (TLS/SSH/Web) e geração de relatório consolidado.

Este documento é a re-engenharia do projeto original ("SwissKnife Pi", pensado para Raspberry Pi genérico) especificamente para as características e limitações reais do **Orange Pi Zero 3, variante de 1,5GB de RAM**.

---

## 2. Hardware

| Item | Especificação | Fonte/observação |
|---|---|---|
| SoC | Allwinner H618, quad-core Cortex-A53 @ 1,5GHz, 1MB L2 cache | confirmado — wiki oficial Orange Pi |
| GPU | Mali-G31 MP2 | não relevante para este projeto |
| RAM | 1,5GB LPDDR4 (variante usada aqui) | placa disponível em 1/1,5/2/4GB |
| Armazenamento | MicroSD (32GB+, classe 10+) + 16MB SPI flash (bootloader) | sem eMMC nesta placa |
| Rede cabeada | Gigabit Ethernet onboard | melhor que a maioria dos Pi pequenos |
| Wi-Fi onboard | Unisoc UWE5622, também vendido como AW859A / 20U5622, via SDIO | driver vendor `unisoc_wifi`/`sprdwl_ng`, fora da árvore mainline |
| USB | **1x USB 2.0 host** | limitação real — ver seção 6 |
| Alimentação | USB-C 5V/3A | |

### 2.1. Gotcha de RAM x imagem de SO

A placa é vendida em 4 densidades de RAM diferentes, e o bootloader (U-Boot) precisa da tabela de timing de DRAM correspondente à densidade exata instalada. Builds mainline/genéricos historicamente não cobrem a variante de 1,5GB (o próprio wiki de suporte a hardware sunxi registra isso para o defconfig mainline). **Use a imagem oficial do fabricante para a variante 1,5GB especificamente**, disponível na página de downloads do wiki da Orange Pi — não um build "universal" ou de outra densidade de RAM, mesmo que pareça funcionar (pode bootar reconhecendo só parte da RAM, ou nem bootar).

### 2.2. Wi-Fi onboard não serve para auditoria wireless

O chip Unisoc UWE5622 usa um driver de fornecedor fora da árvore (`sprdwl_ng`/`unisoc_wifi`) que **não implementa modo monitor nem injeção de pacotes** de forma confiável — o mesmo padrão visto em outros SoCs de SBC pequenos (Broadcom no Raspberry Pi, por exemplo). Há também um bug documentado desse driver que derruba a conexão Wi-Fi após um tempo de uso, exigindo recarregar o módulo do kernel ou reiniciar. Por isso:

- O Wi-Fi onboard serve **só como interface de gerência** (SSH para você acessar a placa).
- A fase de survey wireless (`01-wireless-survey.sh`) **exige um adaptador USB externo** com chipset MT7612U ou MT7601U, os únicos com suporte robusto a modo monitor no kernel Linux sem drivers fora da árvore.

---

## 3. Arquitetura de Rede

Com Ethernet Gigabit onboard + Wi-Fi onboard + 1 porta USB, dá para separar os três papéis sem conflito de interface (diferente de placas com só Wi-Fi ou só 1 porta Ethernet):

```
┌─────────────────────────────────────────────────────────────┐
│                    ORANGE PI ZERO 3 (1,5GB)                   │
│                                                                 │
│  eth0 (Gigabit) ──────► LAN AUDITADA (alvo do scan)            │
│  wlan0 (onboard) ─────► Rede de GERÊNCIA (seu SSH de operador) │
│  wlx... (USB externo) ► Modo monitor / survey wireless         │
│                                                                 │
└─────────────────────────────────────────────────────────────┘
```

Essa separação evita o problema clássico de `airmon-ng check kill` derrubar a conexão de gerência: o `install.sh` marca o adaptador USB (`wlx*`) como **não-gerenciado** pelo NetworkManager, então colocá-lo em modo monitor nunca precisa matar o NetworkManager inteiro — o `wlan0` de gerência continua de pé durante toda a auditoria.

---

## 4. Fluxo das 6 Fases

| # | Script | O que faz | Interface usada |
|---|---|---|---|
| 1 | `01-wireless-survey.sh` | Modo monitor, `airodump-ng` (130s) + `wash` (WPS, 45s) | `wlx*` (USB) |
| 2 | `02-passive-listen.sh` | `p0f` + nmap broadcast scripts + `nbtscan` + `avahi-browse` | `eth0` |
| 3 | `03-discovery.sh` | `arp-scan` + `nmap -sn` (ping scan) → lista de hosts vivos | `eth0` |
| 4 | `04-deep-scan.sh` | `nmap -sS -sV -O` + scripts NSE (`safe` ou `vuln`), só nos hosts vivos da fase 3 | `eth0` |
| 5 | `05-service-checks.sh` | `sslscan`/`ssh-audit`/`whatweb` nas portas abertas encontradas | `eth0` |
| 6 | `06-generate-report.py` | Consolida tudo em `report.md` + `report.html` com heurística de risco | — |

`audit-all.sh` roda as seis em sequência dentro de uma sessão `tmux` (recomendado, para sobreviver a quedas de conexão).

---

## 5. Modelo de Risco

Pontuação simples e transparente, sem pretensão de ser um CVSS:

- Cada porta "arriscada" aberta (Telnet, FTP, SMB, RDP, VNC, painéis web sem TLS...) soma pontos fixos por severidade.
- SO com assinatura de versão antiga (Windows XP/7, Linux 2.6, Android 4/5) soma pontos.
- Redes Wi-Fi abertas ou WEP somam o máximo; WPA1 soma alto; WPA2 soma pouco (mas alerta para checar WPS); WPA3 não soma.
- WPS ativo detectado soma um adicional fixo.
- Nota final: A (score 0) até E (score ≥45) — thresholds definidos em `06-generate-report.py`, ajustáveis.

---

## 6. Limitações de hardware documentadas

| Limitação | Impacto | Mitigação adotada |
|---|---|---|
| 1 porta USB 2.0 | Não dá para adaptador Wi-Fi + storage externo ao mesmo tempo | Tudo grava no microSD; capturas devem ser limitadas em tamanho/tempo |
| 1,5GB RAM | nmap + tshark + kismet concorrendo é pesado | `zram` (compressão em RAM, sem desgastar o SD) configurado no `install.sh` |
| Wi-Fi onboard sem monitor mode | Fase 1 não funciona no rádio onboard | Adaptador USB externo obrigatório (MT7612U/MT7601U) |
| Driver Wi-Fi onboard instável | Conexão de gerência pode cair após uso prolongado | Documentado; recarregar módulo ou reiniciar se acontecer |
| Sem imagem "Ubuntu Server" via imager oficial simples | Processo de instalação mais manual que Raspberry Pi | Passo a passo detalhado no README, incluindo o gotcha da variante de RAM |

---

## 7. Regras de Engajamento (obrigatório ler)

> ⚖️ **Escopo legal**
> - Audite **apenas redes que você administra** ou com **autorização por escrito**. No Brasil, varredura/intrusão sem autorização pode enquadrar na **Lei 12.737/2012**, e dados coletados de dispositivos de terceiros entram na **LGPD**.
> - Modo monitor/passivo = baixo risco. **Scan ativo e scripts `vuln` podem derrubar dispositivos frágeis** (IoT, impressoras, equipamentos médicos/industriais). Mapeie o que existe na LAN antes de rodar com `VULN=1`.
> - Nunca capture handshakes/tráfego de redes de terceiros.
> - Documente escopo + autorização por escrito antes de apertar enter.
> - Os relatórios gerados contêm reconhecimento sensível da rede auditada — trate como dado confidencial. `serve-reports.sh` publica só na interface de gerência, nunca na rede auditada, mas ainda assim é HTTP simples (sem TLS) por padrão.

---

## 8. Histórico

Este projeto evoluiu de uma versão original genérica (sem hardware-alvo definido), depois revisada para corrigir nomes de scripts NSE inexistentes, um bug de geração de HTML sem fechamento de tags, e riscos de segurança na publicação dos relatórios — e agora foi re-especificado do zero para as características reais do Orange Pi Zero 3 (RAM 1,5GB, 1 porta USB, Wi-Fi onboard sem modo monitor), que mudam decisões de arquitetura que faziam sentido em outro hardware.
