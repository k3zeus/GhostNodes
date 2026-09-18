# Portainer CE

## Fonte oficial

- Projeto: [https://github.com/portainer/portainer](https://github.com/portainer/portainer)
- Este guia foi revisado em 2026-09-18. Consulte a fonte antes de atualizar versões ou imagens.

## Como instalar em Debian/Ubuntu

Instale Docker primeiro, crie o volume `portainer_data` e execute `portainer/portainer-ce:lts` com acesso ao socket Docker. O script expõe a interface HTTPS somente em `127.0.0.1:9443` e a porta Edge em loopback; use um proxy autenticado ou VPN para acesso externo.

A primeira visita cria a conta administrativa. Guarde essa credencial fora do repositório.

### Execução pelo GhostNodes

```bash
sudo bash services/portainer/portainer.sh
```

Para inspecionar o plano sem modificar o host:

```bash
bash services/portainer/portainer.sh --dry-run
```

## Outras plataformas

Portainer é distribuído principalmente como contêiner e também possui métodos para Kubernetes. Windows e macOS usam Docker Desktop; Fedora, Suse e Arch usam o runtime Docker/Podman compatível de sua distribuição e o mesmo contêiner.

## Operação e segurança

- Execute o instalador como usuário administrativo; ele solicita `sudo` uma única vez quando necessário.
- Revise portas, volumes, logs e firewall antes de expor o serviço.
- O script é idempotente: um contêiner com o mesmo nome não é substituído automaticamente.
- Atualizações, perfis de uma Raiz e segredos devem ser definidos fora deste guia genérico.
