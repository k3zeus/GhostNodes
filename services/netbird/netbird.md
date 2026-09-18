# NetBird

## Fonte oficial

- Projeto: [https://github.com/netbirdio/netbird](https://github.com/netbirdio/netbird)
- Este guia foi revisado em 2026-09-18. Consulte a fonte antes de atualizar versões ou imagens.

## Como instalar em Debian/Ubuntu

Baixe o instalador oficial para arquivo temporário, execute-o localmente e ative a unidade `netbird`. O script oficial detecta APT e adiciona o repositório do NetBird. Depois, vincule o nó explicitamente com uma setup key ou login interativo; o instalador não recebe nem grava chaves.

Use `netbird status` após o vínculo para confirmar conectividade.

### Execução pelo GhostNodes

```bash
sudo bash services/netbird/netbird.sh
```

Para inspecionar o plano sem modificar o host:

```bash
bash services/netbird/netbird.sh --dry-run
```

## Outras plataformas

O instalador oficial também detecta `yum`, `dnf` e `rpm-ostree`. O cliente possui aplicações para Windows, macOS e Linux; siga a documentação oficial do cliente para esses ambientes.

## Operação e segurança

- Execute o instalador como usuário administrativo; ele solicita `sudo` uma única vez quando necessário.
- Revise portas, volumes, logs e firewall antes de expor o serviço.
- O script é idempotente: um contêiner com o mesmo nome não é substituído automaticamente.
- Atualizações, perfis de uma Raiz e segredos devem ser definidos fora deste guia genérico.
