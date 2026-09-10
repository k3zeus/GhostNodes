from test_install_behavior import bash


def test_web_installer_serves_frontend_and_health():
    result = bash('bash /work/halfin/extras/webapp.sh', {'GN_USER': 'gnstage'}, timeout=600)
    assert result.returncode == 0, result.stdout + result.stderr
    result = bash('curl -fsS http://127.0.0.1:8088/api/health')
    assert result.returncode == 0 and '"status":"ok"' in result.stdout
    result = bash('systemctl restart ghostnodes-web; sleep 2; curl -fsS http://127.0.0.1:8088/')
    assert result.returncode == 0 and '<html' in result.stdout
