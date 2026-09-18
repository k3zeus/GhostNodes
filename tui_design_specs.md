O ideal é criar um documento de especificação visual e de interação, algo como `TUI_DESIGN_SPEC.md`, que funcione como contrato técnico para todos os menus futuros do Ghost Nodes.

Ele deve definir não só “como fica bonito”, mas também comportamento, navegação, cores, estados, espaçamentos, atalhos, componentes reutilizáveis e regras para menus de risco como reboot/shutdown.

A estrutura que eu recomendo é esta:

```md
# Ghost Nodes TUI Design Specification

Versão: 1.0
Status: Ativo
Projeto: Ghost Nodes
Interface: TUI
Objetivo: Padronizar todos os menus, telas e componentes interativos do sistema.

---

# 1. Objetivo

Este documento define o padrão visual, estrutural e comportamental da interface TUI do Ghost Nodes.

Todos os menus novos devem seguir estas regras para manter:

- identidade visual consistente;
- navegação previsível;
- compatibilidade com terminal;
- boa leitura em SSH;
- controle por teclado;
- suporte a seleção por número;
- diferenciação clara entre estados normal, selecionado, atenção e perigo.

---

# 2. Estrutura geral da tela

A tela principal deve ser dividida conceitualmente em:

1. Banner superior
2. Status global
3. Identificação do Node
4. Título da seção
5. Área principal de opções
6. Barra de ajuda
7. Ação de saída
8. Prompt/status inferior

Estrutura:

┌──────────────────────────────────────────────┐
│                  BANNER                      │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│ STATUS / DATA / TEMPERATURA / REDE           │
└──────────────────────────────────────────────┘

Node: halfin       Up: 1d 19h       User: pleb

────────────── [ MENU PRINCIPAL ] ──────────────

┌──────────┐ ┌──────────┐ ┌──────────┐
│   [1]    │ │   [2]    │ │   [3]    │
│ Sistema  │ │   Rede   │ │ Docker   │
└──────────┘ └──────────┘ └──────────┘

┌──────────┐ ┌──────────┐ ┌──────────┐
│   [4]    │ │   [5]    │ │   [6]    │
│ Satoshi  │ │ Reiniciar│ │ Desligar │
└──────────┘ └──────────┘ └──────────┘

Use ↑ ↓ ← → para navegar ou digite o número.

┌──────────────────────────────────────────────┐
│ [q] Sair do sistema                          │
└──────────────────────────────────────────────┘

Selecione uma opção:
```

## 3. Layout padrão dos menus

Para menus principais, usar preferencialmente grade de 3 colunas.

Exemplo:

```text
[1] [2] [3]
[4] [5] [6]
```

Regras:

* máximo recomendado: 6 opções por página;
* ideal: 3 colunas;
* no máximo 2 linhas antes de criar uma segunda página;
* opções relacionadas devem ficar próximas;
* ações destrutivas devem ficar nas últimas posições;
* `[q] Sair` nunca entra na grade principal.

Para submenus pequenos, pode ser usada grade 2×2 ou lista vertical.

---

# 4. Estrutura de um card

Cada opção deve ser apresentada como um card.

Modelo conceitual:

```text
┌─────────────────────────┐
│          ICON           │
│          [1]            │
│        Sistema          │
│ Verificação, serviços   │
│ e atualizações          │
└─────────────────────────┘
```

Cada card possui:

* ícone;
* número;
* título;
* descrição curta;
* borda;
* estado visual.

Nenhum card deve ter mais de 2 linhas de descrição.

---

# 5. Estados visuais

Todo card deve possuir quatro estados possíveis:

## 5.1 Normal

Estado padrão.

Características:

* cor reduzida;
* brilho baixo;
* borda discreta;
* texto secundário em cinza;
* não deve competir visualmente com o item selecionado.

Exemplo:

```text
cor principal: azul escuro / cyan reduzido
borda: cinza azulado
descrição: cinza
```

## 5.2 Selecionado

O item sob navegação deve receber destaque forte.

Características:

* cor viva;
* borda brilhante;
* título destacado;
* ícone em brilho alto;
* pode usar fundo discretamente colorido;
* nunca depender apenas da cor.

Exemplo:

