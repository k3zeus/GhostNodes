#!/usr/bin/env python3
"""Halfin AP ownership, boot readiness and bounded recovery. Never resets passwords."""
import argparse
import ipaddress
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

CONFIG = Path('/etc/halfin/ap.json')
STATE = Path('/run/halfin-ap')


def command(*args, check=False, timeout=15):
    try:
        return subprocess.run(args, text=True, capture_output=True, timeout=timeout,
                              check=check, env={**os.environ, 'LC_ALL': 'C'})
    except FileNotFoundError:
        if check:
            raise
        return subprocess.CompletedProcess(args, 127, '', 'command unavailable')


def atomic(path, text, mode=0o644):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(path.name + '.halfin-tmp')
    fd = os.open(temp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC | os.O_NOFOLLOW, mode)
    with os.fdopen(fd, 'w') as stream:
        stream.write(text)
    temp.chmod(mode)
    temp.replace(path)


def validate_config(cfg, wan=None):
    for key in ('ap', 'bridge'):
        if not re.fullmatch(r'[a-zA-Z0-9_.-]{1,15}', cfg[key]):
            raise ValueError('Invalid interface name')
    if cfg['ap'] == cfg['bridge'] or wan in (cfg['ap'], cfg['bridge']):
        raise ValueError('AP/bridge cannot be the WAN')
    address = ipaddress.IPv4Interface(cfg['address'])
    if address.ip in (address.network.network_address, address.network.broadcast_address):
        raise ValueError('Invalid bridge host address')
    if cfg['dns_service'] not in ('dnsmasq', 'pihole-FTL'):
        raise ValueError('Unsupported DNS/DHCP service')


def default_wan():
    routes = json.loads(command('ip', '-j', '-4', 'route', 'show', 'default').stdout or '[]')
    return next((r.get('dev') for r in routes if 'linkdown' not in r.get('flags', [])), None)


def select_dns_service():
    if shutil.which('pihole-FTL'):
        active = command('pihole-FTL', '--config', 'dhcp.active').stdout.strip()
        if active == 'true':
            return 'pihole-FTL'
    return 'dnsmasq'


def dns_unit():
    return '[Unit]\nRequires=halfin-ap-prepare.service\nAfter=halfin-ap-prepare.service\n[Service]\nTimeoutStopSec=20\n'


def ensure_dns_owner(cfg):
    chosen = cfg['dns_service']
    other = 'dnsmasq' if chosen == 'pihole-FTL' else 'pihole-FTL'
    if command('systemctl', 'show', other, '-p', 'LoadState', '--value').stdout.strip() != 'not-found':
        command('systemctl', 'disable', '--now', other, check=True, timeout=40)
        command('systemctl', 'reset-failed', other)
    command('systemctl', 'enable', chosen, check=True)


def compatible_hostapd(text, ap, bridge):
    values = {}
    for line in text.splitlines():
        if '=' in line and not line.lstrip().startswith('#'):
            key, value = line.split('=', 1)
            values[key.strip()] = value
    if 'bss' in values:
        raise ValueError('Multiple BSS configuration requires manual migration')
    if not values.get('ssid') or not (values.get('wpa_passphrase') or values.get('wpa_psk')):
        raise ValueError('Existing SSID and WPA password required; no password will be invented')
    if len(values['ssid'].encode()) > 32:
        raise ValueError('SSID exceeds 32 bytes')
    if 'wpa_passphrase' in values and not 8 <= len(values['wpa_passphrase']) <= 63:
        raise ValueError('Invalid WPA passphrase length')
    if 'wpa_psk' in values and not re.fullmatch('[a-fA-F0-9]{64}', values['wpa_psk']):
        raise ValueError('Invalid WPA PSK')
    for key in ('ieee80211ac', 'ieee80211ax', 'ieee80211h', 'ht_capab', 'vht_capab',
                'vht_oper_chwidth', 'vht_oper_centr_freq_seg0_idx', 'vht_oper_centr_freq_seg1_idx'):
        values.pop(key, None)
    values.update(interface=ap, bridge=bridge, driver='nl80211', hw_mode='g', channel='6',
                  country_code=values.get('country_code', 'BR'), auth_algs='1', wpa='2',
                  wpa_key_mgmt='WPA-PSK', wpa_pairwise='CCMP', rsn_pairwise='CCMP',
                  wmm_enabled='1', ctrl_interface='/run/hostapd', ieee80211w='0')
    return '# Halfin: conservative WPA2 AP; credentials preserved.\n' + ''.join(
        f'{key}={value}\n' for key, value in values.items())


