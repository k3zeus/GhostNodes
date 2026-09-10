"""Connection state regressions; real SQLite with synthetic NetworkManager output."""
import importlib.util
import os
from pathlib import Path
import sqlite3
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('wifi', ROOT / 'halfin/tools/wifi_db.py')
wifi = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wifi)


class WifiStateTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        self.addCleanup(self.db.close)
        self.db.execute('CREATE TABLE networks (bssid TEXT, password TEXT)')
        self.db.execute('INSERT INTO networks VALUES (?,?)', ('AA:BB:CC:DD:EE:FF', 'old-fixture'))
        self.row = {'BSSID': 'AA:BB:CC:DD:EE:FF', 'SSID': "Cafe: Joe's|WiFi", 'SECURITY': 'WPA2'}

    def connect(self, *, fail=False, replies=None):
        def nmcli(*args):
            if 'status' in args:
                return 'wlan0:wifi\n'
            if fail:
                raise RuntimeError('synthetic connection failure')
            return 'connected'
        with patch.object(wifi, 'nmcli', side_effect=nmcli) as command, \
                patch.object(wifi, 'scan', return_value=[self.row]), \
                patch('builtins.input', side_effect=replies or ['1', '1', 'n', 's', 's', '0', '0']), \
                patch.object(wifi.getpass, 'getpass', return_value='new-fixture'), \
                patch('builtins.print'):
            wifi.connect(self.db)
        return command

    def test_failed_connection_preserves_saved_password(self):
        self.connect(fail=True)
        self.assertEqual(self.db.execute('SELECT password FROM networks').fetchone()[0], 'old-fixture')

    def test_successful_connection_saves_only_after_confirmation(self):
        command = self.connect()
        self.assertEqual(self.db.execute('SELECT password FROM networks').fetchone()[0], 'new-fixture')
        self.assertIn(('device', 'wifi', 'connect', self.row['BSSID'], 'ifname', 'wlan0',
                       'password', 'new-fixture'), [call.args for call in command.call_args_list])

    def test_back_at_save_prompt_does_not_connect_or_change_password(self):
        command = self.connect(replies=['1', '1', 'n', '0', '0', '0'])
        self.assertFalse(any('connect' in call.args for call in command.call_args_list))
        self.assertEqual(self.db.execute('SELECT password FROM networks').fetchone()[0], 'old-fixture')

    def test_quit_propagates_to_parent_tui(self):
        with patch.dict(wifi.os.environ, {'GN_TUI_CHILD': '1'}), \
                patch('builtins.input', return_value='q'):
            with self.assertRaises(SystemExit) as raised:
                wifi.answer('fixture')
            self.assertEqual(raised.exception.code, 200)

    def test_ap_cannot_be_used_as_station_or_scanned(self):
        with patch.object(wifi, 'ap_interface', return_value='wlan0'), \
                patch.object(wifi, 'nmcli') as command:
            with self.assertRaisesRegex(RuntimeError, 'AP'):
                wifi.scan(self.db, 'wlan0')
            command.assert_not_called()

    def test_connection_errors_report_the_real_cause(self):
        self.assertIn('permissao', wifi.connection_error_message('Not authorized to control networking'))
        self.assertIn('ao alcance', wifi.connection_error_message('The Wi-Fi network could not be found'))
        self.assertIn('WPA', wifi.connection_error_message('4-way handshake failed'))

    def test_nmcli_uses_validated_sudo_only_when_requested(self):
        completed = type('Result', (), {'returncode': 0, 'stdout': '', 'stderr': ''})()
        with patch.dict(os.environ, {'GN_WIFI_USE_SUDO': '1'}), \
                patch.object(wifi, 'is_root', return_value=False), \
                patch.object(wifi.subprocess, 'run', return_value=completed) as run:
            wifi.nmcli('device', 'status')
        self.assertEqual(run.call_args.args[0], ['sudo', '-n', 'nmcli', 'device', 'status'])

    def test_connected_wifi_is_configured_as_backup_uplink(self):
        with patch.object(wifi, 'nmcli', side_effect=['Vivo5091\n', '', '']) as command:
            wifi.configure_backup_uplink('wlan1')
        self.assertEqual(command.call_args_list[1].args,
                         ('connection', 'modify', 'Vivo5091', 'ipv4.never-default', 'no',
                          'ipv4.route-metric', '600', 'ipv6.never-default', 'yes'))


if __name__ == '__main__':
    unittest.main()
