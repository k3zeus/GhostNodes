# Sessão: Expansão Arquitetural v2.0 (Módulos Extras)
> Data: 2026-05-11 02:00 | Projeto: GhostNodes

## Objetivo da sessão
Completar a transformação do sistema GhostNodes em um hub soberano completo, integrando os quatro novos módulos (Vault, Hermes, Tailscale, Nostr) no workflow de instalação principal (`nodenation`).

## Contexto (estado antes de começar)
Os quatro módulos haviam sido criados com seus respectivos `install.sh` e arquivos Docker, mas não havia uma forma centralizada de instalá-los através do menu interativo do `nodenation`. O estado do repositório remoto divergia do estado local. O `README.md` refletia uma arquitetura anterior.

## O que foi feito
1. Sincronização do repositório local com o GitHub, confirmando a paridade da branch `main`.
2. Criação da função `menu_extras()` no script `nodenation` para permitir a seleção de módulos adicionais interativamente ou via instrução headless (`--extras`).
3. Refatoração do menu principal `menu_principal()` do `nodenation` para introduzir a opção `[e] Extras`.
4. Atualização completa do `README.md` refletindo a arquitetura `v2.0.0`, com mapa de portas, lista atualizada de módulos e novas instruções de uso de CLI.
5. Push com commit convencional para o GitHub na branch `main`.

## Decisões tomadas
| Decisão | Rationale | Alternativa rejeitada |
|---------|-----------|----------------------|
| Interface Modular via `nodenation` | Manter `nodenation` como único ponto de entrada para manter os Padrões do Projeto. | Exigir rodar scripts `install.sh` de cada módulo separadamente. |
| Implementação Headless | Adicionados `--extras` e `--extras-status` para deployers avançados / scripts de provisionamento. | Requerer menu interativo TUI para uso contínuo. |

## Problemas encontrados e soluções
| Problema | Solução | Status |
|----------|---------|--------|
| Verificação de status dos Extras não existia | Criada função `_extras_module_status` p/ inspecionar states do Docker de cada módulo independentemente. | Resolvido |

## Artefatos gerados
- `nodenation` — atualizado com submenu de extras e args CLI
- `README.md` — reescrito com arquitetura v2.0
- `walkthrough.md` — gerado tutorial no vault log local

## Links
- Plano: (Gerado via brain .gemini interno)
- Tasks: (Gerado via brain .gemini interno)

## Próximos passos
- [ ] Configuração de acesso externo (Cloudflare Tunnels) para Vaultwarden se o usuário não quiser usar apenas Tailscale ingress.

## Resumo executivo (3 linhas — obrigatório)
O repositório foi evoluído para v2.0 com um novo menu `[e] Extras` e controle CLI no `nodenation` para orquestração de módulos soberanos. O `README.md` e a documentação interna foram sincronizados descrevendo as redes Docker, mapa de portas e integração do Vault, Hermes, Tailscale e Nostr. Todo o projeto está espelhado e foi atualizado no branch `main` do repositório GitHub sem divergências.
