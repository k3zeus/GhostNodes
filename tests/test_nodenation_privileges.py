import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
NODE = (ROOT / 'nodenation').read_text(encoding='utf-8')
PRE = (ROOT / 'halfin/pre_install.sh').read_text(encoding='utf-8')

class PrivilegeFlowTests(unittest.TestCase):
    def test_bootstrap_acquires_sudo_once_then_reexecutes_noninteractively(self):
        self.assertIn('sudo -v ||', NODE)
        self.assertIn('exec sudo -n env GN_BOOTSTRAPPED=1 bash "$0" "$@"', NODE)
        self.assertNotIn('Execute como root: ${BOLD}sudo bash nodenation', NODE)

    def test_every_halfin_stage_requires_and_inherits_root(self):
        self.assertIn('require_root', PRE.splitlines()[5])
        stages = ('etapa_usuario', 'etapa_sourcelist', 'etapa_remove_docker', 'etapa_hostname',
                  'etapa_update', 'etapa_ferramentas', 'etapa_alias_wifi', 'etapa_orange3',
                  'etapa_extras', 'etapa_dashboard', 'etapa_aliases', 'etapa_remove_legado', 'etapa_chown')
        for stage in stages:
            self.assertIn(stage, PRE)
        self.assertIn('bash "${_GN_SELF}/pre_install.sh" --step "$stage"', PRE)
        self.assertNotIn('sudo bash "${_GN_SELF}/pre_install.sh"', PRE)

    def test_nodenation_runs_halfin_installer_inside_the_elevated_process(self):
        self.assertIn('bash "$_GN_FOUND_SCRIPT" --step etapa_usuario', NODE)
        self.assertIn('bash "${GN_ROOT}/halfin/pre_install.sh"', NODE)
        self.assertNotIn('sudo bash "${GN_ROOT}/halfin/pre_install.sh"', NODE)

    def test_wifi_runtime_state_is_user_owned_and_separate_from_code(self):
        root_globals = (ROOT / 'var' / 'globals.env').read_text(encoding='utf-8')
        halfin_globals = (ROOT / 'halfin' / 'var' / 'globals.env').read_text(encoding='utf-8')
        for globals_env in (root_globals, halfin_globals):
            self.assertIn('GN_STATE_DIR="${GN_STATE_DIR:-${GN_USER_HOME}/.local/state/halfin}"', globals_env)
            self.assertIn('GN_DB_DIR="${GN_DB_DIR:-${GN_STATE_DIR}/wifi}"', globals_env)
            self.assertNotIn('GN_DB_DIR="${HALFIN_DIR}/var"', globals_env)
        self.assertIn('install -d -o "$GN_USER" -g "$GN_USER" -m 0700 "$WIFI_STATE_DIR"', PRE)
        self.assertIn('[ ! -e "$WIFI_STATE_DB" ]', PRE)
        self.assertIn('install -o "$GN_USER" -g "$GN_USER" -m 0600', PRE)

    def test_halfin_is_not_architecture_limited_in_the_launcher(self):
        registry = (ROOT / 'var' / 'auto.sh').read_text(encoding='utf-8')
        self.assertIn('"Debian/Ubuntu/Armbian generic base"', registry)
        self.assertIn('"any"', registry)
        self.assertIn('Halfin Base é compatível com ${hw_arch}', NODE)
if __name__ == '__main__':
    unittest.main()