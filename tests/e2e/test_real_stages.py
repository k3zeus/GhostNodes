"""Real package/service stages. Destructive inside the disposable container only."""
from pathlib import Path
import subprocess

from test_install_behavior import bash


def test_create_user_and_install_runtime_dependencies():
    for stage in ['etapa_usuario', 'etapa_sourcelist', 'etapa_ferramentas', 'etapa_aliases', 'etapa_chown']:
        result = bash('bash /work/halfin/pre_install.sh --step "$STAGE"',
                      {'STAGE': stage, 'GN_USER': 'gnstage'}, timeout=300)
        assert result.returncode == 0, result.stdout + result.stderr
    result = bash('id gnstage; command -v nmcli sqlite3 hostapd ifup python3; ghostnode --help')
    assert result.returncode == 0, result.stdout + result.stderr
    assert 'Satoshi' in result.stdout


def test_missing_ap_does_not_change_network():
    before = Path('/etc/network/interfaces').read_bytes()
    result = bash('bash /work/halfin/pre_install.sh --step etapa_orange3',
                  {'HALFIN_AP_IFACE': 'absentwifi'})
    assert result.returncode != 0
    assert Path('/etc/network/interfaces').read_bytes() == before


def test_real_docker_portainer_install_and_repeat():
    for _ in range(2):
        result = bash('printf "1\\nn\\n" | bash /work/halfin/docker/docker.sh', timeout=600)
        assert result.returncode == 0, result.stdout + result.stderr
    result = bash('docker compose version; docker inspect -f "{{.State.Running}}" portainer')
    assert result.returncode == 0 and 'true' in result.stdout
    assert Path('/work/halfin/docker/.env').stat().st_mode & 0o777 == 0o600
