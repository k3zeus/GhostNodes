# Contrato de serviços compartilhados

## Limite de responsabilidade

`services/` armazena serviços reutilizáveis e subprojetos compartilhados. As pastas dos Projetos Raiz (`halfin/`, `satoshi/`, `nick/`, `adam/`, `fiatjaf/`, `nash/` e `craig/`) continuam sendo donas da experiência de instalação e das escolhas do seu Node.

## Resolução por perfil

Uma Raiz declara um serviço por meio de um perfil em:

```text
<raiz>/services/<serviço>/manifest.env
```

O perfil referencia a implementação canônica em:

```text
services/<serviço>/
```

A implementação nunca é copiada para a Raiz. Na execução, o instalador carrega o serviço primeiro e aplica apenas os arquivos declarados no perfil da Raiz.

## Onde cada tipo de arquivo fica

| Tipo | Local | Versionado |
|---|---|---|
| código, instalador, modelos e padrões comuns | `services/<serviço>/` | sim |
| perfil, escolhas e modelos exclusivos de uma Raiz | `<raiz>/services/<serviço>/` | sim |
| configuração comum que possa ser compartilhada com segurança | `services/<serviço>/defaults/` | sim |
| dados persistentes, bancos, chaves, senhas e estado do Node instalado | fora do checkout, no caminho operacional definido pelo serviço | não |

## Regras obrigatórias

1. O manifesto declara a origem canônica do serviço e a versão ou perfil escolhido pela Raiz.
2. O perfil de uma Raiz só complementa o serviço; ele não altera o comportamento de outra Raiz.
3. Nenhum serviço pode pressupor que todas as Raízes o instalem.
4. Um bootstrap de monorepo obtém `services/` junto com as Raízes; ele instala somente os serviços declarados para a Raiz selecionada.
5. A migração de código existente exige adaptador de compatibilidade e TDD antes de remover qualquer cópia legada.

## Estado atual

A taxonomia foi criada, mas os instaladores existentes ainda usam suas localizações atuais. Portanto, a convenção já é a fonte de arquitetura; a ativação por manifestos ocorrerá serviço a serviço, começando por aqueles usados pelo Halfin, sem regressão do fluxo atual.
