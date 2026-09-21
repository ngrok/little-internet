#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
case "${1:-}" in a|b|dhcp) ;; *) echo 'usage: link.sh <a|b|dhcp> <on|off>' >&2; exit 2;; esac
case "${2:-}" in on|off) ;; *) echo 'usage: link.sh <a|b|dhcp> <on|off>' >&2; exit 2;; esac
python3 - "$LAB_HOME/pi-$1.qmp" "$2" <<'PY'
import json, socket, sys
with socket.socket(socket.AF_UNIX) as sock:
    sock.settimeout(5)
    sock.connect(sys.argv[1])
    stream = sock.makefile('rwb')
    json.loads(stream.readline())  # greeting
    for command in ({'execute': 'qmp_capabilities', 'id': 'caps'},
                    {'execute': 'set_link', 'id': 'link',
                     'arguments': {'name': 'cable', 'up': sys.argv[2] == 'on'}}):
        stream.write((json.dumps(command) + '\n').encode())
        stream.flush()
        while True:
            response = json.loads(stream.readline())
            if response.get('id') == command['id']:
                if 'error' in response:
                    raise SystemExit(response['error'])
                break
print('eth0 carrier ' + sys.argv[2])
PY
