import os
from pathlib import Path
import sqlite3

from test_install_behavior import bash


def fixture_nmcli(tmp_path, output):
    command = tmp_path / 'nmcli'
    command.write_text('#!/bin/bash\ncat <<\'OUT\'\n' + output + '\nOUT\n')
    command.chmod(0o755)
    return {'PATH': str(tmp_path) + ':' + os.environ['PATH'],
            'GN_DB_DIR': str(tmp_path / 'db')}


def test_scan_preserves_punctuation_and_quoted_ssids(tmp_path):
    # Realistic multiline nmcli output includes colon padding, SSID punctuation.
    env = fixture_nmcli(tmp_path, """BSSID:                                  AA:BB:CC:DD:EE:FF
SSID:                                   Cafe: Joe's|WiFi
MODE:                                   Infra
CHAN:                                   6
SECURITY:                               WPA2
SIGNAL:                                 80""")
    result = bash('bash /work/halfin/tools/wifi_scan.sh', env)
    assert result.returncode == 0, result.stdout + result.stderr
    with sqlite3.connect(tmp_path / 'db/wifi_scan.db') as db:
        assert db.execute('SELECT ssid, channel FROM networks').fetchall() == [("Cafe: Joe's|WiFi", 6)]


def test_import_nm_preserves_equals_and_updates_existing_network(tmp_path):
    env = fixture_nmcli(tmp_path, 'BSSID: AA:BB:CC:DD:EE:FF\nSSID: Lab=One\nMODE: Infra\nCHAN: 6\nSECURITY: WPA2\nSIGNAL: 80')
    bash('bash /work/halfin/tools/wifi_scan.sh', env)
    profiles = tmp_path / 'profiles'
    profiles.mkdir()
    (profiles / 'wifi.nmconnection').write_text('[connection]\ntype=wifi\n[wifi]\nssid=Lab=One\nbssid=AA:BB:CC:DD:EE:FF\n[wifi-security]\nkey-mgmt=wpa-psk\npsk=test=pass123\n')
    result = bash('bash /work/halfin/tools/nm_import.sh "$PROFILES"', {**env, 'PROFILES': str(profiles)})
    assert result.returncode == 0, result.stdout + result.stderr
    with sqlite3.connect(tmp_path / 'db/wifi_scan.db') as db:
        assert db.execute('SELECT password FROM networks WHERE ssid=?', ('Lab=One',)).fetchone() == ('test=pass123',)


def test_empty_database_connection_opens_menu(tmp_path):
    env = fixture_nmcli(tmp_path, 'wlan1:wifi')
    result = bash('printf "0\\n" | bash /work/halfin/tools/wifi_connect.sh', env)
    assert result.returncode == 0, result.stdout + result.stderr
    assert 'Banco n' not in result.stdout
