# Heimdall Dashboard

## Fonte oficial

- Projeto: [https://github.com/linuxserver/docker-heimdall](https://github.com/linuxserver/docker-heimdall)
- Este guia foi revisado em 2026-09-18. Consulte a fonte antes de atualizar versões ou imagens.

## Como instalar em Debian/Ubuntu

Heimdall é distribuído oficialmente para homelab pela imagem LinuxServer.io. Primeiro instale Docker. Em seguida, crie o contêiner `lscr.io/linuxserver/heimdall:latest`, persistindo `/config` em volume e definindo PUID, PGID e fuso horário.

O script vincula HTTP somente a `127.0.0.1:8080` por padrão. Coloque Nginx, Tailscale ou outro proxy autenticado à frente antes de publicar o painel.

### Execução pelo GhostNodes

```bash
sudo bash services/heimdall/heimdall.sh
```

Para inspecionar o plano sem modificar o host:

```bash
bash services/heimdall/heimdall.sh --dry-run
```

## Outras plataformas

A imagem é multi-arquitetura amd64 e arm64. Em Fedora, Suse, Arch, Windows ou macOS, instale um runtime Docker compatível e use o mesmo Compose/CLI; não há instalador Heimdall nativo separado suportado pelo projeto LinuxServer.

## Operação e segurança

- Execute o instalador como usuário administrativo; ele solicita `sudo` uma única vez quando necessário.
- Revise portas, volumes, logs e firewall antes de expor o serviço.
- O script é idempotente: um contêiner com o mesmo nome não é substituído automaticamente.
- Atualizações, perfis de uma Raiz e segredos devem ser definidos fora deste guia genérico.
