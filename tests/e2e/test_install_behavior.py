"""Behavioral regressions. Run as root ONLY inside the disposable TDD images."""
import os
from pathlib import Path
import re
import subprocess
import tempfile

import pytest

ROOT = Path('/work')


def bash(code, env=None, timeout=30):
    return subprocess.run(['bash', '-c', code], text=True, capture_output=True,
                          timeout=timeout, env={**os.environ, 'TERM': 'xterm',
                          'GN_ROOT': str(ROOT), **(env or {})})


def functions(path):
    # Unit seam only; PTY tests separately execute the unmodified entrypoints.
    source = (ROOT / path).read_text()
    return '\n'.join(re.findall(r'^\w+\(\) \{\n.*?^\}', source, re.M | re.S))


def prelude(path='halfin/pre_install.sh'):
    return 'source /work/halfin/lib/init.sh\n' + functions(path) + '\n'


def test_update_failure_not_recorded(tmp_path):
    result = bash(prelude() + '''
PRE_STATE="$TEST_TMP/state"; touch "$PRE_STATE"
apt-get() { return 42; }
etapa_update
''', {'TEST_TMP': str(tmp_path)})
    assert result.returncode != 0, result.stdout
    assert 'etapa_update=1' not in (tmp_path / 'state').read_text()


def test_package_failure_not_recorded(tmp_path):
    result = bash(prelude() + '''
PRE_STATE="$TEST_TMP/state"; touch "$PRE_STATE"
dpkg() { return 1; }; apt-get() { return 42; }
etapa_ferramentas
''', {'TEST_TMP': str(tmp_path)})
    assert result.returncode != 0, result.stdout
    assert 'etapa_ferramentas=1' not in (tmp_path / 'state').read_text()


@pytest.mark.parametrize('missing', [False, True])
def test_extra_failure_propagates(tmp_path, missing):
    script = tmp_path / 'extra.sh'
    if not missing:
        script.write_text('#!/bin/bash\nexit 42\n')
    result = bash(prelude() + '_run_extra "$TEST_SCRIPT" demo',
                  {'TEST_SCRIPT': str(script)})
    assert result.returncode != 0, result.stdout


def test_preserve_distribution_sources():
    files = list(Path('/etc/apt').glob('sources.list*'))
    before = {str(p): p.read_bytes() for f in files
              for p in ([f] if f.is_file() else f.rglob('*')) if p.is_file()}
    with tempfile.TemporaryDirectory() as tmp:
        result = bash(prelude() + '''
PRE_STATE="$TEST_TMP/state"; touch "$PRE_STATE"
etapa_sourcelist
''', {'TEST_TMP': tmp})
    after = {str(p): p.read_bytes() for f in Path('/etc/apt').glob('sources.list*')
             for p in ([f] if f.is_file() else f.rglob('*')) if p.is_file()}
    # Restore original sources so a red run does not poison later package tests.
    for p in after.keys() - before.keys():
        Path(p).unlink()
    for p, content in before.items():
        Path(p).write_bytes(content)
    assert result.returncode == 0, result.stderr
    assert before == after, 'Installer rewrote the distribution repositories'


def test_fail2ban_configuration_is_valid_and_repeatable():
    for _ in range(2):
        result = bash('bash /work/halfin/extras/fail2ban.sh', timeout=90)
        assert result.returncode == 0, result.stdout + result.stderr
        parsed = bash('fail2ban-client -t')
        assert parsed.returncode == 0, parsed.stdout + parsed.stderr


def test_routing_preserves_unrelated_nat_and_is_idempotent():
    bash('ip link add br0 type bridge; ip link set br0 up')
    rule = '-t nat -A POSTROUTING -s 172.30.0.0/16 -j MASQUERADE'
    bash('iptables ' + rule)
    before = bash('iptables-save -t nat').stdout
    try:
        for _ in range(2):
            result = bash('bash /work/halfin/install.sh')
            assert result.returncode == 0, result.stdout + result.stderr
        after = bash('iptables-save -t nat').stdout
        assert '-A POSTROUTING -s 172.30.0.0/16 -j MASQUERADE' in after
        assert after.count('-A HALFIN-NAT ') == 1
    finally:
        bash('iptables -t nat -D POSTROUTING -s 172.30.0.0/16 -j MASQUERADE')


