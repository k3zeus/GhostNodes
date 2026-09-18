import os
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'halfin/tools/end0_bootstrap.sh'
GIT_BASH = pathlib.Path(r'C:\Program Files\Git\bin\bash.exe')
BASH = str(GIT_BASH) if GIT_BASH.exists() else 'bash'


class End0BootstrapTests(unittest.TestCase):
    def run_guard(self, mode, interfaces=''):
        with tempfile.TemporaryDirectory() as temp:
            temp_path = pathlib.Path(temp)
            script = temp_path / 'end0_bootstrap.sh'
            script.write_bytes(SCRIPT.read_bytes())
            script.chmod(0o755)
            log = temp_path / 'ifup.log'
            marker = temp_path / 'route.marker'
            config = temp_path / 'interfaces'
            config.write_text(interfaces)
            ip = temp_path / 'ip'
            ifup = temp_path / 'ifup'
            logger = temp_path / 'logger'
            ip.write_text('''#!/bin/sh
case "$*" in
  *"link show dev end0"*) if [ "$MODE" = no_carrier ]; then echo "2: end0: <NO-CARRIER,BROADCAST>"; else echo "2: end0: <BROADCAST,LOWER_UP>"; fi; exit 0 ;;
  "link show end0") exit 0 ;;
  *"addr show dev end0"*) [ "$MODE" = ready ] || [ "$MODE" = static ] && echo "2: end0 inet 192.168.101.92/24"; exit 0 ;;
  *"route show default dev end0"*) { [ "$MODE" = ready ] || [ -f "$ROUTE_MARKER" ]; } && echo "default via 192.168.101.1 dev end0"; exit 0 ;;
  *"route replace default via 192.168.101.1 dev end0"*) : > "$ROUTE_MARKER"; exit 0 ;;
esac
exit 0
''')
            ifup.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$IFUP_LOG"\n')
            logger.write_text('#!/bin/sh\nexit 0\n')
            for command in (ip, ifup, logger):
                command.chmod(0o755)
            env = os.environ | {
                'MODE': mode, 'IP_BIN': str(ip), 'IFUP_BIN': str(ifup),
                'LOGGER_BIN': str(logger), 'IFUP_LOG': str(log),
                'ROUTE_MARKER': str(marker), 'INTERFACES_FILE': str(config),
            }
            # Git Bash on Windows may need several seconds to create temporary shell mocks.
            # The timeout guards a real hang without making this unit test timing-sensitive.
            result = subprocess.run([BASH, str(script)], env=env, text=True, capture_output=True, timeout=30)
            calls = log.read_text() if log.exists() else ''
            return result, calls

    def test_ready_uplink_does_not_reconfigure(self):
        result, calls = self.run_guard('ready')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, '')

    def test_no_carrier_is_a_valid_wifi_failover_state(self):
        result, calls = self.run_guard('no_carrier')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, '')
        self.assertIn('no carrier', result.stdout)
    def test_missing_uplink_requests_ifup_and_fails_closed(self):
        result, calls = self.run_guard('missing')
        self.assertEqual(result.returncode, 1)
        self.assertEqual(calls, '--force end0\n')

    def test_static_uplink_recreates_missing_default_route(self):
        result, calls = self.run_guard('static', '''iface end0 inet static
    address 192.168.101.92
    gateway 192.168.101.1
''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, '--force end0\n')
        self.assertIn('configured static gateway', result.stdout)

    def test_preinstall_pins_end0_as_the_primary_wired_uplink(self):
        preinstall = (ROOT / 'halfin' / 'pre_install.sh').read_text(encoding='utf-8')
        self.assertIn('PRIMARY_WAN_IFACE="${HALFIN_PRIMARY_WAN_IFACE:-end0}"', preinstall)
        self.assertIn('ip link show "$PRIMARY_WAN_IFACE"', preinstall)
        self.assertIn('HALFIN_WAN_IFACE="$PRIMARY_WAN_IFACE"', preinstall)
        self.assertIn('Environment=HALFIN_PRIMARY_UPLINK=${PRIMARY_WAN_IFACE}', preinstall)
    def test_preinstall_registers_boot_guard(self):
        preinstall = (ROOT / 'halfin' / 'pre_install.sh').read_text(encoding='utf-8')
        self.assertIn('halfin-end0-ensure.service', preinstall)
        self.assertIn('/usr/local/sbin/halfin-end0-ensure', preinstall)
        self.assertIn('RemainAfterExit=yes', preinstall)


if __name__ == '__main__':
    unittest.main()