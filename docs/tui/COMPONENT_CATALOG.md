# Catálogo de componentes TUI

> Referência visual do contrato em `TUI_DESIGN_SPEC.md`.

## Header compacto

```text
GHOST NODES / HALFIN
Host: halfin | Rede: online | 14/09/2026 10:32
```

Em cor: identidade cyan, metadados discretos. Em terminal simples: somente texto e separador ASCII.

## Título e contexto

```text
---------------- [ REDE / WI-FI ] ----------------
```

O caminho deve informar o local atual. O título não usa cor de perigo.

## Opção em lista compacta

```text
> [2] Conexões de rede
    Wi-Fi, uplink e diagnóstico
```

`>` é obrigatório como fallback de foco. A descrição é limitada a duas linhas visuais.

## Card médio ou amplo

```text
+----------------------------+
| > [2] CONEXÕES DE REDE     |
|   Wi-Fi, uplink e          |
|   diagnóstico              |
+----------------------------+
```

Em UTF-8 podem ser usadas bordas simples e ícone. A versão ASCII sempre é equivalente.

## Barra de ajuda

```text
[setas] mover  [ENTER] abrir  [1-9] direto  [0/b] voltar  [q] sair
```

A barra mostra somente teclas ativas no contexto.

## Painel de resultado

```text
[ OK ] Wi-Fi conectado.
[ WARN ] wlan1 não encontrada; configure outro adaptador depois.
[ ERRO ] Serviço não respondeu.
```

A palavra entre colchetes permanece mesmo quando não há cor.

## Confirmação crítica

```text
+------------------ CRÍTICO ------------------+
| O node será desligado.                       |
| Host: halfin                                  |
| Digite "halfin" para confirmar:              |
|                                                |
| [ESC] cancelar                                |
+------------------------------------------------+
```

A confirmação não usa o número da opção como confirmação.

## Opção indisponível

```text
[4] Bitcoin Core  [INDISPONÍVEL]
    Requer espaço e pré-requisitos ainda ausentes.
```

Não desaparece silenciosamente; explica o motivo.