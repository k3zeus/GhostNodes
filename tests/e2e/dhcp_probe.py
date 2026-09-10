#!/usr/bin/env python3
"""Hardware test: DHCP exchange on an authorized spare Wi-Fi NIC, no IP/route edits."""
import ipaddress
import os
from pathlib import Path
import socket
import struct
import sys
import time


def checksum(data):
    if len(data) % 2:
        data += b'\0'
    total = sum(struct.unpack('!' + 'H' * (len(data) // 2), data))
    while total >> 16:
        total = (total & 65535) + (total >> 16)
    return (~total) & 65535


def probe(interface):
    mac = bytes.fromhex(Path('/sys/class/net', interface, 'address').read_text().strip().replace(':', ''))
    xid = os.urandom(4)
    with socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(0x0800)) as sock:
        sock.bind((interface, 0))
        sock.settimeout(2)

        def send(kind, requested=None, server=None):
            options = b'\x35\x01' + bytes([kind]) + b'\x3d\x07\x01' + mac
            if requested:
                options += b'\x32\x04' + requested + b'\x36\x04' + server
            options += b'\x37\x03\x01\x03\x06\xff'
            bootp = b'\x01\x01\x06\x00' + xid + b'\x00\x00\x80\x00' + b'\0' * 16 + mac + b'\0' * 10 + b'\0' * 192
            payload = bootp + b'\x63\x82\x53\x63' + options
            udp = struct.pack('!HHHH', 68, 67, 8 + len(payload), 0) + payload
            ip = struct.pack('!BBHHHBBH4s4s', 0x45, 0, 20 + len(udp), 0, 0, 64, 17, 0, b'\0'*4, b'\xff'*4)
            ip = ip[:10] + struct.pack('!H', checksum(ip)) + ip[12:]
            sock.send(b'\xff'*6 + mac + b'\x08\x00' + ip + udp)

        def receive(kind):
            deadline = time.monotonic() + 8
            while time.monotonic() < deadline:
                try:
                    packet = sock.recv(4096)
                except TimeoutError:
                    continue
                offset = 14 + (packet[14] & 15) * 4
                if len(packet) < offset + 8 + 240 or packet[23] != 17:
                    continue
                if packet[offset:offset+4] != b'\x00\x43\x00\x44':
                    continue
                data = packet[offset+8:]
                if data[4:8] != xid or data[28:34] != mac:
                    continue
                options, i = {}, 240
                while i < len(data):
                    code = data[i]; i += 1
                    if code == 255:
                        break
                    if code == 0:
                        continue
                    if i >= len(data):
                        break
                    length = data[i]; i += 1
                    options[code] = data[i:i+length]; i += length
                if options.get(53) == bytes([kind]):
                    return data[16:20], options
            raise TimeoutError('DHCP response not received')

        for attempt in range(3):
            try:
                send(1)
                offered, options = receive(2)
                server = options[54]
                send(3, offered, server)
                address, options = receive(5)
                router = options.get(3, b'')[:4]
                print('DHCPACK address=' + str(ipaddress.IPv4Address(address)) +
                      ' router=' + str(ipaddress.IPv4Address(router)))
                if ipaddress.IPv4Address(address) not in ipaddress.IPv4Network('10.21.21.0/24'):
                    raise RuntimeError('Unexpected subnet')
                if router != ipaddress.IPv4Address('10.21.21.1').packed:
                    raise RuntimeError('Unexpected gateway')
                return
            except TimeoutError:
                if attempt == 2:
                    raise


if __name__ == '__main__':
    if len(sys.argv) != 2 or sys.argv[1] != 'wlan1':
        raise SystemExit('Hardware probe is restricted to the explicitly selected spare wlan1')
    probe(sys.argv[1])