def test_global_command_uses_same_dashboard(tmp_path):
    result = bash('bash /work/halfin/ghostnode-install.sh')
    assert result.returncode == 0, result.stdout + result.stderr
    help_result = bash('env -u GN_ROOT ghostnode --help')
    assert help_result.returncode == 0, help_result.stdout + help_result.stderr
    assert 'Satoshi' in help_result.stdout
    assert '/work/halfin' in help_result.stdout


def test_satoshi_random_password_does_not_abort(tmp_path):
    result = bash('set -euo pipefail\n' + prelude('satoshi/install.sh') + '''
banner() { :; }; ensure_bitcoin_user() { :; }; choose_install_mode() { :; }
write_rpc_env() { :; }; create_systemd_service() { :; }; systemctl() { :; }
chown() { :; }; log_ok() { :; }
BITCOIN_DIR="$TEST_TMP"; BITCOIN_CONF="$TEST_TMP/bitcoin.conf"
SATOSHI_LOG_DIR="$TEST_TMP"; SATOSHI_ENV_FILE="$TEST_TMP/missing.env"
BITCOIN_USER=bitcoin; BITCOIN_GROUP=bitcoin; BITCOIN_SERVICE=demo
INSTALL_MODE=pruned; SATOSHI_PRUNE_GB=10; AUTO_MODE=true
configurar_bitcoin
''', {'TEST_TMP': str(tmp_path)})
    assert result.returncode == 0, result.stdout + result.stderr
    assert 'prune=10240' in (tmp_path / 'bitcoin.conf').read_text()


@pytest.mark.parametrize('version', ['28.1.knots20250305', '29.3.knots20260210'])
def test_knots_custom_major(version):
    result = bash(prelude('satoshi/install.sh') + '''
GN_HW_ARCH=x86_64; BITCOIN_VARIANT=knots; BITCOIN_VERSION="$TEST_VERSION"
resolve_release; printf '%s' "$BITCOIN_URL"
''', {'TEST_VERSION': version})
    assert f'/files/{version.split(".")[0]}.x/' in result.stdout


@pytest.mark.parametrize('version', ['../../bad', 'not-a-version', '29.1\nextra'])
def test_reject_invalid_bitcoin_version(version):
    result = bash(prelude('satoshi/install.sh') + '''
GN_HW_ARCH=x86_64; BITCOIN_VARIANT=core; BITCOIN_VERSION="$TEST_VERSION"
resolve_release
''', {'TEST_VERSION': version})
    assert result.returncode != 0


def test_cancel_confirmation_at_eof():
    result = bash('source /work/halfin/lib/init.sh; confirm example </dev/null')
    assert result.returncode != 0


def test_runtime_context_survives_library_load():
    result = bash('source /work/halfin/lib/init.sh; printf "%s|%s|%s|%s" "$GN_ROOT" "$GN_USER" "$GN_HW_ARCH" "$GN_REPO_URL"',
                  {'GN_USER': 'tester', 'GN_HW_ARCH': 'x86_64',
                   'GN_REPO_URL': 'http://127.0.0.1/main.tar.gz'})
    assert result.stdout == '/work|tester|x86_64|http://127.0.0.1/main.tar.gz'


def test_promotion_preserves_installed_data(tmp_path):
    staging = tmp_path / 'staging'
    target = tmp_path / 'installed'
    staging.mkdir()
    (staging / 'new.txt').write_text('new version')
    (target / 'var').mkdir(parents=True)
    (target / 'var' / 'bitcoin-rpc.env').write_text('synthetic-secret')
    (target / 'halfin/docker/data').mkdir(parents=True)
    (target / 'halfin/docker/data/sentinel').write_text('user data')
    result = bash(prelude('nodenation') + '''
GN_ROOT="$TEST_TARGET"; GN_TMP_DIR="$TEST_STAGING"; GN_USER=tester
GN_USER_HOME=/home/tester; GN_TMP_HW=/nonexistent; GN_TMP_STATE=/nonexistent
instalar_projeto
''', {'TEST_TARGET': str(target), 'TEST_STAGING': str(staging)})
    assert result.returncode == 0, result.stdout + result.stderr
    assert (target / 'var/bitcoin-rpc.env').read_text() == 'synthetic-secret'
    assert (target / 'halfin/docker/data/sentinel').read_text() == 'user data'
    assert (target / 'new.txt').read_text() == 'new version'
