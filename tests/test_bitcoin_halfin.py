import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = json.loads((ROOT / 'bitcoin/manifests/bitcoin-core-29.1.json').read_text())
PROFILE = json.loads((ROOT / 'bitcoin/profiles/halfin.json').read_text())
ENGINE = (ROOT / 'bitcoin/bitcoin-node.sh').read_text()
MENU = (ROOT / 'ghostnode').read_text(encoding='utf-8')

class HalfinBitcoinProfileTests(unittest.TestCase):
    def test_halfin_policy_is_fixed_to_core_29_1_pruned_at_five_gib(self):
        self.assertEqual(PROFILE['implementation'], 'core')
        self.assertEqual(MANIFEST['version'], '29.1')
        self.assertEqual(PROFILE['mode'], 'pruned')
        self.assertEqual(PROFILE['max_prune_gib'], 5)
        self.assertEqual(PROFILE['min_prune_gib'], 1)

    def test_each_supported_architecture_has_an_official_hashed_tarball(self):
        for arch, suffix in {'arm64': 'aarch64-linux-gnu.tar.gz', 'amd64': 'x86_64-linux-gnu.tar.gz'}.items():
            artifact = MANIFEST['artifacts'][arch]
            self.assertTrue(artifact['url'].startswith('https://bitcoincore.org/bin/bitcoin-core-29.1/'))
            self.assertTrue(artifact['filename'].endswith(suffix))
            self.assertRegex(artifact['sha256'], r'^[0-9a-f]{64}$')

    def test_engine_limits_prune_to_one_third_of_free_space_and_five_gib(self):
        self.assertIn('candidate=$((free / 3))', ENGINE)
        self.assertIn('MAX_PRUNE_GIB', ENGINE)
        self.assertIn('tar -xzf', ENGINE)
        self.assertIn('SHA256SUMS oficial diverge do manifesto fixado', ENGINE)
        self.assertIn('tar -tzf', ENGINE)
        self.assertIn('--verify-artifact', ENGINE)

    def test_halfin_menu_delegates_to_shared_root_engine(self):
        self.assertIn('BITCOIN_ENGINE="$GN_ROOT/bitcoin/bitcoin-node.sh"', MENU)
        self.assertIn('--profile halfin --install', MENU)
        self.assertIn('--profile halfin --plan', MENU)

if __name__ == '__main__':
    unittest.main()