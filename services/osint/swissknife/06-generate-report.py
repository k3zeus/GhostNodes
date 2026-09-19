#!/usr/bin/env python3
"""Consolida os achados das fases 1-5 em report.md e report.html.
Somente biblioteca padrão. Uso: python3 06-generate-report.py <pasta_do_relatorio>
"""
import glob, sys, csv, html
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path

R = Path(sys.argv[1] if len(sys.argv) > 1 else ".")

PORT_RISK = {
    23:   (10, "CRÍTICO", "Telnet aberto (credenciais em claro)"),
    21:   (7,  "ALTO",    "FTP sem criptografia"),
    445:  (5,  "MÉDIO",   "SMB exposto na LAN"),
    139:  (4,  "MÉDIO",   "NetBIOS exposto"),
    80:   (3,  "MÉDIO",   "Web sem TLS"),
    8080: (3,  "MÉDIO",   "Painel web/admin sem TLS"),
    3389: (6,  "ALTO",    "RDP exposto na LAN"),
    5900: (7,  "ALTO",    "VNC exposto"),
    1900: (3,  "MÉDIO",   "UPnP/SSDP (superfície IoT)"),
}
OLD_OS = ["xp", "2000", "2003", "windows 7", "linux 2.6", "android 4", "android 5"]


def parse_nmap():
    hosts = []
    f = R / "deep.xml"
    if not f.exists():
        return hosts
    for h in ET.parse(f).getroot().iter('host'):
        ip = h.find("address[@addrtype='ipv4']")
        if ip is None:
            continue
        mac = h.find("address[@addrtype='mac']")
        om = h.find("./os/osmatch")
        ports = []
        for p in h.iter('port'):
            st = p.find('state')
            if st is None or st.get('state') != 'open':
                continue
            s = p.find('service')
            ports.append({
                'port': int(p.get('portid')), 'proto': p.get('protocol'),
                'svc': s.get('name') if s is not None else '',
                'prod': ((s.get('product') or '') + ' ' + (s.get('version') or '')).strip() if s is not None else '',
            })
        hosts.append({
            'ip': ip.get('addr'),
            'mac': mac.get('addr') if mac is not None else '-',
            'vendor': (mac.get('vendor') if mac is not None else None) or '-',
            'os': om.get('name') if om is not None else 'desconhecido',
            'ports': ports, 'score': 0, 'findings': [],
        })
    return hosts


def score_hosts(hosts):
    for h in hosts:
        for p in h['ports']:
            if p['port'] in PORT_RISK:
                s, sev, msg = PORT_RISK[p['port']]
                h['score'] += s
                h['findings'].append(f"[{sev}] {msg} (porta {p['port']})")
        osl = h['os'].lower()
        if any(k in osl for k in OLD_OS):
            h['score'] += 8
            h['findings'].append(f"[ALTO] SO possivelmente desatualizado: {h['os']}")
    return hosts


def parse_wifi():
    aps = []
    for f in glob.glob(str(R / "wifi*-01.csv")):
        rows = list(csv.reader(open(f, errors='ignore')))
        sec = None
        for row in rows:
            if not row:
                continue
            if row[0].strip() == 'BSSID':
                sec = 'ap'; continue
            if row[0].strip() == 'Station MAC':
                sec = 'st'; continue
            if sec == 'ap' and len(row) > 13 and row[0].strip():
                aps.append({'bssid': row[0].strip(), 'ch': row[3].strip(),
                            'priv': row[5].strip(), 'auth': row[7].strip(),
                            'pwr': row[8].strip(), 'essid': row[13].strip()})
    seen, out = set(), []
    for a in aps:
        if a['bssid'] in seen:
            continue
        seen.add(a['bssid']); out.append(a)
    return out


def wifi_risk(a):
    p = a['priv'].upper()
    if 'OPN' in p: return 10, "CRÍTICO", "Rede ABERTA"
    if 'WEP' in p: return 10, "CRÍTICO", "WEP (quebrável em minutos)"
    if 'WPA3' in p: return 0, "OK", "WPA3"
    if p.startswith('WPA ') or p == 'WPA': return 7, "ALTO", "WPA1 legado"
    if 'WPA2' in p: return 1, "INFO", "WPA2 (verifique força da senha e WPS)"
    return 2, "INFO", p or 'desconhecido'


def grade(total):
    return 'A' if total == 0 else 'B' if total < 10 else 'C' if total < 25 else 'D' if total < 45 else 'E'


