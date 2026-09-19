import ast
import hashlib
import os
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASH = os.environ.get('OSINT_BASH', 'bash')
TOOLS = ['security_audit.sh', 'vulnerability_scan.sh', 'systemd_security_audit.sh', 'ssh_audit.sh', 'aide_critical.sh', 'gitleaks_repo.sh', 'exposure_report.sh']
SWISS_SHELL = ['install.sh', 'audit-all.sh', 'serve-reports.sh', '01-wireless-survey.sh', '02-passive-listen.sh', '03-discovery.sh', '04-deep-scan.sh', '05-service-checks.sh']


class OsintContract(unittest.TestCase):
    def test_tools_parse_and_stay_defensive(self):
        for name in TOOLS:
            path = ROOT / 'services/osint' / name
            self.assertTrue(path.is_file(), path)
            text = path.read_text()
            self.assertNotIn('curl | bash', text)
            self.assertNotIn(b'\r\n', path.read_bytes())
            self.assertEqual(subprocess.run([BASH, '-n'], input=text, text=True).returncode, 0)
        self.assertTrue((ROOT / 'services/osint/authorized-targets.example').is_file())
        self.assertIn('GN_SERVICE_OSINT_SECURITY_AUDIT=true', (ROOT / 'halfin/services/osint/manifest.env').read_text())

    def test_local_network_scanner_contract(self):
        scanner = ROOT / 'services/scripts/scan_network.sh'
        text = scanner.read_text()
        self.assertTrue(text.startswith('#!/usr/bin/env bash'))
        self.assertIn('if [ "${1:-}" = "--local" ]', text)
        self.assertIn('nmap -sn -T3 --max-retries 2 -oG -', text)
        self.assertIn('nmap -p- -T3 --max-retries 2', text)
        self.assertIn('declare -A seen_networks', text)
        self.assertNotIn(b'\r\n', scanner.read_bytes())
        self.assertEqual(subprocess.run([BASH, '-n', str(scanner)]).returncode, 0)
        ssh_audit = (ROOT / 'services/osint/ssh_audit.sh').read_text()
        self.assertIn('/usr/sbin/sshd', ssh_audit)
        self.assertIn('exec sudo --', ssh_audit)

    def test_swissknife_is_preserved_and_inactive(self):
        swiss = ROOT / 'services/osint/swissknife'
        expected = {'README.md', 'SPECS.md', 'install.sh', 'audit-all.sh', 'serve-reports.sh', '01-wireless-survey.sh', '02-passive-listen.sh', '03-discovery.sh', '04-deep-scan.sh', '05-service-checks.sh', '06-generate-report.py'}
        self.assertTrue(swiss.is_dir())
        self.assertTrue(expected.issubset({path.name for path in swiss.iterdir() if path.is_file()}))
        inventory = ROOT / 'services/osint/SWISSKNIFE.sha256'
        self.assertTrue(inventory.is_file())
        for line in inventory.read_text().splitlines():
            digest, relative = line.split('  ', 1)
            self.assertEqual(hashlib.sha256((ROOT / 'services/osint' / relative).read_bytes()).hexdigest(), digest)
        self.assertIn('GN_SERVICE_OSINT_SWISSKNIFE=false', (ROOT / 'halfin/services/osint/manifest.env').read_text())
        self.assertIn('services/01-', (swiss / 'audit-all.sh').read_text())
        self.assertFalse((swiss / 'services').exists())
        for name in SWISS_SHELL:
            self.assertEqual(subprocess.run([BASH, '-n', str(swiss / name)]).returncode, 0, name)
        ast.parse((swiss / '06-generate-report.py').read_text(encoding='utf-8'))

    def test_swissknife_isolated_harness_contract(self):
        harness = ROOT / 'tests/swissknife/run_isolated_contract.sh'
        text = harness.read_text()
        self.assertTrue(text.startswith('#!/usr/bin/env bash'))
        self.assertIn('RUN_ROOT=${RUN_ROOT:-"$HOME/logs/osint/swissknife/', text)
        self.assertIn('snapshot before', text)
        self.assertIn('snapshot after', text)
        self.assertIn('local name=$1', text)
        self.assertIn('local out="$RUN_ROOT/${name}.state"', text)
        self.assertIn('mocked-privileged-operations.log', text)
        self.assertIn('target=${1:-}', text)
        self.assertNotIn('python3 python3', text)
        self.assertNotIn(b'\r\n', harness.read_bytes())
        self.assertEqual(subprocess.run([BASH, '-n', str(harness)]).returncode, 0)


if __name__ == '__main__':
    unittest.main()