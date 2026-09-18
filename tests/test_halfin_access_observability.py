#!/usr/bin/env python3
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class HalfinAccessObservabilityTests(unittest.TestCase):
    def test_access_hardening_contract(self):
        tool = ROOT / 'halfin/tools/access_hardening.sh'
        self.assertTrue(tool.is_file())
        text = tool.read_text(encoding='utf-8')
        for required in ('PermitRootLogin no', 'PasswordAuthentication yes', 'PubkeyAuthentication yes', 'ufw --force disable', 'fail2ban.sh', 'sshd -t'):
            self.assertIn(required, text)
        self.assertNotIn('PasswordAuthentication no', text)

    def test_local_inventory_contract(self):
        tool = ROOT / 'halfin/tools/security_inventory.sh'
        self.assertTrue(tool.is_file())
        text = tool.read_text(encoding='utf-8')
        for required in ('/var/lib/ghostnodes/security', 'ss -lntup', 'systemctl --failed', 'fail2ban-client', 'ufw status', 'inventory.timer'):
            self.assertIn(required, text)
        self.assertNotIn('shodan', text.lower())
        self.assertNotIn('censys', text.lower())

    def test_preinstall_runs_hardening_and_inventory(self):
        text = (ROOT / 'halfin/pre_install.sh').read_text(encoding='utf-8')
        self.assertIn('etapa_acesso_seguro', text)
        self.assertIn('etapa_inventario_seguranca', text)
        self.assertLess(text.index('etapa_acesso_seguro'), text.index('etapa_extras'))

if __name__ == '__main__':
    unittest.main()
