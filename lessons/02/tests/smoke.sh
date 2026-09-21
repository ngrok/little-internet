#!/usr/bin/env bash
# Development integration test, deliberately destructive only to lesson 02 VM
# state. Start the VMs before invoking; they stay up for inspection afterward.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$HERE/../scripts"
source "$SCRIPTS/virtual-vm/common.sh"
export LESSON_AUTO=1 NO_COLOR=1
"$SCRIPTS/reset.sh"
"$SCRIPTS/run.sh" --auto
for n in a b; do
  case "$n" in a) expected=10.10.0.1;; b) expected=10.10.0.2;; esac
  node_ssh "$n" "set -e
    ip -4 -o addr show dev eth0 | grep -F '$expected/24'
    test -z \"\$(ip route show default dev eth0)\"
    sudo nmcli -g ipv4.method connection show eth-dhcp | grep -x auto"
  node_ssh "$n" 'python3 -' <<'PY'
from pathlib import Path
import subprocess

def rows(beat):
    capture = sorted(Path('/home/pi/cap').glob(beat + '-*.pcap'))[-1]
    data = subprocess.check_output(['tshark', '-n', '-r', str(capture), '-Y', 'dhcp',
        '-T', 'fields', '-e', 'dhcp.id', '-e', 'dhcp.option.dhcp',
        '-e', 'dhcp.option.requested_ip_address', '-e', 'dhcp.ip.your'], text=True)
    return [line.split('\t') for line in data.splitlines()]

switch_rows = rows('switch')
assert any(kind == '1' for xid, kind, pref, offered in switch_rows), switch_rows
assert not any(kind in ('2', '5') for xid, kind, pref, offered in switch_rows), switch_rows
for beat in ('dora', 'preference', 'reconnect'):
    transactions = {}
    for xid, kind, preferred, offered in rows(beat):
        transactions.setdefault(xid, set()).add(kind)
    assert any({'1', '2', '3', '5'} <= kinds for kinds in transactions.values()), (beat, transactions)
assert any(kind == '1' and pref in ('10.10.0.1', '10.10.0.2')
           for xid, kind, pref, offered in rows('preference'))
for beat in ('manual', 'ping', 'reconnect'):
    capture = sorted(Path('/home/pi/cap').glob(beat + '-*.pcap'))[-1]
    replies = subprocess.check_output(['tshark', '-n', '-r', str(capture),
        '-Y', 'icmp.type == 0', '-T', 'fields', '-e', 'icmp.seq'], text=True)
    assert {'1', '2'} <= set(replies.splitlines()), (beat, replies)
print('PASS: DORA, Discover preference, and both ping replies in real captures')
PY
done
node_ssh dhcp 'sudo cat /var/lib/misc/dnsmasq.leases'
echo 'PASS: lesson 02 integration smoke test'
