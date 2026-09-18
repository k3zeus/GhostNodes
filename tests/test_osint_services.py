import os,subprocess,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BASH=os.environ.get('OSINT_BASH','bash')
TOOLS=['security_audit.sh','vulnerability_scan.sh','systemd_security_audit.sh','ssh_audit.sh','aide_critical.sh','gitleaks_repo.sh','exposure_report.sh']
class OsintContract(unittest.TestCase):
 def test_tools_parse_and_stay_defensive(self):
  for n in TOOLS:
   p=ROOT/'services/osint'/n; self.assertTrue(p.is_file(),p)
   t=p.read_text(); self.assertNotIn('curl | bash',t); self.assertNotIn(b'\r\n',p.read_bytes()); self.assertEqual(subprocess.run([BASH,'-n'],input=t,text=True).returncode,0)
  self.assertTrue((ROOT/'services/osint/authorized-targets.example').is_file())
  self.assertIn('GN_SERVICE_OSINT_SECURITY_AUDIT=true',(ROOT/'halfin/services/osint/manifest.env').read_text())
 def test_local_network_scanner_contract(self):
  scanner=(ROOT/'services/scripts/scan_network.sh').read_text()
  self.assertTrue(scanner.startswith('#!/usr/bin/env bash'))
  self.assertIn('if [ "${1:-}" = "--local" ]', scanner)
  self.assertIn('nmap -sn -T3 --max-retries 2 -oG -',scanner)
  self.assertIn('nmap -p- -T3 --max-retries 2',scanner)
  self.assertIn('declare -A seen_networks',scanner)
  ssh_audit=(ROOT/'services/osint/ssh_audit.sh').read_text()
  self.assertIn('/usr/sbin/sshd',ssh_audit)
  self.assertIn('exec sudo --',ssh_audit)
  p=ROOT/'services/scripts/scan_network.sh'
  self.assertNotIn(b'\r\n',p.read_bytes())
  self.assertEqual(subprocess.run([BASH,'-n',str(p)]).returncode,0)
if __name__=='__main__':unittest.main()