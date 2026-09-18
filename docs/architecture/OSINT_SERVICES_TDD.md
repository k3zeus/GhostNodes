# TDD — serviços OSINT compartilhados

**Data:** 2026-09-18
**Escopo:** scripts em `services/osint/`, perfil Halfin e `services/scripts/scan_network.sh`.

## Critérios aprovados

- Nenhum script baixa ou executa código por pipe.
- Todos os scripts têm sintaxe Bash válida e fim de linha LF.
- `scan_network.sh --local` limita-se a `/24` obtido de `end0` e `wlan1`, deduplica redes iguais e faz inventário de todas as portas TCP para redes locais autorizadas.
- `ssh_audit.sh` pede `sudo`, pois `sshd -T` precisa ler as chaves privadas do host; ele encontra `sshd` mesmo quando `/usr/sbin` não está no `PATH` da sessão do usuário.
- A coleta de exposição externa exige allowlist. Shodan, AIDE e nftables permanecem desativados por padrão no perfil Halfin.

## Execução

| Host | Arquitetura observada | Suíte portátil | Auditorias de leitura |
|---|---|---:|---:|
| `192.168.101.92` | `aarch64` (ARM64) | 2/2 verde | SSH e `systemd-analyze security ssh.service`: verde |
| `192.168.101.132` | `x86_64` (AMD64) | 2/2 verde | SSH e `systemd-analyze security ssh.service`: verde |

A suíte executada foi `python3 tests/test_osint_services.py -v` em uma cópia temporária do conteúdo a publicar. As auditorias foram executadas sem modificar serviços, firewall, rede ou pacotes.

## Limites deliberados

Lynis, debsecan, AIDE e Gitleaks não foram instalados para este teste; seus módulos retornam orientação explícita se estiverem ausentes. A varredura `scan_network.sh --local` e o relatório de exposição não foram disparados: ambos atingem redes ou alvos e só devem ser executados sob a autorização operacional correspondente.
