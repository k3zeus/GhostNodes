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

if __name__ == '__main__':
    unittest.main()