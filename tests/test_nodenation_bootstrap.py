import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = (ROOT / 'nodenation').read_text(encoding='utf-8')

class NodeNationBootstrapTests(unittest.TestCase):
    def test_interactive_bootstrap_requires_a_tty_explicitly(self):
        self.assertIn('Interactive installation needs a TTY', SOURCE)
        self.assertIn('GN_BOOTSTRAPPED', SOURCE)

    def test_tui_tolerates_missing_term(self):
        self.assertIn('clear_screen()', SOURCE)
        self.assertIn('clear >/dev/null 2>&1 || true', SOURCE)
        self.assertNotIn('banner_root() {\n    clear\n', SOURCE)

    def test_automatic_download_failure_is_not_masked(self):
        self.assertIn('Automatic download failed', SOURCE)
        self.assertNotIn('download_project || true', SOURCE)

    def test_download_selects_only_the_expected_archive_root(self):
        exact = 'local EXTRACTED="${EXTRACT_PARENT}/${GN_REPO_DIR_NAME}"'
        self.assertIn(exact, SOURCE)
        self.assertNotIn('find "$EXTRACT_PARENT" -maxdepth 1 -type d -iname "ghostnodes*"', SOURCE)
        self.assertIn('"${EXTRACTED}/halfin/lib/init.sh"', SOURCE)
        self.assertIn('"${EXTRACTED}/var/auto.sh"', SOURCE)
if __name__ == '__main__':
    unittest.main()