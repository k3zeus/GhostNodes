# Walkthrough: GhostNodes Audit & Restoration (v.1.22t)
> Data: 2026-04-14 | Sessão: audit_and_fixes

## Mudanças Realizadas

### Bootstrap (`nodenation`)
- Corrigida inicialização da variável `$HAS_PRE`.
- Adicionado `.gitattributes` para LF enforcement.

### Instalação (`halfin/pre_install.sh`)
- Restaurada declaração da função `etapa_extras()`.

### Web Dashboard
- Criado `web/frontend/src/ApplicationsTab.jsx`.
- Priorização de rotas de API sobre static files no `main.py`.
- Windows Guard no `bitcoin.py` para evitar crashes em ambiente de dev.

## Validação
- 73/73 testes básicos de sintaxe e estrutura.
- 12/13 testes de API (FastAPI TestClient).
- Git Tag `v.1.22t` gerada.
