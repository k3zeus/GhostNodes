#!/usr/bin/env python3
"""Shared NetworkManager/SQLite operations for the Halfin terminal tools."""
import configparser
import getpass
import json
import os
from pathlib import Path
import re
import sqlite3
import subprocess
import sys


def database():
    folder = Path(os.environ['GN_DB_DIR'])
    folder.mkdir(parents=True, exist_ok=True)
    folder.chmod(0o700)
    path = folder / 'wifi_scan.db'
    db = sqlite3.connect(path)
    path.chmod(0o600)
    db.execute('''CREATE TABLE IF NOT EXISTS networks (
        id INTEGER PRIMARY KEY AUTOINCREMENT, bssid TEXT UNIQUE, ssid TEXT,
        mode TEXT, channel INTEGER, security TEXT, password TEXT,
        last_seen DATETIME DEFAULT CURRENT_TIMESTAMP)''')
    return db


def nmcli(*args):
    command = ['nmcli', *args]
    if os.environ.get('GN_WIFI_USE_SUDO') == '1' and not is_root():
        command = ['sudo', '-n', *command]
    result = subprocess.run(command, text=True, capture_output=True, timeout=45)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or 'NetworkManager retornou erro')
    return result.stdout


def is_root():
    return getattr(os, 'geteuid', lambda: 0)() == 0


def connection_error_message(error):
    """Translate NetworkManager failures without falsely blaming the password."""
    text = str(error).lower()
    if 'not authorized' in text or 'not authorized to control networking' in text:
        return 'Sem permissao para controlar a rede. Entre pelo submenu Wi-Fi e confirme sudo.'
    if 'could not be found' in text or 'ssid-not-found' in text:
        return 'A rede selecionada nao esta ao alcance neste momento; atualize o scan e tente novamente.'
    if 'secrets were required' in text or 'no secrets' in text:
        return 'A senha nao foi fornecida ao NetworkManager. Informe-a novamente.'
    if 'wrong password' in text or 'password is incorrect' in text or '4-way handshake' in text:
        return 'Autenticacao WPA recusada. Confirme a senha e o tipo de seguranca da rede.'
    return f'Falha na conexao: {safe(str(error))}'


def configure_backup_uplink(interface):
    profile = nmcli('-g', 'GENERAL.CONNECTION', 'device', 'show', interface).strip()
    if profile and profile != '--':
        nmcli('connection', 'modify', profile, 'ipv4.never-default', 'no',
              'ipv4.route-metric', '600', 'ipv6.never-default', 'yes')
        nmcli('device', 'reapply', interface)


def ap_interface():
    if os.environ.get('HALFIN_AP_IFACE'):
        return os.environ['HALFIN_AP_IFACE']
    config = Path('/etc/halfin/ap.json')
    if config.exists():
        return json.loads(config.read_text())['ap']
    # Legacy installations have no AP health configuration yet.
    config = Path('/etc/hostapd/hostapd.conf')
    if config.exists() and os.access(config, os.R_OK):
        for line in config.read_text().splitlines():
            if line.startswith('interface='):
                return line.split('=', 1)[1].strip()
    return None


def scan(db, interface=None):
    reserved = ap_interface()
    if reserved and interface == reserved:
        raise RuntimeError('Interface AP reservada; use o adaptador Wi-Fi secundario.')
    if reserved and interface is None:
        devices = [line.rsplit(':', 1)[0] for line in nmcli('-t', '-f', 'DEVICE,TYPE', 'device', 'status').splitlines()
                   if line.endswith(':wifi') and line.rsplit(':', 1)[0] != reserved]
        if not devices:
            return []
        interface = devices[0]
    args = ['--escape', 'no', '-t', '-m', 'multiline', '-f',
            'BSSID,SSID,MODE,CHAN,SECURITY,SIGNAL', 'device', 'wifi', 'list']
    if interface:
        args += ['ifname', interface, '--rescan', 'yes']
    rows, row = [], {}
    for line in nmcli(*args).splitlines():
        key, sep, value = line.partition(':')
        if not sep:
            continue
        if key == 'BSSID' and row:
            rows.append(row)
            row = {}
        row[key] = value.lstrip()
    if row:
        rows.append(row)
    valid = []
    for row in rows:
        if not re.fullmatch(r'(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}', row.get('BSSID', '')):
            continue
        row['BSSID'] = row['BSSID'].upper()
        row['SSID'] = '' if row.get('SSID') == '--' else row.get('SSID', '')
        channel = row.get('CHAN', '')
        db.execute('''INSERT INTO networks(bssid,ssid,mode,channel,security)
            VALUES(?,?,?,?,?) ON CONFLICT(bssid) DO UPDATE SET
            ssid=excluded.ssid,mode=excluded.mode,channel=excluded.channel,
            security=excluded.security,last_seen=CURRENT_TIMESTAMP''',
            (row['BSSID'], row['SSID'], row.get('MODE', 'Infra'),
             int(channel) if channel.isdecimal() else None, row.get('SECURITY', '')))
        valid.append(row)
    db.commit()
    return valid


