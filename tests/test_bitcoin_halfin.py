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

    def test_microsd_is_warned_but_remains_an_explicitly_optional_install(self):
        self.assertIn('uses_microsd()', ENGINE)
        self.assertIn('/dev/mmcblk*', ENGINE)
        self.assertIn('Digite MICROSD', ENGINE)
        self.assertIn('MICROSD', ENGINE)
        self.assertNotIn('RECUSAR — MicroSD', ENGINE)
        self.assertIn('disablewallet=1', ENGINE)
        self.assertIn('persistmempool=0', ENGINE)

    def test_halfin_storage_stage_is_registered_and_safe_by_default(self):
        tuning = (ROOT / 'halfin/tools/storage_tuning.sh').read_text(encoding='utf-8')
        installer = (ROOT / 'halfin/pre_install.sh').read_text(encoding='utf-8')
        self.assertIn('etapa_armazenamento', installer)
        self.assertIn('zram-tools', tuning)
        self.assertIn('zram_is_active()', tuning)
        self.assertIn('export PATH=/usr/sbin:/usr/bin:/sbin:/bin', tuning)
        self.assertIn('preserving the image provider', tuning)
        self.assertIn('swapon --show --noheadings --raw --output NAME', tuning)
        self.assertIn('SystemMaxUse=100M', tuning)
        self.assertIn('MaxRetentionSec=14day', tuning)
        self.assertIn('vm.swappiness=10', tuning)
        self.assertIn('noatime', tuning)
        self.assertIn('^commit=', tuning)

    def test_halfin_menu_delegates_to_shared_root_engine(self):
        self.assertIn('BITCOIN_ENGINE="$GN_ROOT/bitcoin/bitcoin-node.sh"', MENU)
        self.assertIn('--profile halfin --install', MENU)
        self.assertIn('--profile halfin --plan', MENU)
        self.assertNotIn('`r`nBITCOIN_ENGINE', MENU)
        self.assertIn('0|"") return ;;', MENU)
        self.assertIn('journalctl -fu "$BITCOIN_SERVICE" --no-pager', MENU)
        self.assertIn('Pressione CTRL+C para voltar.', MENU)
        self.assertIn('press_enter', MENU)

if __name__ == '__main__':
    unittest.main()