def remove_owned_interfaces(text, owned):
    result, skip = [], False
    for line in text.splitlines(keepends=True):
        words = line.split()
        if words and words[0] == 'iface':
            skip = len(words) > 1 and words[1] in owned
        elif words and words[0] in ('auto', 'allow-hotplug', 'source', 'source-directory', 'mapping'):
            skip = False
            if words[0] in ('auto', 'allow-hotplug'):
                names = [n for n in words[1:] if n not in owned]
                if not names:
                    continue
                if names != words[1:]:
                    line = words[0] + ' ' + ' '.join(names) + '\n'
        if not skip:
            result.append(line)
    return ''.join(result)


def prepare(cfg):
    validate_config(cfg, default_wan())
    ap, bridge = cfg['ap'], cfg['bridge']
    if not Path('/sys/class/net', ap).exists():
        raise RuntimeError('AP radio missing; no WAN changes made')
    command('nmcli', 'general', 'reload')
    command('nmcli', 'device', 'set', ap, 'managed', 'no')
    command('nmcli', 'device', 'set', bridge, 'managed', 'no')
    if not Path('/sys/class/net', bridge).exists():
        command('ip', 'link', 'add', 'name', bridge, 'type', 'bridge', check=True)
    command('ip', 'address', 'replace', cfg['address'], 'dev', bridge, check=True)
    command('ip', 'link', 'set', bridge, 'up', check=True)
    command('iw', 'dev', ap, 'set', 'power_save', 'off')


def diagnose(cfg):
    validate_config(cfg)
    ap, bridge = cfg['ap'], cfg['bridge']
    issues = []
    if not Path('/sys/class/net', ap).exists():
        return {'issues': ['radio_missing'], 'clients': 0}
    managed = command('nmcli', '-g', 'GENERAL.NM-MANAGED', 'device', 'show', ap).stdout.strip()
    if managed == 'yes':
        issues.append('manager_conflict')
    status = command('hostapd_cli', '-i', ap, 'status').stdout
    if 'state=ENABLED' not in status:
        issues.append('ap_not_ready')
    if not Path('/sys/class/net', bridge, 'brif', ap).exists():
        issues.append('bridge_membership')
    addr = command('ip', '-j', '-4', 'addr', 'show', 'dev', bridge)
    addresses = [f"{a['local']}/{a['prefixlen']}" for d in json.loads(addr.stdout or '[]')
                 for a in d.get('addr_info', [])]
    if cfg['address'] not in addresses:
        issues.append('bridge_address')
    service = cfg['dns_service']
    other = 'dnsmasq' if service == 'pihole-FTL' else 'pihole-FTL'
    if (command('systemctl', 'is-enabled', '--quiet', other).returncode == 0
            or command('systemctl', 'is-active', '--quiet', other).returncode == 0):
        issues.append('dns_conflict')
    if command('systemctl', 'is-active', '--quiet', service).returncode:
        issues.append('dhcp_service')
    if not command('ss', '-H', '-lun', 'sport = :67').stdout.strip():
        issues.append('dhcp_socket')
    gateway = cfg['address'].split('/')[0]
    dns = command('dig', '+time=2', '+tries=1', '@' + gateway, 'localhost', 'A').stdout
    if 'status: NOERROR' not in dns:
        issues.append('local_dns')
    station = command('iw', 'dev', ap, 'station', 'dump').stdout
    return {'issues': issues, 'ap': ap, 'bridge': bridge, 'manager': managed,
            'dns_owner': service,
            'clients': station.count('Station '), 'hostapd_ready': 'state=ENABLED' in status,
            'address': cfg['address'],
            'note': 'No clients is not a failure. Local checks do not prove a client WPA handshake or internet access.'}


def repair(cfg, automatic=False):
    report = diagnose(cfg)
    recoverable = {'manager_conflict', 'ap_not_ready', 'bridge_membership',
                   'bridge_address', 'dhcp_service', 'dhcp_socket', 'local_dns', 'dns_conflict'}
    faults = set(report['issues']) & recoverable
    if not faults or 'radio_missing' in report['issues']:
        return report
    validate_config(cfg, default_wan())
    STATE.mkdir(exist_ok=True, mode=0o755)
    last = STATE / 'last-repair'
    now = time.monotonic()
    if automatic and last.exists() and now - float(last.read_text()) < 300:
        report['recovery'] = 'cooldown: no restart storm'
        return report
    if automatic:
        atomic(last, str(now))
    if faults & {'manager_conflict', 'ap_not_ready', 'bridge_membership', 'bridge_address'}:
        prepare(cfg)
        command('systemctl', 'restart', 'hostapd', check=True, timeout=40)
    if faults & {'dhcp_service', 'dhcp_socket', 'local_dns', 'bridge_address', 'dns_conflict'}:
        ensure_dns_owner(cfg)
        if cfg['dns_service'] == 'dnsmasq':
            command('dnsmasq', '--test', check=True)
        command('systemctl', 'restart', cfg['dns_service'], check=True, timeout=40)
    for _ in range(15):
        report = diagnose(cfg)
        if not report['issues']:
            break
        time.sleep(1)
    report['recovery'] = 'attempted once; credentials and WAN preserved'
    return report