def import_nm(db, folder):
    count = 0
    for path in Path(folder).iterdir():
        if not path.is_file():
            continue
        parser = configparser.ConfigParser(interpolation=None, strict=False)
        parser.read(path)
        if parser.get('connection', 'type', fallback='') not in ('wifi', '802-11-wireless'):
            continue
        ssid = parser.get('wifi', 'ssid', fallback='')
        if not ssid:
            continue
        bssid = parser.get('wifi', 'bssid', fallback='').upper()
        password = parser.get('wifi-security', 'psk', fallback='')
        if bssid:
            db.execute('''INSERT INTO networks(bssid,ssid,password) VALUES(?,?,?)
                ON CONFLICT(bssid) DO UPDATE SET ssid=excluded.ssid,
                password=excluded.password,last_seen=CURRENT_TIMESTAMP''', (bssid, ssid, password))
        elif db.execute('SELECT 1 FROM networks WHERE ssid=?', (ssid,)).fetchone():
            db.execute('UPDATE networks SET password=? WHERE ssid=?', (password, ssid))
        else:
            db.execute('INSERT INTO networks(ssid,password) VALUES(?,?)', (ssid, password))
        count += 1
    db.commit()
    print(f'Perfis Wi-Fi importados: {count}')


def safe(value):
    return ''.join(c if c.isprintable() else '?' for c in value)


def answer(prompt):
    try:
        value = input(prompt).strip()
    except EOFError:
        raise SystemExit(0)
    if value.lower() == 'q':
        raise SystemExit(200 if os.environ.get('GN_TUI_CHILD') == '1' else 0)
    return value


def connect(db):
    while True:
        devices = [line.rsplit(':', 1)[0] for line in nmcli('-t', '-f', 'DEVICE,TYPE', 'device', 'status').splitlines()
                   if line.endswith(':wifi') and line.rsplit(':', 1)[0] != ap_interface()]
        print('\nInterfaces WiFi disponiveis:')
        for i, device in enumerate(devices, 1):
            print(f'  [{i}] {safe(device)}')
        print('  [0] Voltar  [q] Sair')
        if not devices:
            print('Nenhuma interface WiFi encontrada.')
            return
        choice = answer('Interface: ')
        if choice == '0':
            return
        if not choice.isdecimal() or not 1 <= int(choice) <= len(devices):
            print('Opcao invalida')
            continue
        interface = devices[int(choice) - 1]
        while True:
            try:
                rows = scan(db, interface)
            except RuntimeError as exc:
                print(f'Falha no scan: {safe(str(exc))}')
                break
            print(f'\nRedes Wi-Fi - {safe(interface)}')
            for i, row in enumerate(rows, 1):
                print(f"  [{i}] {safe(row['SSID'] or '[oculto]')}  {row['BSSID']}  {safe(row.get('SECURITY', 'ABERTA'))}")
            print('  [r] Atualizar  [0] Voltar  [q] Sair')
            choice = answer('Rede: ')
            if choice == '0':
                break
            if choice.lower() == 'r':
                continue
            if not choice.isdecimal() or not 1 <= int(choice) <= len(rows):
                print('Opcao invalida')
                continue
            row = rows[int(choice) - 1]
            if '802.1X' in row.get('SECURITY', ''):
                print('WPA Enterprise requer um perfil NetworkManager configurado pelo administrador.')
                continue
            saved = db.execute('SELECT password FROM networks WHERE bssid=?', (row['BSSID'],)).fetchone()
            password, save = '', False
            secured = row.get('SECURITY', '') not in ('', '--', 'ABERTA')
            if secured:
                use_saved = answer('Usar senha salva? [s/N, 0 volta, q sai]: ').lower() if saved and saved[0] else 'n'
                if use_saved == '0':
                    continue
                if use_saved == 's':
                    password = saved[0]
                else:
                    password = getpass.getpass('Senha (ENTER cancela): ')
                    if not password:
                        continue
                    save_reply = answer('Salvar senha apos conectar? [s/N, 0 volta, q sai]: ').lower()
                    if save_reply == '0':
                        continue
                    save = save_reply == 's'
            decision = answer('Confirmar conexao? [s/N, 0 volta, q sai]: ')
            if decision.lower() != 's':
                continue
            args = ['device', 'wifi', 'connect', row['BSSID'], 'ifname', interface]
            if password:
                args += ['password', password]
            try:
                nmcli(*args)
                configure_backup_uplink(interface)
            except RuntimeError as exc:
                print(connection_error_message(exc))
                print('Senha anterior preservada.')
                continue
            if save:
                db.execute('UPDATE networks SET password=? WHERE bssid=?', (password, row['BSSID']))
                db.commit()
            print('Conectado com sucesso!')


def main():
    with database() as db:
        if sys.argv[1] == 'scan':
            print(f'Redes encontradas: {len(scan(db))}')
        elif sys.argv[1] == 'import-nm':
            import_nm(db, sys.argv[2] if len(sys.argv) > 2 else '/etc/NetworkManager/system-connections')
        elif sys.argv[1] == 'connect':
            connect(db)


if __name__ == '__main__':
    try:
        main()
    except (OSError, RuntimeError, sqlite3.Error, subprocess.TimeoutExpired, configparser.Error) as exc:
        print(f'Erro Wi-Fi: {safe(str(exc))}', file=sys.stderr)
        sys.exit(1)
    except (KeyboardInterrupt, EOFError):
        sys.exit(0)
