"""AP failure regressions. No real networking changes in this suite."""
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('ap', ROOT / 'halfin/tools/ap_health.py')
ap = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ap)


class ApTests(unittest.TestCase):
    def test_radio_fallback_preserves_password_and_ssid(self):
        original = 'interface=wlan0\nbridge=br0\nssid=Halfin\nwpa_passphrase=fixtureOnly123\nhw_mode=a\nchannel=36\nieee80211ac=1\nvht_oper_chwidth=1\nht_capab=[MAX-AMSDU-7935]\n'
        result = ap.compatible_hostapd(original, 'wlan0', 'br0')
        self.assertIn('wpa_passphrase=fixtureOnly123\n', result)
        self.assertIn('ssid=Halfin\n', result)
        self.assertIn('hw_mode=g\n', result)
        self.assertIn('ctrl_interface=/run/hostapd\n', result)
        self.assertNotIn('ieee80211ac=', result)
        self.assertNotIn('ht_capab=', result)
        self.assertEqual(ap.compatible_hostapd(result, 'wlan0', 'br0'), result)

    def test_ifupdown_migration_preserves_wan_and_secondary_wifi(self):
        original = 'auto lo\niface lo inet loopback\nallow-hotplug end0\niface end0 inet dhcp\n    metric 20\nallow-hotplug wlan0\niface wlan0 inet manual\nauto br0\niface br0 inet static\n    address 10.21.21.1\n    bridge_ports wlan0\nallow-hotplug wlan1\niface wlan1 inet dhcp\n    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf\n'
        result = ap.remove_owned_interfaces(original, {'wlan0', 'br0'})
        self.assertIn('iface end0 inet dhcp\n    metric 20\n', result)
        self.assertIn('iface wlan1 inet dhcp\n    wpa-conf', result)
        self.assertNotIn('iface br0', result)
        self.assertNotIn('allow-hotplug wlan0', result)

    def test_credential_whitespace_is_not_changed(self):
        result = ap.compatible_hostapd('ssid= Halfin \nwpa_passphrase= fixtureOnly123 \n', 'wlan0', 'br0')
        self.assertIn('ssid= Halfin \n', result)
        self.assertIn('wpa_passphrase= fixtureOnly123 \n', result)

    def test_no_repair_on_healthy_ap_or_zero_clients(self):
        with patch.object(ap, 'diagnose', return_value={'issues': [], 'clients': 0}), \
                patch.object(ap, 'prepare') as prepare:
            self.assertEqual(ap.repair({}, automatic=True)['issues'], [])
            prepare.assert_not_called()

    def test_no_radio_restart_for_external_internet_failure(self):
        with patch.object(ap, 'diagnose', return_value={'issues': ['wan_offline'], 'clients': 1}), \
                patch.object(ap, 'prepare') as prepare:
            result = ap.repair({}, automatic=True)
            prepare.assert_not_called()
            self.assertEqual(result['issues'], ['wan_offline'])

    def test_config_rejects_ap_as_wan(self):
        with self.assertRaises(ValueError):
            ap.validate_config({'ap': 'end0', 'bridge': 'br0', 'address': '10.21.21.1/24', 'dns_service': 'dnsmasq'}, wan='end0')

    def test_missing_radio_does_not_restart_services(self):
        with patch.object(ap, 'diagnose', return_value={'issues': ['radio_missing'], 'clients': 0}), \
                patch.object(ap, 'prepare') as prepare:
            result = ap.repair({}, automatic=True)
            prepare.assert_not_called()
            self.assertIn('radio_missing', result['issues'])

    def test_manual_repair_does_not_consume_automatic_recovery_budget(self):
        with patch.object(ap, 'diagnose', side_effect=[{'issues': ['ap_not_ready']}, {'issues': []}]), \
                patch.object(ap, 'prepare'), patch.object(ap, 'validate_config'), \
                patch.object(ap, 'default_wan'), patch.object(ap, 'STATE'), \
                patch.object(ap, 'command'), patch.object(ap, 'atomic') as atomic:
            ap.repair({}, automatic=False)
            atomic.assert_not_called()

    def test_pihole_with_dhcp_is_preferred_over_competing_dnsmasq(self):
        with patch.object(ap, 'command') as command, patch.object(ap.shutil, 'which', return_value='/usr/bin/pihole-FTL'):
            command.return_value.stdout = 'true\n'
            self.assertEqual(ap.select_dns_service(), 'pihole-FTL')

    def test_dns_unit_waits_for_bridge_and_not_just_network_target(self):
        text = ap.dns_unit()
        self.assertIn('Requires=halfin-ap-prepare.service', text)
        self.assertIn('After=halfin-ap-prepare.service', text)

    def test_network_ownership_contract_keeps_wan_and_client_separate(self):
        interfaces = (ROOT / 'halfin/Files/network/interfaces').read_text()
        preinstall = (ROOT / 'halfin/pre_install.sh').read_text()
        legacy_wifi = (ROOT / 'halfin/wifi_connect_debian.sh').read_text()
        routing = (ROOT / 'halfin/routing.sh').read_text()
        self.assertIn('iface end0 inet dhcp', interfaces)
        self.assertNotIn('iface wlan1 inet dhcp', interfaces)
        self.assertIn('managed=false', preinstall)
        self.assertIn('interface-name:end0', preinstall)
        self.assertIn('nmcli device set "$CLIENT_IFACE" managed yes', preinstall)
        self.assertNotIn('systemctl restart networking', legacy_wifi)
        self.assertIn('/etc/network/if-up.d/iptables', routing)
        failover = (ROOT / 'halfin/tools/uplink_failover.sh').read_text()
        self.assertIn('table halfin-wlan1', failover)
        self.assertIn('curl --interface', failover)


if __name__ == '__main__':
    unittest.main()