def install(cfg):
    validate_config(cfg, default_wan())
    if not Path('/sys/class/net', cfg['ap']).exists():
        raise RuntimeError('Radio missing')
    for name in ('ip', 'iw', 'hostapd_cli', 'dig', 'ss', 'systemctl'):
        if not shutil.which(name):
            raise RuntimeError('Missing dependency: ' + name)
    # Do not let the periodic repair race with configuration/service migration.
    command('systemctl', 'stop', 'halfin-ap-health.timer')
    command('systemctl', 'stop', 'halfin-ap-health.service', timeout=160)
    hostapd = Path('/etc/hostapd/hostapd.conf')
    content = compatible_hostapd(hostapd.read_text(), cfg['ap'], cfg['bridge'])
    files = {hostapd: (content, 0o600), CONFIG: (json.dumps(cfg, indent=2) + '\n', 0o644)}
    for path in [Path('/etc/network/interfaces'), *Path('/etc/network/interfaces.d').glob('*')]:
        if path.is_file():
            original = path.read_text()
            revised = remove_owned_interfaces(original, {cfg['ap'], cfg['bridge']})
            if revised != original:
                files[path] = (revised, path.stat().st_mode & 0o777)
    nm = Path('/etc/NetworkManager/conf.d/99-halfin-ap.conf')
    files[nm] = (f"[keyfile]\nunmanaged-devices+=interface-name:{cfg['ap']};interface-name:{cfg['bridge']}\n", 0o644)
    files[Path('/etc/systemd/system') / (cfg['dns_service'] + '.service.d/halfin-ap.conf')] = (dns_unit(), 0o644)
    binary = Path('/usr/local/lib/halfin/ap_health.py')
    files[binary] = (Path(__file__).read_text(), 0o755)
    files[Path('/usr/local/bin/halfin-ap')] = ('#!/bin/sh\nexec python3 /usr/local/lib/halfin/ap_health.py "$@"\n', 0o755)
    files[Path('/etc/systemd/system/halfin-ap-prepare.service')] = ('''[Unit]
Description=Halfin AP bridge and exclusive radio ownership
After=NetworkManager.service
Before=hostapd.service
Wants=NetworkManager.service
[Service]
Type=oneshot
ExecStart=/usr/local/bin/halfin-ap prepare
RemainAfterExit=yes
TimeoutStartSec=45
[Install]
WantedBy=multi-user.target
''', 0o644)
    files[Path('/etc/systemd/system/hostapd.service.d/halfin.conf')] = ('''[Unit]
Requires=halfin-ap-prepare.service
After=halfin-ap-prepare.service
[Service]
Restart=on-failure
RestartSec=5
''', 0o644)
    files[Path('/etc/systemd/system/halfin-ap-health.service')] = ('''[Unit]
Description=Halfin AP local health and bounded recovery
After=hostapd.service
[Service]
Type=oneshot
ExecStart=/usr/local/bin/halfin-ap repair --automatic
TimeoutStartSec=150
''', 0o644)
    files[Path('/etc/systemd/system/halfin-ap-health.timer')] = ('''[Unit]
Description=Check Halfin AP after boot and periodically
[Timer]
OnBootSec=45
OnUnitActiveSec=60
AccuracySec=5
[Install]
WantedBy=timers.target
''', 0o644)
    # Keep originals and absence information for an exact, host-local rollback.
    backup = Path('/var/backups/halfin-ap') / (time.strftime('%Y%m%d-%H%M%S') + '-' + str(os.getpid()))
    backup.mkdir(parents=True, mode=0o700)
    manifest = {}
    for path in files:
        if path.is_symlink():
            raise RuntimeError('Refusing to replace symlink: ' + str(path))
        manifest[str(path)] = path.exists()
        if path.exists():
            dest = backup / str(path).lstrip('/')
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, dest)
    atomic(backup / 'manifest.json', json.dumps(manifest), 0o600)
    service_state = {svc: command('systemctl', 'is-enabled', svc).stdout.strip()
                     for svc in ('dnsmasq', 'pihole-FTL')}
    atomic(backup / 'dns-services.json', json.dumps(service_state), 0o600)
    shutil.copy2(Path(__file__), backup / 'recovery.py')
    print('Backup: ' + str(backup), flush=True)
    rollback_unit = 'halfin-ap-install-rollback-' + str(os.getpid())
    command('systemd-run', '--unit=' + rollback_unit, '--on-active=300',
            '/usr/bin/python3', str(backup / 'recovery.py'), 'restore', '--backup', str(backup), check=True)
    for path, (text, mode) in files.items():
        atomic(path, text, mode)
    command('systemctl', 'daemon-reload', check=True)
    ensure_dns_owner(cfg)
    command('systemctl', 'enable', 'halfin-ap-prepare.service', 'hostapd.service',
            'halfin-ap-health.timer', check=True)
    prepare(cfg)
    command('systemctl', 'start', 'halfin-ap-prepare.service', check=True, timeout=50)
    command('systemctl', 'restart', 'hostapd', check=True, timeout=40)
    command('systemctl', 'start', cfg['dns_service'], check=True, timeout=40)
    command('systemctl', 'enable', '--now', 'halfin-ap-health.timer', check=True)
    time.sleep(3)
    report = repair(cfg)
    if not report['issues']:
        command('systemctl', 'stop', rollback_unit + '.timer', check=True)
        (STATE / 'last-repair').unlink(missing_ok=True)
    else:
        report['rollback'] = 'scheduled within 5 minutes; installation NOT accepted'
    return report


