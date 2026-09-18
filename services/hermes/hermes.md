# Hermes / Open WebUI

## Fonte oficial

- Projeto: [https://github.com/open-webui/open-webui](https://github.com/open-webui/open-webui)
- Este guia foi revisado em 2026-09-18. Consulte a fonte antes de atualizar versões ou imagens.

## Como instalar em Debian/Ubuntu

No GhostNodes, Hermes é o perfil de integração para o projeto oficial Open WebUI; não é um upstream independente. A instalação básica usa a imagem `ghcr.io/open-webui/open-webui`, volume persistente e uma `WEBUI_SECRET_KEY` aleatória em `/opt/ghostnodes/hermes/.env` com permissão 0600.

O serviço fica em `127.0.0.1:3000`. A conexão com modelos, Telegram e proxy é responsabilidade do perfil da Raiz.

### Execução pelo GhostNodes

```bash
sudo bash services/hermes/hermes.sh
```

Para inspecionar o plano sem modificar o host:

```bash
bash services/hermes/hermes.sh --dry-run
```

## Outras plataformas

O Open WebUI oferece Docker, Python e Kubernetes. O projeto também mantém aplicativo Desktop para Debian/Ubuntu, AppImage, Flatpak, Snap, Windows e macOS. Para produção, o upstream recomenda Docker ou Python.

## Operação e segurança

- Execute o instalador como usuário administrativo; ele solicita `sudo` uma única vez quando necessário.
- Revise portas, volumes, logs e firewall antes de expor o serviço.
- O script é idempotente: um contêiner com o mesmo nome não é substituído automaticamente.
- Atualizações, perfis de uma Raiz e segredos devem ser definidos fora deste guia genérico.
