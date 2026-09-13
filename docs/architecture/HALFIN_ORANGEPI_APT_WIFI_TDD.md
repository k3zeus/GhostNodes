# TDD - Orange Pi Zero 3: APT, usuario e Wi-Fi Halfin

## Resultado

`passed` em 2026-09-13 no node de referencia Orange Pi Zero 3, arm64, Debian 12 Bookworm.

## Escopo validado

| ID | Evidencia | Resultado |
| --- | --- | --- |
| APT-01 | `apt-get update` concluiu apos aplicar as tres entradas Debian Huawei Cloud; a fonte Docker separada foi preservada. Backup criado em `/etc/ghostnodes/backups/apt/orangepi-zero3-20260913-180223`. | Aprovado |
| USR-01 / USR-02 | `pleb` possuia home e grupo `sudo`. Quatro processos de `orangepi` adiaram a remocao para unidade one-shot. Apos reboot, `orangepi` nao existe, a unidade ficou `disabled` e o backup `/var/backups/halfin-users/orangepi-20260913-180446.tar.gz` existe. | Aprovado |
| WIFI-02 | Regras Udev persistentes associaram `24:02:fc:ac:45:47` a `wlan0` e `90:de:80:f9:44:3b` a `wlan1`. Os mesmos nomes e MACs estavam presentes apos reboot. | Aprovado |
| REG-01 | Nenhum arquivo do menu `nodenation` foi modificado. O novo fluxo e chamado somente pelas etapas existentes do pre-install Halfin. | Aprovado |
| Boot e rede | O node respondeu a ICMP durante o boot; SSH ficou disponivel apos a inicializacao completa. `NetworkManager` e `hostapd` ficaram `active`. | Aprovado |

## Testes locais

- `python tests/test_halfin_standard_hardware.py`: aprovado.
- `python tests/test_nodenation_privileges.py`: aprovado.
- Sintaxe Bash validada para `halfin/pre_install.sh` e `halfin/tools/standard_hardware.sh` antes da aplicacao no node.

## Observacao operacional

O reboot do hardware de referencia levou cerca de um minuto ate a disponibilidade completa do SSH. A indisponibilidade transitória nao alterou o IP conhecido e nao exigiu IP estatico; e um tempo de boot a ser considerado pelo verificador de saude, nao uma falha de DHCP ou de alias Wi-Fi.