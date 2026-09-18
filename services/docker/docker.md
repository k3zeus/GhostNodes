# Docker Engine

## Fonte oficial

- Projeto: [https://github.com/docker/docs](https://github.com/docker/docs)
- Este guia foi revisado em 2026-09-18. Consulte a fonte antes de atualizar versões ou imagens.

## Como instalar em Debian/Ubuntu

Instala Docker Engine pelo repositório APT oficial, instala Engine/CLI/containerd/Buildx/Compose e valida com `hello-world`.

1. Remova previamente pacotes Docker conflitantes se já existirem; imagens e volumes não são apagados automaticamente.
2. Instale `ca-certificates` e `curl`, grave a chave oficial em `/etc/apt/keyrings/docker.asc` e o arquivo `docker.sources`.
3. Instale `docker-ce`, CLI, containerd, Buildx e Compose; ative `docker` e valide a imagem de teste.

### Execução pelo GhostNodes

```bash
sudo bash services/docker/docker.sh
```

Para inspecionar o plano sem modificar o host:

```bash
bash services/docker/docker.sh --dry-run
```

## Outras plataformas

A documentação oficial também publica procedimentos para Debian, Fedora, RHEL, CentOS, Raspberry Pi OS, binários estáticos e Docker Desktop em Windows/macOS. Para Arch e derivados, use a documentação da distribuição: não há pacote oficial mantido pela Docker para Arch.

## Operação e segurança

- Execute o instalador como usuário administrativo; ele solicita `sudo` uma única vez quando necessário.
- Revise portas, volumes, logs e firewall antes de expor o serviço.
- O script é idempotente: um contêiner com o mesmo nome não é substituído automaticamente.
- Atualizações, perfis de uma Raiz e segredos devem ser definidos fora deste guia genérico.