```text
┏━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃          ⚙              ┃
┃          [1]            ┃
┃        Sistema          ┃
┃ Verificação e serviços  ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

Também pode ser utilizado:

```text
▶
```

ou:

```text
> Sistema
```

para acessibilidade em terminais simples.

## 5.3 Atenção

Usado para operações que merecem cautela.

Exemplos:

* reiniciar serviço;
* reiniciar node;
* atualizar pacotes críticos.

Cor recomendada:

```text
amarelo / âmbar
```

## 5.4 Perigo

Usado para:

* desligamento;
* remoção;
* reset;
* formatação;
* operações irreversíveis.

Cor recomendada:

```text
vermelho / tomate
```

Essas opções exigem confirmação.

---

# 6. Paleta oficial

A TUI deve trabalhar com cores discretas quando inativas e mais vivas quando selecionadas.

Paleta recomendada:

| Uso              | Cor            |
| ---------------- | -------------- |
| Cor principal    | Cyan           |
| Item selecionado | Cyan brilhante |
| Rede             | Azul           |
| Docker           | Azul           |
| Bitcoin          | Laranja        |
| Sucesso          | Verde          |
| Atenção          | Amarelo        |
| Erro             | Vermelho       |
| Perigo           | Tomato         |
| Texto normal     | Branco         |
| Texto secundário | Cinza          |
| Fundo            | Preto          |

Exemplo ANSI aproximado:

```text
CYAN_DIM
CYAN_BRIGHT
BLUE_DIM
BLUE_BRIGHT
GREEN_DIM
GREEN_BRIGHT
YELLOW
ORANGE
RED
TOMATO
WHITE
GRAY
```

---

# 7. Regra de intensidade

Princípio obrigatório:

> Opção não selecionada = cor reduzida.
> Opção selecionada = cor viva.

Exemplo:

Normal:

```text
[2] Conexões de Rede
```

Selecionado:

```text
╔══════════════════════════╗
║        🌐                ║
║        [2]               ║
║   Conexões de Rede       ║
╚══════════════════════════╝
```

O contraste deve deixar evidente onde está o cursor.

---

# 8. Navegação

Todos os menus devem aceitar simultaneamente:

```text
↑
↓
←
→
ENTER
```

e seleção direta:

```text
1
2
3
4
5
6
```

Também:

```text
q
```

para sair ou voltar.

Regras:

* `ENTER` executa item selecionado;
* número executa diretamente;
* setas movem seleção;
* `q` sai ou retorna;
* `ESC` pode funcionar como voltar;
* seleção deve circular opcionalmente.

Exemplo:

```text
1 2 3
4 5 6
```

Pressionar `→` em `[3]` pode levar para `[1]` ou permanecer em `[3]`, dependendo da implementação escolhida.

Recomendação do Ghost Nodes:

```text
navegação circular = habilitada
```

---

# 9. Barra de ajuda

Todos os menus devem mostrar uma barra de ajuda curta.

Exemplo:

```text
ⓘ Use ↑ ↓ ← → para navegar | ENTER selecionar | número acesso direto
```

Evitar instruções longas.

---

# 10. Sair

A opção de saída deve permanecer separada da grade.

Formato:

```text
┌─────────────────────────────────────────────┐
│ [q]            Sair do sistema              │
└─────────────────────────────────────────────┘
```

Padrão visual:

```text
[q] = vermelho tomate
texto = branco
borda = cinza discreto ou vermelho escuro
```

Não deve competir visualmente com `Desligar Node`.

---

# 11. Reiniciar Node

Deve utilizar verde ou amarelo, dependendo do contexto.

Exemplo:

```text
[5]
↻
Reiniciar o Node
Reinicia o sistema
com confirmação
```

Antes de executar:

```text
Tem certeza que deseja reiniciar o Node?

[y] Sim
[n] Não
```

Nunca executar reboot diretamente ao pressionar o card sem confirmação.

---

# 12. Desligar Node

Deve ser visualmente identificado como destrutivo.

Exemplo:

```text
[6]
⏻
Desligar o Node
Desliga o sistema
com confirmação
```

Estado normal:

```text
vermelho escuro
```

Estado selecionado:

```text
vermelho tomate brilhante
```

Confirmação obrigatória:

```text
ATENÇÃO

O Node será desligado.

Hostname: halfin
Usuário: pleb

Deseja continuar?

