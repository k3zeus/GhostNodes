#!/usr/bin/env python3
"""Contract tests for the shared-service catalog installers."""

from __future__ import annotations

import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SERVICES = {
    "docker": "github.com/docker/docs",
    "fail2ban": "github.com/fail2ban/fail2ban",
    "heimdall": "github.com/linuxserver/docker-heimdall",
    "hermes": "github.com/open-webui/open-webui",
    "netbird": "github.com/netbirdio/netbird",
    "nginx": "github.com/nginx/nginx",
    "pihole": "github.com/pi-hole/pi-hole",
    "portainer": "github.com/portainer/portainer",
    "vaultwarden": "github.com/dani-garcia/vaultwarden",
}

class SharedServiceInstallerTests(unittest.TestCase):
    def test_every_service_has_source_documentation(self) -> None:
        for service, official_source in SERVICES.items():
            with self.subTest(service=service):
                document = ROOT / "services" / service / f"{service}.md"
                self.assertTrue(document.is_file(), document)
                text = document.read_text(encoding="utf-8").lower()
                self.assertIn(official_source, text)
                self.assertIn("debian/ubuntu", text)
                self.assertIn("outras plataformas", text)

    def test_every_service_has_a_safe_debian_installer(self) -> None:
        for service in SERVICES:
            with self.subTest(service=service):
                installer = ROOT / "services" / service / f"{service}.sh"
                self.assertTrue(installer.is_file(), installer)
                text = installer.read_text(encoding="utf-8")
                self.assertTrue(text.startswith("#!/usr/bin/env bash"))
                self.assertIn("set -euo pipefail", text)
                self.assertIn("--dry-run", text)
                self.assertNotRegex(text, r"curl[^\n]*\|[^\n]*(bash|sh)")
                parsed = subprocess.run(["bash", "-n"], input=text, text=True, capture_output=True, check=False)
                self.assertEqual(parsed.returncode, 0, parsed.stderr)
                dry_run = subprocess.run(["bash", str(installer), "--dry-run"], text=True, capture_output=True, check=False)
                self.assertEqual(dry_run.returncode, 0, dry_run.stderr)
                self.assertIn("DRY RUN", dry_run.stdout)

if __name__ == "__main__":
    unittest.main()
