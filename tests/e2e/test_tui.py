"""Public entrypoints driven through a real pseudo-terminal, without menu mocks."""
import os
from pathlib import Path
import pexpect
import pytest

PROMPT = r'Op(?:ç|c)(?:ã|a)o:.*? '


def spawn(command, tmp_path):
    child = pexpect.spawn('/bin/bash', ['-c', command], encoding='utf-8',
                          env={**os.environ, 'TERM': 'xterm', 'GN_ROOT': '/work'},
                          timeout=20, dimensions=(40, 120))
    child.logfile = (tmp_path / 'terminal.log').open('w')
    return child


@pytest.mark.parametrize('submenu', ['1', '2', '3', '4'])
@pytest.mark.parametrize('leave', ['0', 'q'])
def test_installed_dashboard_navigation(tmp_path, submenu, leave):
    child = spawn('ghostnode', tmp_path)
    try:
        child.expect('Menu Principal')
        child.expect(PROMPT)
        child.sendline(submenu)
        child.expect(PROMPT)
        assert '[0]' in child.before and '[q]' in child.before
        child.sendline(leave)
        if leave == '0':
            child.expect('Menu Principal')
            child.expect(PROMPT)
            child.sendline('q')
        child.expect(pexpect.EOF)
        child.close()
        assert child.exitstatus == 0
    finally:
        child.close(force=True)


@pytest.mark.parametrize('option', ['5', '6'])
def test_power_actions_cancel(tmp_path, option):
    child = spawn('ghostnode', tmp_path)
    try:
        child.expect(PROMPT)
        child.sendline(option)
        child.expect(r'\]: ')
        child.sendline('n')
        child.expect('Menu Principal')
        child.expect(PROMPT)
        child.sendline('q')
        child.expect(pexpect.EOF)
    finally:
        child.close(force=True)


@pytest.mark.parametrize('option', ['1', '2', '3', '4', '5', '6', '7', 'c', '?'])
def test_bootstrap_main_submenus_return(tmp_path, option):
    child = spawn('bash /work/nodenation', tmp_path)
    try:
        child.expect(PROMPT)
        child.sendline(option)
        child.expect(PROMPT)
        child.sendline('0')
        child.expect(PROMPT)
        child.sendline('q')
        child.expect(pexpect.EOF)
        child.close()
        assert child.exitstatus == 0
    finally:
        child.close(force=True)


def test_curl_pipe_bash_menu(tmp_path):
    import http.server
    import threading
    from functools import partial
    handler = partial(http.server.SimpleHTTPRequestHandler, directory='/work')
    server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    child = spawn(f'curl -fsSL http://127.0.0.1:{server.server_port}/nodenation | bash', tmp_path)
    try:
        child.expect(PROMPT)
        child.sendline('2')
        child.expect('Satoshi')
        child.expect(PROMPT)
        child.sendline('0')
        child.expect(PROMPT)
        child.sendline('q')
        child.expect(pexpect.EOF)
        child.close()
        assert child.exitstatus == 0
    finally:
        child.close(force=True)
        server.shutdown()
        server.server_close()


@pytest.mark.parametrize('subpath', [('1', '2'), ('2', '1'), ('2', '2'), ('2', '3'), ('3', '1'), ('3', '3'), ('4', '1')])
def test_dashboard_operational_pages_return(tmp_path, subpath):
    child = spawn('ghostnode', tmp_path)
    try:
        child.expect(PROMPT)
        child.sendline(subpath[0])
        child.expect(PROMPT)
        child.sendline(subpath[1])
        for _ in range(12):
            prompt = child.expect(['ENTER para', r'\]: '], timeout=45)
            if prompt == 0:
                break
            child.sendline('n')
        else:
            pytest.fail('Operational page did not return after declining actions')
        assert 'command not found' not in child.before
        assert 'unbound variable' not in child.before
        child.sendline('')
        child.expect(PROMPT)
        child.sendline('0')
        child.expect('Menu Principal')
        child.expect(PROMPT)
        child.sendline('q')
        child.expect(pexpect.EOF)
    finally:
        child.close(force=True)


@pytest.mark.parametrize('variant,version,prune', [('1', '29.1', '1'), ('2', '28.1.knots20250305', '2')])
def test_satoshi_manual_plan_can_cancel_install(tmp_path, variant, version, prune):
    child = spawn('bash /work/nodenation', tmp_path)
    try:
        child.expect(PROMPT); child.sendline('2')
        child.expect(PROMPT); child.sendline('2')
        child.expect(PROMPT); child.sendline(variant)
        child.expect('padrao: '); child.sendline(version)
        child.expect(PROMPT); child.sendline('2')
        child.expect(PROMPT); child.sendline(prune)
        child.expect('Executar instalacao do Bitcoin Node')
        child.expect(PROMPT); child.sendline('0')
        child.expect(PROMPT); child.sendline('q')
        child.expect(pexpect.EOF)
        child.close()
        assert child.exitstatus == 0
    finally:
        child.close(force=True)