def restore(backup):
    backup = Path(backup).resolve()
    if not backup.is_relative_to(Path('/var/backups/halfin-ap')):
        raise ValueError('Invalid backup directory')
    manifest = json.loads((backup / 'manifest.json').read_text())
    command('systemctl', 'disable', '--now', 'halfin-ap-health.timer', 'halfin-ap-prepare.service')
    for name, existed in manifest.items():
        path = Path(name)
        if not any(path.is_relative_to(Path(base)) for base in
                   ('/etc/network', '/etc/halfin', '/etc/hostapd', '/etc/NetworkManager/conf.d',
                    '/etc/systemd/system', '/usr/local/lib/halfin', '/usr/local/bin')):
            raise ValueError('Unexpected backup target')
        if existed:
            shutil.copy2(backup / name.lstrip('/'), path)
        else:
            path.unlink(missing_ok=True)
    command('systemctl', 'daemon-reload', check=True)
    if (backup / 'dns-services.json').exists():
        for svc, state in json.loads((backup / 'dns-services.json').read_text()).items():
            command('systemctl', 'enable' if state == 'enabled' else 'disable', svc)
    command('nmcli', 'general', 'reload')
    command('systemctl', 'restart', 'hostapd', check=True, timeout=40)
    print('Original files restored. WAN was not restarted.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['check', 'repair', 'prepare', 'install', 'restore'])
    parser.add_argument('--backup')
    parser.add_argument('--automatic', action='store_true')
    parser.add_argument('--ap', default='wlan0')
    parser.add_argument('--bridge', default='br0')
    parser.add_argument('--address', default='10.21.21.1/24')
    parser.add_argument('--dns-service', choices=['auto', 'dnsmasq', 'pihole-FTL'], default='auto')
    args = parser.parse_args()
    if args.action != 'check' and os.geteuid() != 0:
        parser.error('Run with sudo; check does not modify the system')
    if args.action == 'restore':
        if not args.backup:
            parser.error('--backup required')
        restore(args.backup)
        return 0
    cfg = ({'ap': args.ap, 'bridge': args.bridge, 'address': args.address,
            'dns_service': select_dns_service() if args.dns_service == 'auto' else args.dns_service}
           if args.action == 'install' else json.loads(CONFIG.read_text()))
    # systemd may invoke prepare as a dependency while repair waits for hostapd.
    # prepare only applies idempotent kernel state and must not take that lock.
    if args.action in ('repair', 'install'):
        import fcntl
        STATE.mkdir(exist_ok=True, mode=0o755)
        lock = (STATE / 'lock').open('w')
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise SystemExit('Another AP operation is running')
    if args.action == 'prepare':
        prepare(cfg)
        return 0
    if args.action == 'install':
        # Release before systemd invokes a separate prepare process.
        fcntl.flock(lock, fcntl.LOCK_UN)
        result = install(cfg)
    elif args.action == 'repair':
        result = repair(cfg, args.automatic)
    else:
        result = diagnose(cfg)
    print(json.dumps(result, indent=2))
    return int(bool(result['issues']))


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError, OSError, RuntimeError, subprocess.SubprocessError) as error:
        # CalledProcessError output may include configuration; never print it.
        print('AP operation failed: ' + str(error), file=sys.stderr)
        sys.exit(1)
