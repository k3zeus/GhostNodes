# Fail2Ban

## Fonte oficial

- Projeto: [https://github.com/fail2ban/fail2ban](https://github.com/fail2ban/fail2ban)
- Este guia foi revisado em 2026-09-18. Consulte a fonte antes de atualizar versões ou imagens.

## Como instalar em Debian/Ubuntu

Instale pelo repositório da distribuição: `apt-get update` e `apt-get install fail2ban python3-systemd`; ative a unidade e valide-a. A configuração local deve ser criada em `jail.d/*.local`, nunca editando `jail.conf` diretamente.

O upstream também documenta instalação por fonte: clone ou tarball, Python 3.5+, setuptools e `python setup.py install`. Essa via não instala automaticamente a unidade de serviço.

### Execução pelo GhostNodes

```bash
sudo bash services/fail2ban/fail2ban.sh
```

Para inspecionar o plano sem modificar o host:

```bash
bash services/fail2ban/fail2ban.sh --dry-run
```

## Outras plataformas

O upstream recomenda preferir o pacote nativo de cada distribuição. Para Fedora/RHEL use o gerenciador RPM da distribuição; para Arch, `pacman`; para BSD, o sistema de pacotes local. Não existe suporte nativo para Windows; use um host Linux.

## Operação e segurança

- Execute o instalador como usuário administrativo; ele solicita `sudo` uma única vez quando necessário.
- Revise portas, volumes, logs e firewall antes de expor o serviço.
- O script é idempotente: um contêiner com o mesmo nome não é substituído automaticamente.
- Atualizações, perfis de uma Raiz e segredos devem ser definidos fora deste guia genérico.
