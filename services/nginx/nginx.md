# NGINX Open Source

## Fonte oficial

- Projeto: [https://github.com/nginx/nginx](https://github.com/nginx/nginx)
- Este guia foi revisado em 2026-09-18. Consulte a fonte antes de atualizar versões ou imagens.

## Como instalar em Debian/Ubuntu

Instale `nginx` pelo APT, ative a unidade e valide seu estado. O pacote da distribuição é a opção mais simples para Debian/Ubuntu. Para recursos ou versões do repositório oficial nginx.org, siga a documentação de pacotes do projeto e troque a origem APT conscientemente.

Antes de expor um virtual host, teste com `nginx -t` e aplique TLS e autenticação no perfil da Raiz.

### Execução pelo GhostNodes

```bash
sudo bash services/nginx/nginx.sh
```

Para inspecionar o plano sem modificar o host:

```bash
bash services/nginx/nginx.sh --dry-run
```

## Outras plataformas

O NGINX possui instruções oficiais para pacotes RPM, compilação da fonte e binário para Windows. Fedora, RHEL e Suse devem usar os pacotes oficiais da distribuição ou nginx.org; Arch usa seu pacote da distribuição.

## Operação e segurança

- Execute o instalador como usuário administrativo; ele solicita `sudo` uma única vez quando necessário.
- Revise portas, volumes, logs e firewall antes de expor o serviço.
- O script é idempotente: um contêiner com o mesmo nome não é substituído automaticamente.
- Atualizações, perfis de uma Raiz e segredos devem ser definidos fora deste guia genérico.
