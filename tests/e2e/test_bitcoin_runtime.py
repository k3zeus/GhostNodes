"""Real upstream binary + generated service/config + local regtest RPC."""
from pathlib import Path
import json
import time

from test_install_behavior import bash


def test_bitcoin_install_service_rpc_and_restart():
    # Keep the test off mainnet without mocking the installer or bitcoind.
    dropin = Path('/etc/systemd/system/satoshi-bitcoind.service.d')
    dropin.mkdir(parents=True, exist_ok=True)
    (dropin / 'test-network.conf').write_text('''[Service]
ExecStart=
ExecStart=/usr/local/bin/bitcoind -regtest -rpcport=8332 -rpcbind=127.0.0.1 -rpcallowip=127.0.0.1 -conf=/home/bitcoin/.bitcoin/bitcoin.conf -datadir=/home/bitcoin/.bitcoin
ExecStop=
ExecStop=/usr/local/bin/bitcoin-cli -regtest -rpcport=8332 -conf=/home/bitcoin/.bitcoin/bitcoin.conf stop
''')
    result = bash('bash /work/satoshi/install.sh', {
        'GN_AUTO_INSTALL': 'true', 'GN_INSTALL_MODE': 'pruned',
        'SATOSHI_VARIANT': 'core', 'SATOSHI_VERSION': '29.1',
        'GN_HW_ARCH': 'x86_64', 'SATOSHI_PRUNE_GB': '10'}, timeout=300)
    assert result.returncode == 0, result.stdout + result.stderr
    rpc = 'bitcoin-cli -regtest -rpcport=8332 -conf=/home/bitcoin/.bitcoin/bitcoin.conf getblockchaininfo'
    for _ in range(30):
        result = bash(rpc)
        if result.returncode == 0:
            break
        time.sleep(1)
    assert result.returncode == 0, result.stderr
    info = json.loads(result.stdout)
    assert info['chain'] == 'regtest' and info['pruned'] is True
    assert info['prune_target_size'] == 10240 * 1024 * 1024
    assert Path('/home/bitcoin/.bitcoin/bitcoin.conf').stat().st_mode & 0o777 == 0o600
    assert bash('systemctl restart satoshi-bitcoind').returncode == 0
    result = bash('bitcoin-cli -rpcwait -regtest -rpcport=8332 -conf=/home/bitcoin/.bitcoin/bitcoin.conf getblockchaininfo')
    assert result.returncode == 0, result.stderr
