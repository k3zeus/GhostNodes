# Halfin Wi-Fi Runtime State — TDD

**Data:** 2026-09-12  
**Alvo físico:** Orange Pi Zero 3 (`halfin`)  
**Escopo:** persistência local da conexão Wi-Fi e estado do menu.

## Falha reproduzida

O menu é executado pelo usuário do projeto e eleva somente o `nmcli`. Contudo, o instalador criava `halfin/var` durante uma etapa root e sua etapa final só ajustava a pasta pessoal, sem ajustar esse diretório. Como o banco `wifi_scan.db` ficava em `halfin/var`, `Status Wi-Fi` e `Conectar Wi-Fi` falhavam ao criar ou atualizar o banco.

## Contrato aprovado

- Código permanece em `${GN_ROOT}/halfin`.
- O estado mutável do Wi-Fi fica em `${GN_USER_HOME}/.local/state/halfin/wifi`.
- Diretório de estado: modo `0700`, proprietário `GN_USER`.
- Banco SQLite: modo `0600`, proprietário `GN_USER`.
- O instalador copia o banco legado somente quando o novo banco ainda não existe; nunca sobrescreve um banco de runtime existente.
- O NetworkManager continua dono do perfil de conexão e da reconexão automática; `wlan1` permanece o cliente Wi-Fi e `end0` a WAN prioritária.

## TDD executado

| Caso | Evidência | Resultado |
| --- | --- | --- |
| TDD-WIFI-STATE-01 | Regressões de privilégios e conexão | 13/13 testes passaram. |
| TDD-WIFI-STATE-02 | Migração do banco existente no Orange Pi | 8 registros preservados, incluindo 1 credencial confirmada; nenhum segredo foi exibido. |
| TDD-WIFI-STATE-03 | Status Wi-Fi como usuário `pleb` | Scan e consulta ao banco concluíram sem erro. |
| TDD-WIFI-STATE-04 | Permissões | Diretório `0700` e banco `0600`, ambos pertencentes a `pleb`. |
| TDD-WIFI-STATE-05 | Rede após migração | `wlan1` permaneceu conectado; `end0` continuou como rota preferida. |

## Resultado de reconexão

Após uma conexão confirmada pelo operador, o NetworkManager criou um perfil Wi-Fi persistente com reconexão automática habilitada. O banco Halfin registra SSID/BSSID, metadados de scan e a senha somente após confirmação de sucesso. A senha não é exibida pela TUI de status nem por este registro.

## Exportação incremental remota

Não há exportador ou sincronização remota no estado atual. Os importadores existentes trazem perfis do NetworkManager para o SQLite local; eles não enviam dados a outro host.

A próxima especificação deve definir o host de destino, autenticação, criptografia em repouso, esquema de conflito por BSSID e uma chave de exportação. Não usar cópia bruta do SQLite: ela pode expor credenciais e substituir registros do destino em vez de fazer merge incremental.
