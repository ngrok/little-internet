#!/usr/bin/env bash
# Where did that packet go? The ping from the last step failed because eth0 has no
# IPv4 identity, so the routing table can't see the wire as a path to the peer.
source "$(dirname "$0")/lib.sh"

note <<'EOF'
You just watched a ping drop on a live, chattering wire. So where did that packet
actually go? Follow it. With no IPv4 identity on eth0, the routing table can't see
the wire as a way to reach anything, so the packet goes elsewhere—on a Pi, out the
only other route it has (the management Wi-Fi), where it dies; in the bare lab,
nowhere at all ("Network is unreachable"). The wire was never the problem.
Identity was.
EOF

eye <<'EOF'
"ip -4 addr show eth0" has no inet line—the wire has no IPv4 identity
"ip route get 10.10.0.2" does NOT resolve to dev eth0 (on a Pi it picks dev wlan0)
that mismatch is the whole story: a wire with no identity is invisible to routing
EOF

pause "Press Enter to check pi-a's address and trace where the packet would go."

node_a "$STYLE"'
h "ip -4 addr show eth0  (expect no inet line)"; ip -4 addr show eth0
h "ip route get 10.10.0.2  (which dev?)"; ip route get 10.10.0.2 || true'
