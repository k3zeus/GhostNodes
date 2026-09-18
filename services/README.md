# Serviços compartilhados

Este diretório é o catálogo canônico de serviços e subprojetos reutilizáveis do GhostNodes. Ele não contém Projetos Raiz.

## Contrato

- `services/<serviço>/` contém a implementação genérica, os padrões seguros, modelos e configuração comum versionada do serviço.
- Cada Projeto Raiz mantém sua identidade, fluxo e decisão de instalação em sua própria pasta (`halfin/`, `satoshi/`, `nash/`, etc.).
- Quando um serviço exigir configuração própria de uma Raiz, ela fica em `<raiz>/services/<serviço>/manifest.env` e nos arquivos declarados por ele. Esse perfil só pode complementar ou especializar o serviço; não deve copiar a implementação comum.
- O bootstrap baixa o monorepo completo. Durante a instalação, a Raiz resolve primeiro a implementação em `services/<serviço>/` e, quando existir, aplica o perfil local da Raiz.
- Dados persistentes, bancos, chaves e senhas não pertencem a este catálogo nem ao perfil versionado da Raiz. Eles permanecem na instalação do Node e nos arquivos de ambiente previstos para cada serviço.

O detalhamento normativo está em [`CONTRACT.md`](CONTRACT.md).`r`n`r`n## Taxonomia inicial

| Serviço | Finalidade comum | Estado |
|---|---|---|
| `docker` | Runtime, rede e componentes de containers | reservado para migração compatível |
| `fail2ban` | proteção contra tentativas de acesso indevidas | reservado para migração compatível |
| `heimdall` | painel de serviços | reservado para migração compatível |
| `hermes` | recursos Hermes compartilháveis | reservado para migração compatível |
| `netbird` | VPN e conectividade privada opcional | reservado para migração compatível |
| `nginx` | proxy reverso e políticas HTTP | reservado para migração compatível |
| `pihole` | DNS e filtragem opcional | reservado para migração compatível |
| `portainer` | administração de containers opcional | reservado para migração compatível |
| `vaultwarden` | cofre de credenciais opcional | reservado para migração compatível |

## Regra de migração

Os scripts existentes em Projetos Raiz e módulos legados continuam sendo a fonte executável até que cada serviço passe por migração individual, com adaptador de compatibilidade e TDD. Nenhum instalador passa a depender deste catálogo vazio nesta alteração.
