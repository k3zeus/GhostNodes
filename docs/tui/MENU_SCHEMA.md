# Contrato de dados de menus TUI

> Formato lógico. A primeira implementação deve usar representação Bash sem parser externo.

## Menu

| Campo | Obrigatório | Regra |
| --- | --- | --- |
| `id` | sim | slug único e estável |
| `title` | sim | até 40 caracteres visíveis em compacto |
| `breadcrumb` | não | caminho apresentado no header |
| `layout` | sim | `auto`, `list`, `grid2` ou `grid3` |
| `options` | sim | 1 a 9 opções por página |
| `back` | não | destino ou comportamento padrão global |

## Opção

| Campo | Obrigatório | Regra |
| --- | --- | --- |
| `id` | sim | número `1` a `9`, único no menu |
| `title` | sim | texto conciso |
| `description` | sim | até duas linhas visuais |
| `icon` | não | deve possuir fallback ASCII |
| `tone` | sim | `identity`, `bitcoin`, `success`, `warning`, `danger`, `muted` |
| `risk` | sim | `normal`, `info`, `warning`, `danger`, `critical` |
| `state` | sim | `normal`, `disabled`, `running` |
| `action_id` | sim | identificador permitido pelo action gateway |
| `disabled_reason` | condicional | obrigatório quando `state=disabled` |
| `shortcut` | não | letra adicional declarada pelo menu |

## Exemplo lógico

```yaml
menu:
  id: main
  title: MENU PRINCIPAL
  layout: auto
  options:
    - id: 1
      title: Halfin
      description: Rede, serviços e manutenção
      icon: "[H]"
      tone: identity
      risk: normal
      state: normal
      action_id: open_halfin
    - id: 4
      title: Bitcoin Core
      description: Serviço Bitcoin compartilhado
      icon: "[B]"
      tone: bitcoin
      risk: normal
      state: normal
      action_id: open_bitcoin
    - id: 9
      title: Desligar node
      description: Encerra o sistema com confirmação
      icon: "[!]"
      tone: danger
      risk: critical
      state: normal
      action_id: shutdown_host
```

## Validação obrigatória

Antes de renderizar, o catálogo deve rejeitar:

- ids duplicados ou fora de `1..9`;
- `action_id` não registrado;
- risco, tom ou estado desconhecidos;
- item desabilitado sem motivo;
- ação crítica sem texto de confirmação;
- descrições que não possam ser exibidas no layout compacto.

## Regra de segurança

`action_id` é uma chave de tabela para funções Bash registradas pelo projeto. Não pode conter espaços, comandos, argumentos de shell, pipes, substituições ou texto executável.