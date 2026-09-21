#!/usr/bin/env bash
# Where did that packet go? The ping from the last step failed because eth0 has no
# IPv4 identity, so the routing table can't see the wire as a path to the peer.
source "$(dirname "$0")/lib.sh"

note <<'EOF'
Inspect eth0's IPv4 address and the route to 10.10.0.2. In this starting state,
eth0 has no address or connected IPv4 route for the peer.

A Pi may try its management Wi-Fi route; a VM may try its management interface.
The namespace lab has no other route, so it reports "Network is unreachable."
The output tells you which path your node chose.
EOF

pause "Press Enter to check pi-a's address and trace where the packet would go."

node_a "$STYLE"'
h "ip -4 addr show eth0  (expect no inet line)"; ip -4 addr show eth0
h "ip route get 10.10.0.2  (which dev?)"; ip route get 10.10.0.2 || true'

eye <<'EOF'
No inet line means eth0 has no IPv4 address.
Check the dev field in the route: does it name eth0, wlan0, or mgmt?
An unreachable error means the kernel has no route to that destination.
EOF

pause "Press Enter when you've had a look."
