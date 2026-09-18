# Scripts compartilhados

`scan_network.sh --local` detecta redes IPv4 em `end0` e `wlan1`, reduz cada uma ao `/24` local e gera um relatório TCP completo por rede autorizada em `/var/lib/ghostnodes/security/network-scans/`. Redes repetidas não geram relatórios duplicados.