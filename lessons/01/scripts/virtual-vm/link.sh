#!/usr/bin/env bash
# Seat or unseat the virtual cable on a node — the Layer 1 beat the namespace lab
# can't do. This drives the NIC's carrier over QEMU's QMP control socket, exactly
# the bit a real PHY drops when you pull the plug. The guest kernel sees a genuine
# link-change event: eth0 flips between LOWER_UP and NO-CARRIER.
#
#   ./link.sh a off     # drop pi-a's eth0 carrier
#   ./link.sh a on      # restore it
set -euo pipefail
cd "$(dirname "$0")"
source ./common.sh

node="${1:-}"; state="${2:-}"
case "$node" in a|b) ;; *) echo "usage: ./link.sh <a|b> <on|off>" >&2; exit 1;; esac
case "$state" in on) up=true;; off) up=false;; *) echo "usage: ./link.sh <a|b> <on|off>" >&2; exit 1;; esac

sock="$LAB_HOME/pi-$node.qmp"
[ -S "$sock" ] || { echo "no QMP socket for pi-$node — is the lab up?" >&2; exit 1; }

python3 - "$sock" "$up" <<'PY'
import socket, sys, json
sock, up = sys.argv[1], sys.argv[2] == "true"
s = socket.socket(socket.AF_UNIX); s.connect(sock)
s.recv(65536)                                             # QMP greeting
s.sendall(b'{"execute":"qmp_capabilities"}\n'); s.recv(65536)
# The NIC's control name can be either the -device id or the netdev id depending
# on the QEMU build, so try both and report whichever the monitor accepts.
for name in ("cable", "wire"):
    s.sendall((json.dumps({"execute": "set_link",
                           "arguments": {"name": name, "up": up}}) + "\n").encode())
    resp = s.recv(65536).decode()
    if '"error"' not in resp:
        print(f"cable {'seated (carrier up)' if up else 'unseated (carrier down)'}  [{name}]")
        break
else:
    print("set_link failed:\n" + resp, file=sys.stderr); sys.exit(1)
PY
