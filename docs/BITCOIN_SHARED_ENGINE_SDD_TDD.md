# Motor compartilhado Bitcoin — SDD e TDD

## Decisão

`bitcoin/` é o motor compartilhado na raiz do NodeNation. Cada projeto-base fornece somente uma política. Halfin não instala o projeto-base Satoshi.

## Perfil Halfin

- Bitcoin Core 29.1;
- ARM64 e AMD64;
- pruned obrigatório;
- máximo de 5 GiB;
- tamanho efetivo: `min(5 GiB, espaço_livre / 3)`;
- recusa se não puder reservar ao menos 1 GiB de prune;
- dados em `/var/lib/ghostnodes/bitcoin/halfin-core`;
- binários extraídos de tarball para `/opt/ghostnodes/bitcoin/core/29.1` somente após confirmação;
- serviço `ghostnodes-bitcoin-halfin.service`.

## Integridade do release

O manifesto `bitcoin/manifests/bitcoin-core-29.1.json` fixa os URLs oficiais, SHA256 de ARM64/AMD64 e os URLs de `SHA256SUMS` e `SHA256SUMS.asc`. Na instalação, o hash do manifesto deve coincidir com o registro baixado em `SHA256SUMS` e com o artefato. O motor sempre descompacta o `.tar.gz` e exige `bitcoind` e `bitcoin-cli` antes de instalar.

A assinatura é baixada e preservada como artefato de verificação; a próxima evolução deve adicionar um keyring Bitcoin Core versionado e `gpgv` obrigatório antes de ativar downloads em produção.

## Resultados TDD

| Caso | Resultado |
| --- | --- |
| Política Halfin, hashes e delegação do menu | 4/4 testes Python passaram. |
| Plano AMD64 com 14 GiB simulados | Prune calculado: 4 GiB; nenhum download ou escrita. |
| Plano físico ARM64 no Orange Pi `.92` | ARM64 detectado; 55 GiB livres; prune limitado a 5 GiB. |
| Download físico ARM64 no Orange Pi `.92` | SHA256 oficial validado e tarball listado com `bitcoind` e `bitcoin-cli`; arquivos temporários removidos; nenhum serviço instalado. |`n| Plano e download físico AMD64 no Node `.132` | `x86_64` detectado; 11 GiB livres; prune calculado em 3 GiB; SHA256 e tarball Core 29.1 validados; arquivos temporários removidos. |

## Pendente

O teste físico AMD64 no Node `.134` depende de acesso SSH válido para esse host. Nenhuma credencial foi inferida ou reutilizada de outro Node.