import os
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
TOOL = ROOT / 'halfin/tools/standard_hardware.sh'
BASH = r'C:\Program Files\Git\bin\bash.exe' if pathlib.Path(r'C:\Program Files\Git\bin\bash.exe').exists() else 'bash'


def run(code, env):
    return subprocess.run([BASH, '-c', f'source "{TOOL}"\n' + code], text=True,
                          capture_output=True, env={**os.environ, **env}, timeout=20)


class StandardHardwareTests(unittest.TestCase):
    def fixture_radios(self, temp, names):
        sys = pathlib.Path(temp) / 'net'
        for index, name in enumerate(names):
            node = sys / name
            (node / 'wireless').mkdir(parents=True)
            (node / 'address').write_text(f'02:00:00:00:00:{index + 1:02x}\n')
        return sys

    def test_orangepi_apt_is_exclusive_to_full_baseline(self):
        with tempfile.TemporaryDirectory() as temp:
            temp = pathlib.Path(temp)
            apt = temp / 'apt'; apt.mkdir(); (apt / 'sources.list.d').mkdir()
            source = apt / 'sources.list'; source.write_text('deb http://old.invalid bookworm main\n')
            env = {'HALFIN_APT_ROOT': str(apt), 'HALFIN_APT_BACKUP_ROOT': str(temp/'backup'),
                   'HALFIN_APT_UPDATE_CMD': 'true', 'GN_HW_MODEL': 'OrangePi Zero3',
                   'GN_HW_ARCH': 'arm64', 'GN_HW_OS': 'Debian GNU/Linux 12 (bookworm)'}
            self.assertEqual(run('halfin_apply_orangepi_apt', env).returncode, 0)
            self.assertIn('repo.huaweicloud.com', source.read_text())
            source.write_text('keep-me\n')
            env['GN_HW_MODEL'] = 'Raspberry Pi 4'
            self.assertEqual(run('halfin_apply_orangepi_apt', env).returncode, 0)
            self.assertEqual(source.read_text(), 'keep-me\n')

    def test_user_migration_requires_valid_pleb_home_and_sudo_group(self):
        source = TOOL.read_text(encoding='utf-8')
        self.assertIn("stat -c '%U:%G' /home/pleb", source)
        self.assertIn('getent group sudo | awk -F:', source)
    def test_zero_radios_do_not_create_udev_rule(self):
        with tempfile.TemporaryDirectory() as temp:
            temp = pathlib.Path(temp); sys = temp / 'net'; sys.mkdir(); udev = temp / 'udev'
            result = run('halfin_configure_wifi_roles', {'HALFIN_SYS_CLASS_NET': str(sys), 'HALFIN_UDEV_DIR': str(udev), 'GN_ROOT': str(temp)})
            self.assertEqual(result.returncode, 0)
            self.assertFalse((udev / '70-halfin-wifi-roles.rules').exists())
            self.assertIn('nenhum radio encontrado', result.stderr + result.stdout)

    def test_one_radio_becomes_wlan0_and_reports_missing_wlan1(self):
        with tempfile.TemporaryDirectory() as temp:
            temp = pathlib.Path(temp); sys = self.fixture_radios(temp, ['wlxabc']); udev = temp / 'udev'
            result = run('halfin_configure_wifi_roles', {'HALFIN_SYS_CLASS_NET': str(sys), 'HALFIN_UDEV_DIR': str(udev), 'GN_ROOT': str(temp)})
            rule = (udev / '70-halfin-wifi-roles.rules').read_text()
            self.assertEqual(result.returncode, 0)
            self.assertIn('NAME="wlan0"', rule); self.assertNotIn('NAME="wlan1"', rule)
            self.assertIn('wlan1 nao foi encontrada', result.stderr + result.stdout)

    def test_two_radios_receive_stable_mac_roles(self):
        with tempfile.TemporaryDirectory() as temp:
            temp = pathlib.Path(temp); sys = self.fixture_radios(temp, ['wlan1', 'wlxabc']); udev = temp / 'udev'
            result = run('halfin_configure_wifi_roles', {'HALFIN_SYS_CLASS_NET': str(sys), 'HALFIN_UDEV_DIR': str(udev), 'GN_ROOT': str(temp)})
            rule = (udev / '70-halfin-wifi-roles.rules').read_text()
            self.assertEqual(result.returncode, 0)
            self.assertIn('NAME="wlan0"', rule); self.assertIn('NAME="wlan1"', rule)

    def test_user_migration_is_guarded_by_baseline_and_safety_checks(self):
        source = TOOL.read_text(encoding='utf-8')
        self.assertIn('halfin_is_orangepi_zero3_baseline || return 0', source)
        self.assertIn('pgrep -u "$legacy"', source)
        self.assertIn('tar --one-file-system', source)
        self.assertIn('userdel -r "$legacy"', source)

if __name__ == '__main__':
    unittest.main()
