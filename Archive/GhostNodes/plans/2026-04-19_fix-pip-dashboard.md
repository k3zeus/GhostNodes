# Plano de Implementação: Correção pip3 e Dependências Dashboard

## 1. Problema Identificado
- Falha `pip3: command not found` no script `nodenation_bootstrap.sh` (linha 876) ao tentar instalar dependências do dashboard web.
- Pacotes `python3-pip` e `python3-venv` ausentes na lista de pré-instalação.

## 2. Escopo Técnica
- **Alvo 1:** `halfin/pre_install.sh`
- **Alvo 2:** `nodenation` (lógica de instalação do dashboard)

## 3. Ações Planejadas
1. Inserir `python3-pip` e `python3-venv` na variável `PKGS` de `pre_install.sh`.
2. Alterar comando de instalação em `nodenation` para `python3 -m pip install --break-system-packages -r requirements.txt` (Necessário para Debian Bookworm).
3. Adicionar verificação de presença do binário antes da execução.

## 4. Validação
- Teste de instalação em ambiente Debian Bookworm limpo.
- Verificação de status do serviço `ghostnodes-dashboard.service`.
