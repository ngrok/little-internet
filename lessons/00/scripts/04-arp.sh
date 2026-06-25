#!/usr/bin/env bash
# Watch ARP make the introduction. Flush pi-a's neighbor
# cache, ping the peer twice, and capture the exchange.
source "$(dirname "$0")/lib.sh"

note <<'EOF'
Ping again. It works now—but that's not the interesting part. Rewind to the
half-millisecond before the first echo even left the wire. You typed an IP address;
the wire only carries MAC addresses. Something had to translate one into the other,
and you never saw it. Flush pi-a's memory, ping, and catch it in the act: pi-a
shouting into the room, a stranger shouting back. That's ARP—the introduction that
had to happen before any of this could work.
EOF

eye <<'EOF'
who-has 10.10.0.2 tell 10.10.0.1   pi-a shouts to the whole room (ff:ff:ff:ff:ff:ff)
10.10.0.2 is-at <mac>              one device raises its hand
THEN the ICMP echo request, and its reply
seq 2 skips ARP entirely—pi-a remembers now (the cache is REACHABLE)
EOF

pause "Press Enter to flush the cache, ping, and capture the ARP exchange."

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
