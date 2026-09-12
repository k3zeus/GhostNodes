import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'halfin/tools/configure_wan_dhcp.sh'
GIT_BASH = pathlib.Path(r'C:\Program Files\Git\bin\bash.exe')
BASH = str(GIT_BASH) if GIT_BASH.exists() else 'bash'

class WanDhcpTests(unittest.TestCase):
    def test_migrates_end0_to_owned_dhcp_fragment(self):
        with tempfile.TemporaryDirectory() as temp:
            path = pathlib.Path(temp)
            root = path / 'interfaces'
            directory = path / 'interfaces.d'
            directory.mkdir()
            root.write_text('auto lo end0\niface lo inet loopback\niface end0 inet static\n address 192.168.1.2\n gateway 192.168.1.1\nallow-hotplug wlan1\niface wlan1 inet dhcp\n')
            (directory / 'legacy').write_text('allow-hotplug end0\niface end0 inet static\n address 10.0.0.2\n')
            result = subprocess.run([BASH, str(SCRIPT)], env={
                'PATH': __import__('os').environ['PATH'], 'HALFIN_WAN_IFACE': 'end0',
                'HALFIN_INTERFACES_FILE': str(root), 'HALFIN_INTERFACES_DIR': str(directory),
            }, text=True, capture_output=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn('iface end0', root.read_text())
            self.assertIn('iface lo inet loopback', root.read_text())
            self.assertIn('iface wlan1 inet dhcp', root.read_text())
            self.assertNotIn('iface end0', (directory / 'legacy').read_text())
            wan = (directory / 'halfin-wan').read_text()
            self.assertIn('allow-hotplug end0', wan)
            self.assertIn('iface end0 inet dhcp', wan)
            self.assertIn('metric 100', wan)

if __name__ == '__main__':
    unittest.main()