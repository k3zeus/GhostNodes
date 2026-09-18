# Pi-hole

## Fonte oficial

- Projeto: [https://github.com/pi-hole/pi-hole](https://github.com/pi-hole/pi-hole)
- Este guia foi revisado em 2026-09-18. Consulte a fonte antes de atualizar versões ou imagens.

## Como instalar em Debian/Ubuntu

Baixe o instalador oficial para arquivo temporário e execute-o localmente. Ele é interativo porque IP estático, interface, upstream DNS, serviço DHCP e senha administrativa são decisões específicas da rede. Não execute em um Node que já ofereça DHCP/DNS sem revisar os conflitos.

Após a instalação, confirme a interface e configure a senha com `pihole -a -p` antes de apontar clientes para o serviço.

### Execução pelo GhostNodes

```bash
sudo bash services/pihole/pihole.sh
```

Para inspecionar o plano sem modificar o host:

```bash
bash services/pihole/pihole.sh --dry-run
```

## Outras plataformas

O instalador oficial é para Linux. Para outras plataformas use uma máquina virtual Linux ou o projeto oficial Docker do Pi-hole; Windows, macOS, Fedora, Suse e Arch não têm o mesmo fluxo APT direto documentado pelo instalador principal.

## Operação e segurança

- Execute o instalador como usuário administrativo; ele solicita `sudo` uma única vez quando necessário.
- Revise portas, volumes, logs e firewall antes de expor o serviço.
- O script é idempotente: um contêiner com o mesmo nome não é substituído automaticamente.
- Atualizações, perfis de uma Raiz e segredos devem ser definidos fora deste guia genérico.
