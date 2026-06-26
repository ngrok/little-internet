#!/usr/bin/env bash
# Watch ARP make the introduction. Ping the peer (it works now that both nodes have
# addresses), then flush the cache and run it again in slow motion to catch the
# who-has/is-at that had to happen before the first echo could leave.
source "$(dirname "$0")/lib.sh"

note <<'EOF'
You gave both nodes an identity. So does the ping finally work? Try the very same
command that flopped before you had addresses.
EOF

pause "Press Enter to ping pi-b again."

node_a "$STYLE"'
h "ping -c2 10.10.0.2"
ping -c2 10.10.0.2 || true'

note <<'EOF'
There it is—a reply, after all that. But how? You typed an IP address, and the wire
only carries MAC addresses. Something had to bridge the two in the half-millisecond
before that first echo went out, and you never saw it. Flush pi-a's memory of its
neighbor and run the ping again, this time in slow motion.
EOF

eye <<'EOF'
who-has 10.10.0.2 tell 10.10.0.1   pi-a shouts to the whole room (ff:ff:ff:ff:ff:ff)
10.10.0.2 is-at <mac>              one device raises its hand
THEN the ICMP echo request, and its reply
seq 2 skips ARP entirely—pi-a remembers now (the cache is REACHABLE)
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
  tshark -n -r /tmp/first-arp.pcap 2>/dev/null
else
  echo "(tshark not found—showing tcpdump; frame length first, trailing length is the L2 payload)"
  tcpdump -n -e -t -r /tmp/first-arp.pcap 2>/dev/null
fi'
