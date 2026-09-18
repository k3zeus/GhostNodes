# Vaultwarden

## Fonte oficial

- Projeto: [https://github.com/dani-garcia/vaultwarden](https://github.com/dani-garcia/vaultwarden)
- Este guia foi revisado em 2026-09-18. Consulte a fonte antes de atualizar versões ou imagens.

## Como instalar em Debian/Ubuntu

Instale Docker primeiro, crie o volume `vaultwarden_data` e execute `vaultwarden/server:latest`. O script publica HTTP apenas em `127.0.0.1:8080`; coloque proxy TLS e controle de acesso antes de qualquer exposição na rede.

Crie a primeira conta, habilite 2FA e faça backup do volume. Não grave `ADMIN_TOKEN`, domínio ou chaves no repositório.

### Execução pelo GhostNodes

```bash
sudo bash services/vaultwarden/vaultwarden.sh
```

Para inspecionar o plano sem modificar o host:

```bash
bash services/vaultwarden/vaultwarden.sh --dry-run
```

## Outras plataformas

Vaultwarden é suportado pelo upstream como servidor em contêiner ou compilado a partir do código Rust. Para Windows, macOS, Fedora, Suse e Arch, use Docker/Compose ou compile conforme o upstream; não há instalador nativo de produção separado por desktop.

## Operação e segurança

- Execute o instalador como usuário administrativo; ele solicita `sudo` uma única vez quando necessário.
- Revise portas, volumes, logs e firewall antes de expor o serviço.
- O script é idempotente: um contêiner com o mesmo nome não é substituído automaticamente.
- Atualizações, perfis de uma Raiz e segredos devem ser definidos fora deste guia genérico.
