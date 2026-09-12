# Layout de Runtime e Atualização do Halfin

## Decisão proposta

O clone baixado pelo instalador não deve ser a instalação que os serviços executam. Ele é apenas a origem de uma versão verificada. O runtime do equipamento deve separar código de release, configuração, estado persistente e dados de serviço.

```text
/tmp/ghostnodes-stage/<id>/              # estágio descartável do instalador
/opt/ghostnodes/releases/<versão>/       # código imutável de uma release validada
/opt/ghostnodes/current -> releases/...  # release ativa, alterada atomicamente
/opt/ghostnodes/services/<serviço>/       # descritores locais e material de deploy
/etc/ghostnodes/                          # nó-base escolhido e configuração sem segredo no Git
/var/lib/ghostnodes/<serviço>/            # dados persistentes de cada serviço
/var/log/ghostnodes/                      # logs persistentes quando não usados pelo journal
```

`/opt/ghostnodes/services/<serviço>` é para arquivos operacionais que acompanham o deploy local, como manifestos, unidades geradas e metadados da instalação. Segredos ficam fora do Git, em permissões restritas, e os caminhos de dados, portas e usuários de cada serviço são declarados no ambiente operacional correspondente.

## Por que isso facilita atualizações

Separar as pastas resolve a preocupação, mas uma raiz sem alterações não é suficiente para uma atualização segura. A atualização precisa apontar os serviços para uma release identificável, preservar estado fora dela, validar antes do corte e oferecer retorno imediato.

Fluxo proposto:

1. Baixar o repositório para um estágio em `/tmp` e verificar commit, assinatura ou hash definido pela release.
2. Executar pré-validações e testes específicos do perfil Halfin no estágio.
3. Copiar a versão aprovada para `/opt/ghostnodes/releases/<versão>` sem arquivos gerados.
4. Aplicar somente migrações explícitas de configuração ou dados, sempre com backup e reversão.
5. Trocar o link `/opt/ghostnodes/current` para a nova release de modo atômico.
6. Reiniciar apenas as unidades afetadas e executar `halfin-ap check`, incluindo conectividade de administração.
7. Se a validação falhar, devolver o link para a release anterior e reiniciar somente as mesmas unidades.

As unidades systemd e os wrappers devem referenciar `/opt/ghostnodes/current/...`, nunca um clone em `/home/pleb/nodenation` ou em `/tmp`. A identificação do nó-base permanece em `/etc/ghostnodes/installed-node.env`; a instalação deve recusar outro nó-base no mesmo equipamento conforme a topologia do monorepo.

## Situação atual e próximo passo

No Orange Pi validado, os serviços ativos já executam cópias instaladas em `/usr/local/bin`, `/usr/local/lib` e `/usr/local/sbin`; a cópia de recuperação em `/home/pleb/nodenation` não é Git. Falta uma relação verificável entre essas cópias, a release de origem e os remotos. Antes de migrá-lo, é necessário inventariar todos os caminhos de unidades, timers, scripts e arquivos persistentes, criar um backup restaurável e testar o corte em uma janela com Ethernet ou console disponível. Nenhuma mudança em `/opt`, nos serviços ou no equipamento foi feita por esta documentação.
