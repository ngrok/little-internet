#!/usr/bin/env bash
# The obvious thing fails. With no IPv4 identity on the wire, the
# routing table can't see the link as a path to the peer.
source "$(dirname "$0")/lib.sh"

note <<'EOF'
The wire's alive and frames are flowing both ways, so ping 10.10.0.2 obviously
works. Try it. ...No dice. So where did the packet actually go? Trace it with
"ip route get": it never touched the cable. With no IPv4 identity on eth0, the
routing table can't see the wire as a way to reach anything, so the packet goes
elsewhere. On a Pi it slips out the only other route, the management Wi-Fi, and
dies out there; in the bare lab there's simply nowhere to send it ("Network is
unreachable"). The wire was never the problem. Identity was.
EOF

eye <<'EOF'
"ip -4 addr show eth0" has no inet line—the wire has no IPv4 identity
"ip route get" does NOT resolve to dev eth0 (on a Pi it picks dev wlan0, the mgmt route)
the ping fails—with no identity on the wire, the packet never even touches it
EOF

pause "Press Enter to check pi-a's address, route to the peer, and ping."

node_a "$STYLE"'
h "ip -4 addr show eth0  (expect no inet line)"; ip -4 addr show eth0
h "ip route get 10.10.0.2  (which dev?)"; ip route get 10.10.0.2 || true
h "ping -c1 10.10.0.2  (expect failure)"; ping -c1 -W1 10.10.0.2 || true'
