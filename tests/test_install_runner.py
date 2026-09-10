"""Portable safety tests; no Docker or Linux host changes."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('runner', ROOT / 'tests/e2e/run_install_matrix.py')
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class RunnerSafetyTests(unittest.TestCase):
    def test_low_disk_refuses_before_docker_or_snapshot(self):
        with patch.object(runner.shutil, 'disk_usage') as disk, \
                patch.object(runner, 'check_local_daemon') as docker, \
                patch.object(runner, 'snapshot') as snapshot:
            disk.return_value.free = 1024
            with self.assertRaisesRegex(RuntimeError, 'GiB required'):
                runner.main(['--run', '--docker-storage', str(ROOT)])
            docker.assert_not_called()
            snapshot.assert_not_called()

    def test_remote_docker_is_rejected(self):
        with patch.dict(runner.os.environ, {'DOCKER_HOST': 'ssh://example.invalid'}), \
                patch.object(runner.subprocess, 'run') as command:
            with self.assertRaisesRegex(RuntimeError, 'DOCKER_HOST'):
                runner.check_local_daemon()
            command.assert_not_called()

    def test_remote_context_is_rejected(self):
        with patch.dict(runner.os.environ, {}, clear=True), \
                patch.object(runner.subprocess, 'run') as command:
            command.return_value.stdout = '[{"Endpoints":{"docker":{"Host":"tcp://example.invalid:2375"}}}]'
            with self.assertRaisesRegex(RuntimeError, 'non-local'):
                runner.check_local_daemon()
            self.assertEqual(command.call_count, 1)

    def test_source_snapshot_excludes_secrets_and_generated_data(self):
        output = runner.TEST_ROOT / 'GhostNodes/unit-fixtures'
        output.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=output) as tmp:
            root = Path(tmp)
            subprocess.run(['git', 'init', '-q', str(root)], check=True)
            files = ['var/globals.env', 'halfin/var/globals.env',
                     'halfin/docker/pass.txt', 'halfin/docker/data/private.txt',
                     'halfin/docker/.env', 'halfin/docker/.env.local', 'web/.venv/local.py',
                     'halfin/pre_install.sh', 'web/backend/requirements.txt',
                     'tests/e2e/Dockerfile.install', 'tests/evidence/results.json']
            for name in files:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('synthetic fixture\n')
            self.assertEqual(list(runner.source_paths(root)), sorted([
                'var/globals.env', 'halfin/pre_install.sh',
                'web/backend/requirements.txt', 'tests/e2e/Dockerfile.install']))

    def test_default_only_checks_prerequisites(self):
        with patch.object(runner, 'check_space'), \
                patch.object(runner, 'check_local_daemon'), \
                patch.object(runner, 'snapshot') as snapshot:
            self.assertEqual(runner.main(['--docker-storage', str(ROOT)]), 0)
            snapshot.assert_not_called()


if __name__ == '__main__':
    unittest.main()
