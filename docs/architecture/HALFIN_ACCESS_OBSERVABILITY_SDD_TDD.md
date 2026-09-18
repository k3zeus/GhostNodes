# Halfin: acesso seguro e observabilidade defensiva

## Decisão aprovada

- SSH mantém autenticação por senha para administração via Tailscale ou NetBird.
- `root` nunca pode entrar por SSH; chaves públicas continuam aceitas.
- Após o primeiro login de `pleb`, o shell recomenda cadastrar uma chave, sem remover a senha.
- Fail2ban é obrigatório na pré-instalação. UFW permanece desabilitado; a topologia Halfin usa a política de rede já existente.
- O inventário é exclusivamente local: portas, interfaces, serviços, SSH efetivo, Fail2ban, UFW, unidades falhas e atualizações. Não consulta Shodan, Censys ou terceiros.

## Fluxo

`etapa_acesso_seguro` valida e recarrega SSH, desabilita UFW se presente e aplica Fail2ban. `etapa_inventario_seguranca` produz `/var/lib/ghostnodes/security/latest.json` com permissões 0600 e agenda atualização diária.

## TDD

- Contratos: `python -B -m unittest tests.test_halfin_access_observability -v`.
- Sintaxe: `bash -n halfin/tools/access_hardening.sh halfin/tools/security_inventory.sh halfin/pre_install.sh`.
- Equipamento: validar SSH por senha como `pleb`, recusar root, `fail2ban-client status sshd`, `ufw status`, e o JSON local.
