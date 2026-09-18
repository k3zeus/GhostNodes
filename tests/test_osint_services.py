import subprocess,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
TOOLS=['security_audit.sh','vulnerability_scan.sh','systemd_security_audit.sh','ssh_audit.sh','aide_critical.sh','gitleaks_repo.sh','exposure_report.sh']
class OsintContract(unittest.TestCase):
 def test_tools_parse_and_stay_defensive(self):
  for n in TOOLS:
   p=ROOT/'services/osint'/n; self.assertTrue(p.is_file(),p)
   t=p.read_text(); self.assertNotIn('curl | bash',t); self.assertEqual(subprocess.run(['bash','-n'],input=t,text=True).returncode,0)
  self.assertTrue((ROOT/'services/osint/authorized-targets.example').is_file())
  self.assertIn('GN_SERVICE_OSINT_SECURITY_AUDIT=true',(ROOT/'halfin/services/osint/manifest.env').read_text())
if __name__=='__main__':unittest.main()