[y] Confirmar desligamento
[n] Cancelar
```

---

# 13. Títulos

Padronização:

```text
──────────── [ MENU PRINCIPAL ] ────────────
```

Submenu:

```text
──────────── [ SISTEMA ] ──────────────────
```

Outros exemplos:

```text
[ REDE ]
[ DOCKER ]
[ SATOSHI NODE ]
[ DISCOS ]
[ SERVIÇOS ]
[ SEGURANÇA ]
[ BACKUP ]
```

---

# 14. Hierarquia visual

Prioridade:

1. Item selecionado
2. Título do menu
3. Nome da opção
4. Número da opção
5. Ícone
6. Descrição
7. Texto auxiliar

Nunca deixar todos os elementos com o mesmo brilho.

---

# 15. Ícones

Ícones devem ser utilizados apenas quando o terminal suportar UTF-8.

Exemplos:

Sistema:

⚙

Rede:

🌐

Docker:

▣

Bitcoin:

₿

Reiniciar:

↻

Desligar:

⏻

Informação:

ⓘ

Erro:

!

Caso Unicode não esteja disponível:

```text
[*]
[N]
[D]
[B]
[R]
[P]
[i]
[!]
```

---

# 16. Compatibilidade

A interface deve funcionar em:

* console local;
* SSH;
* Linux Mint;
* Ubuntu Server;
* Debian;
* terminal 80×24;
* terminal 120×30 ou superior.

A TUI não deve depender exclusivamente de:

* mouse;
* Unicode;
* 256 cores;
* terminal gráfico.

Deve existir fallback.

---

# 17. Resolução mínima

Recomendado:

```text
mínimo absoluto:
80x24

recomendado:
100x30

ideal:
120x35
```

Se a largura for insuficiente:

```text
3 colunas
↓
2 colunas
↓
1 coluna
```

---

# 18. Componentes reutilizáveis

A implementação deve tratar os seguintes elementos como componentes:

```text
draw_header()
draw_status()
draw_node_info()
draw_section_title()
draw_card()
draw_selected_card()
draw_help_bar()
draw_exit_button()
draw_confirmation()
draw_footer()
```

Nunca duplicar código visual em cada submenu.

---

# 19. Definição estrutural de uma opção

Internamente, cada item do menu deve seguir estrutura semelhante:

```bash
id="1"
title="Sistema"
description="Verificação, serviços e atualizações"
icon="⚙"
color="cyan"
action="system_menu"
risk="normal"
```

Exemplo Docker:

```bash
id="3"
title="Docker"
description="Verificação, instalação e containers"
icon="▣"
color="blue"
action="docker_menu"
risk="normal"
```

Exemplo shutdown:

```bash
id="6"
title="Desligar o Node"
description="Desliga o sistema com confirmação"
icon="⏻"
color="tomato"
action="shutdown_node"
risk="critical"
```

---

# 20. Tipos de risco

Definir:

```text
normal
info
warning
danger
critical
```

Comportamento:

```text
normal
→ executa

warning
→ confirmação simples

danger
→ confirmação explícita

critical
→ confirmação + hostname
```

---

# 21. Submenus

Submenus devem seguir exatamente a mesma identidade visual.

Exemplo:

```text
────────────── [ SISTEMA ] ──────────────

┌────────────┐ ┌────────────┐ ┌────────────┐
│    [1]     │ │    [2]     │ │    [3]     │
│  Serviços  │ │ Atualizar  │ │   Logs     │
└────────────┘ └────────────┘ └────────────┘

┌────────────┐ ┌────────────┐
│    [4]     │ │    [5]     │
│ Hardware   │ │ Informação │
└────────────┘ └────────────┘

