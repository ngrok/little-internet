#!/usr/bin/env bash
# Watch ARP make the introduction. Ping the peer (it works now that both nodes have
# addresses), then flush the cache and run it again in slow motion to catch the
# who-has/is-at that had to happen before the first echo could leave.
source "$(dirname "$0")/lib.sh"

note <<'EOF'
Both nodes now have IPv4 addresses. Try the same ping that failed before
you assigned them.
EOF

pause "Press Enter to ping pi-b again."

node_a "$STYLE"'
h "ping -c2 10.10.0.2"
ping -c2 10.10.0.2 || true'

note <<'EOF'
Look for an echo reply. It shows the peer is reachable by its IPv4 address.
Ethernet also needs a destination MAC address. Clear pi-a's neighbor cache
and repeat the ping with a capture running to see how ARP finds that MAC.
EOF

pause "Press Enter to flush the cache and capture the introduction."

node_a "$STYLE"'
h "neighbor cache before"; ip neigh show dev eth0
ip neigh flush dev eth0
rm -f /tmp/first-arp.pcap
tcpdump -i eth0 -n -e -U "arp or icmp" -w /tmp/first-arp.pcap 2>/dev/null & CAP=$!
sleep 1; ping -c2 10.10.0.2 || true; sleep 2
kill -INT $CAP 2>/dev/null; wait $CAP 2>/dev/null
h "neighbor cache after (expect 10.10.0.2 ... REACHABLE)"; ip neigh show dev eth0
h "the exchange, frame by frame"
if command -v tshark >/dev/null 2>&1; then
  # COLORTERM inline: the ssh transport runs this via non-login sudo bash, which
  # never sources /etc/profile.d, so tshark --color stays blank without it.
  COLORTERM=truecolor tshark -n -r /tmp/first-arp.pcap --color 2>/dev/null
else
  echo "(tshark not found—showing tcpdump; frame length first, trailing length is the L2 payload)"
  tcpdump -n -e -t -r /tmp/first-arp.pcap 2>/dev/null
fi'

eye <<'EOF'
"Who has 10.10.0.2?" goes to the broadcast destination ff:ff:ff:ff:ff:ff.
The "is at" reply supplies the peer's MAC address.
Follow those rows to the ICMP echo request and reply.
Compare seq 2: it can reuse the cached MAC without another ARP lookup.
EOF

pause "Press Enter when you've had a look."

note <<'EOF'
The link came up, frames crossed it, and assigning IPv4 addresses gave the
nodes a route to each other. ARP supplied the MAC address needed to deliver
the first ping. Each part answered a different piece of "can they talk?"

With two nodes on one cable, a broadcast has only one neighbor to reach.
Add a third node and a switch, and the distinction matters: a broadcast
reaches everyone, while a known unicast destination belongs on one port.
In lesson 02, test what the switch does and who assigns IPv4 addresses.
EOF
