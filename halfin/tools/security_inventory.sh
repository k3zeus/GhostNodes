#!/usr/bin/env bash
set -euo pipefail
# Coleta local: ss -lntup; systemctl --failed; fail2ban-client; ufw status.
ROOT=/var/lib/ghostnodes/security
mkdir -p -m 0700 "$ROOT/history"
python3 - "$ROOT" <<'PY'
import datetime,json,os,subprocess,sys
root=sys.argv[1]
def cmd(*a):
 try:return subprocess.run(a,text=True,capture_output=True,timeout=20).stdout.strip()
 except Exception as e:return f'error: {e}'
def unit(n): return cmd('systemctl','is-active',n)
data={'generated_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'scope':'local defensive inventory only','hostname':cmd('hostnamectl','--static'),'kernel':cmd('uname','-r'),'os_release':open('/etc/os-release').read() if os.path.exists('/etc/os-release') else '', 'listeners':cmd('ss','-lntup'),'interfaces':cmd('ip','-j','addr'),'failed_units':cmd('systemctl','--failed','--no-legend'),'ssh_effective':cmd('sshd','-T'),'fail2ban_sshd':cmd('fail2ban-client','status','sshd'),'ufw':cmd('ufw','status'),'updates':cmd('apt','list','--upgradable'),'services':cmd('systemctl','list-units','--type=service','--state=running','--no-legend')}
stamp=datetime.datetime.now().strftime('%Y%m%dT%H%M%S')
for path in (os.path.join(root,'latest.json'),os.path.join(root,'history',stamp+'.json')):
 with open(path,'w') as f: json.dump(data,f,indent=2,sort_keys=True)
 os.chmod(path,0o600)
PY
cat > /etc/systemd/system/halfin-security-inventory.service <<EOF
[Unit]
Description=Halfin local defensive inventory
[Service]
Type=oneshot
ExecStart=$0
EOF
cat > /etc/systemd/system/halfin-security-inventory.timer <<'EOF'
[Unit]
Description=Daily Halfin local defensive inventory
[Timer]
OnCalendar=daily
Persistent=true
[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now halfin-security-inventory.timer
echo "Inventário atualizado em $ROOT/latest.json"