[b] Voltar
```

---

# 22. Convenção de teclas

Padrão global:

| Tecla | Função        |
| ----- | ------------- |
| ↑     | Cima          |
| ↓     | Baixo         |
| ←     | Esquerda      |
| →     | Direita       |
| ENTER | Selecionar    |
| 1-9   | Acesso direto |
| q     | Sair          |
| b     | Voltar        |
| ESC   | Voltar        |
| r     | Atualizar     |
| h     | Ajuda         |

Evitar redefinir essas teclas entre menus.

---

# 23. Estados de execução

Quando uma ação estiver rodando:

```text
⟳ Verificando serviços...
```

Sucesso:

```text
✓ Operação concluída
```

Falha:

```text
✗ Falha na operação
```

Aviso:

```text
! Atenção
```

Não bloquear silenciosamente a interface.

---

# 24. Padrão de feedback

Resultado positivo:

```text
[ OK ] Docker está ativo.
```

Aviso:

```text
[ WARN ] Existem atualizações disponíveis.
```

Erro:

```text
[ ERROR ] Não foi possível acessar o serviço.
```

---

# 25. Regra principal do Ghost Nodes

Todo menu futuro deve parecer parte do mesmo sistema.

Não criar telas que tenham:

* outra paleta;
* outro padrão de borda;
* outra lógica de navegação;
* atalhos diferentes;
* cards com tamanho arbitrário;
* excesso de cores;
* descrições longas;
* ações destrutivas misturadas às comuns.

---

# 26. Template oficial

Todo novo menu deve partir deste modelo:

Menu:
título
opções[]
ação voltar
barra ajuda

Option:
id
icon
title
description
color
action
risk

Renderer:
normal
selected
disabled
warning
danger

Input:
arrows
enter
numbers
q/b/esc

---

# 27. Filosofia visual

Ghost Nodes deve transmitir:

* terminal técnico;
* identidade Bitcoin/cyberpunk discreta;
* baixo ruído visual;
* leitura rápida;
* operação segura;
* aparência consistente;
* sensação de appliance profissional.

O destaque visual deve sempre representar estado ou ação.

Nunca usar cor apenas como decoração.

````

Eu acrescentaria ainda dois documentos ao projeto, porque isso evita que o `.md` principal vire uma mistura de design com código:

```text
docs/
├── TUI_DESIGN_SPEC.md
├── TUI_COMPONENTS.md
└── TUI_MENU_SCHEMA.md
````

O `TUI_DESIGN_SPEC.md` seria o documento acima. O `TUI_COMPONENTS.md` especificaria tecnicamente `Card`, `Header`, `StatusBar`, `ConfirmationDialog`, etc. Já o `TUI_MENU_SCHEMA.md` definiria como cadastrar menus e opções, por exemplo:

```yaml
menu:
  id: main
  title: MENU PRINCIPAL
  columns: 3

  options:
    - id: 1
      title: Sistema
      icon: "⚙"
      description: "Verificação, serviços e atualizações"
      color: cyan
      risk: normal
      action: menu_system

    - id: 2
      title: Conexões de Rede
      icon: "🌐"
      description: "Status Wi-Fi, conexões e diagnóstico"
      color: blue
      risk: normal
      action: menu_network

    - id: 3
      title: Docker
      icon: "▣"
      description: "Verificação, instalação e containers"
      color: blue
      risk: normal
      action: menu_docker

    - id: 4
      title: Satoshi Node
      icon: "₿"
      description: "Monitoramento e controle do Bitcoin Core"
      color: orange
      risk: normal
      action: menu_satoshi

    - id: 5
      title: Reiniciar o Node
      icon: "↻"
      description: "Reinicia o sistema com confirmação"
      color: green
      risk: warning
      action: reboot_node

    - id: 6
      title: Desligar o Node
      icon: "⏻"
      description: "Desliga o sistema com confirmação"
      color: tomato
      risk: critical
      action: shutdown_node

  exit:
    key: q
    label: Sair do sistema
    key_color: tomato
    text_color: white
```

Essa última parte é especialmente importante: em vez de desenhar cada menu manualmente no Bash, Python ou outra linguagem, podemos chegar a uma arquitetura em que **o menu é apenas dados e existe um único renderer TUI**.

Assim:

```text
menu.yaml
       │
       ▼
┌──────────────────┐
│   Menu Engine    │
│                  │
│ lê opções        │
│ controla cursor  │
│ recebe teclas    │
│ executa ações    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   TUI Renderer   │
│                  │
│ header           │
│ cards            │
│ colors           │
│ selected state   │
│ help             │
│ footer           │
└──────────────────┘
```

Isso resolveria o problema dos “próximos menus”: para criar **Discos**, **Backup**, **Segurança**, **Rede**, **Bitcoin Core**, **Docker**, etc., você não redesenharia a TUI. Apenas declararia as opções e o motor produziria sempre o mesmo padrão visual.

Para o Ghost Nodes, eu considero essa abordagem melhor do que começar criando cada tela separadamente, porque já transforma a interface que desenhamos em um **Design System de TUI**, e não apenas em um menu bonito.