def md_to_html(md_text: str) -> str:
    """Conversor Markdown -> HTML simples (stdlib), com tags sempre fechadas
    e tabelas reais — corrige o bug da versão anterior, que só fazia
    .replace('#', '<h1>') em cadeia e nunca fechava nada."""
    out, in_table, in_list = [], False, False
    for raw in md_text.split("\n"):
        line = raw.rstrip()
        is_table_row = line.strip().startswith("|")
        is_sep_row = is_table_row and set(line.replace("|", "").strip()) <= set("- :")

        if is_table_row and not is_sep_row:
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if not in_table:
                out.append("<table>"); in_table = True
                out.append("<tr>" + "".join(f"<th>{html.escape(c)}</th>" for c in cells) + "</tr>")
            else:
                out.append("<tr>" + "".join(f"<td>{html.escape(c)}</td>" for c in cells) + "</tr>")
            continue
        elif is_sep_row:
            continue
        elif in_table:
            out.append("</table>"); in_table = False

        if line.strip().startswith("- "):
            if not in_list:
                out.append("<ul>"); in_list = True
            out.append(f"<li>{html.escape(line.strip()[2:])}</li>")
            continue
        elif in_list:
            out.append("</ul>"); in_list = False

        if line.startswith("### "):
            out.append(f"<h3>{html.escape(line[4:])}</h3>")
        elif line.startswith("## "):
            out.append(f"<h2>{html.escape(line[3:])}</h2>")
        elif line.startswith("# "):
            out.append(f"<h1>{html.escape(line[2:])}</h1>")
        elif line.strip() == "":
            out.append("<br>")
        else:
            out.append(f"<p>{html.escape(line)}</p>")

    if in_table: out.append("</table>")
    if in_list: out.append("</ul>")
    return "\n".join(out)


hosts = score_hosts(parse_nmap())
wifis = parse_wifi()
wps_on = (R / 'wps.txt').exists() and (R / 'wps.txt').read_text(errors='ignore').strip()
total = sum(h['score'] for h in hosts) + sum(wifi_risk(w)[0] for w in wifis) + (7 if wps_on else 0)

md = [
    "# Relatório de Auditoria de Rede",
    f"Gerado em {datetime.now():%Y-%m-%d %H:%M} | Hardware: Orange Pi Zero 3 (H618, 1,5GB)",
    "",
    "## Resumo Executivo",
    f"- **Score de risco:** {total} | **Nota:** {grade(total)}",
    f"- Hosts vivos auditados: {len(hosts)} | APs visíveis: {len(wifis)}",
    f"- WPS ativo detectado: {'SIM (ALTO)' if wps_on else 'não'}",
    "",
    "## Redes Sem Fio Visíveis",
    "| SSID | BSSID | Canal | Criptografia | Auth | Risco |",
    "|---|---|---|---|---|---|",
]
for w in wifis:
    s, sev, msg = wifi_risk(w)
    md.append(f"| {w['essid'] or '(oculto)'} | {w['bssid']} | {w['ch']} | {w['priv']} | {w['auth']} | {sev}: {msg} |")

md.append("")
md.append("## Hosts da Rede")
for h in sorted(hosts, key=lambda x: -x['score']):
    md.append(f"### {h['ip']} — {h['vendor']}")
    md.append(f"MAC: `{h['mac']}` | SO provável: **{h['os']}** | Risco: {h['score']}")
    md.append("")
    md.append("| Porta | Proto | Serviço | Produto/Versão |")
    md.append("|---|---|---|---|")
    for p in h['ports']:
        md.append(f"| {p['port']} | {p['proto']} | {p['svc']} | {p['prod']} |")
    if h['findings']:
        md.append("")
        md.append("**Achados:**")
        md += [f"- {f}" for f in h['findings']]
    md.append("")

netbios = R / 'netbios.txt'
if netbios.exists() and netbios.read_text(errors='ignore').strip():
    md.append("## NetBIOS (nbtscan)")
    md.append("```")
    md.append(netbios.read_text(errors='ignore').strip())
    md.append("```")

p0f = R / 'p0f.log'
if p0f.exists():
    md.append("## Impressão Digital Passiva (p0f — trecho)")
    md.append("```")
    md += p0f.read_text(errors='ignore').splitlines()[:25]
    md.append("```")

md.append("## Anexos")
md.append("Capturas brutas, logs de sslscan/ssh-audit/whatweb e XML do nmap estão nesta pasta.")

md_text = "\n".join(md)
(R / 'report.md').write_text(md_text)

html_body = md_to_html(md_text)
html_doc = f"""<!DOCTYPE html>
<html><head><meta charset="utf-8">
<title>Relatório de Auditoria de Rede</title>
<style>
body{{font-family:sans-serif;max-width:960px;margin:2rem auto;padding:0 1rem;line-height:1.5}}
table{{border-collapse:collapse;width:100%;margin:0.5rem 0}}
th,td{{border:1px solid #ccc;padding:4px 8px;text-align:left;font-size:0.9rem}}
th{{background:#eee}}
h1,h2,h3{{margin-top:1.2em}}
code,pre{{background:#f5f5f5}}
</style></head>
<body>{html_body}</body></html>"""
(R / 'report.html').write_text(html_doc)

print(f"[+] report.md / report.html gerados em {R} | score={total} nota={grade(total)}")
