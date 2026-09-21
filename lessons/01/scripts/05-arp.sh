#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
begin '05 — How does IPv4 find the Ethernet destination?' \
  'Both nodes have IPv4 addresses and a route over eth0. Test the ping again,
then inspect how the sender finds the peer’s Ethernet address.'
pause 'Will the same destination answer now that both ends have addresses?'
node a 'ping -I eth0 -c2 -W2 10.10.0.2'
note 'The ping received a reply. The peer is reachable over eth0 using its
IPv4 address. Ethernet also needs a destination MAC address. Clear the
neighbor cache and record another ping to watch that lookup happen.'
pause 'Check the received count and packet loss. Ready to record the lookup?'
node a 'ip neigh show dev eth0'
CAPTURE="/tmp/little-internet-01-$RUN_ID-arp.pcap"
h '[pi-a] $ ping -I eth0 -c2 -W2 10.10.0.2 (recording ARP and ICMP)'
node_a "ip neigh flush dev eth0
tcpdump -i eth0 -n -e -U 'arp or icmp' -w '$CAPTURE' 2>'$CAPTURE.log' & CAP=\$!
trap 'kill -INT \$CAP 2>/dev/null || true' EXIT
sleep 1
if ! kill -0 \$CAP 2>/dev/null; then cat '$CAPTURE.log' >&2; exit 1; fi
ping -I eth0 -c2 -W2 10.10.0.2
sleep 2
kill -INT \$CAP
wait \$CAP || true
trap - EXIT
chmod a+r '$CAPTURE'"
note 'ARP, the Address Resolution Protocol, maps an IPv4 address to a MAC.
Look for “Who has 10.10.0.2?” sent to ff:ff:ff:ff:ff:ff (everyone),
then the “is at” reply. ICMP Echo rows are the ping requests and replies.'
pause 'Which packet supplies the MAC before the first Echo request?'
capture_show "$CAPTURE" arp
pause 'What MAC is in the reply? Does seq=2 need another lookup?'
eye 'The “is at” reply supplies the peer’s MAC. The first Echo can then use
that Ethernet destination. The second can reuse the cached mapping;
its timing also depends on scheduling, so it is not always faster.'
pause 'Did pi-a keep the mapping? Compare the cache with the ARP reply.'
node a 'ip neigh show dev eth0'
finish 'What did the link, IPv4 addresses, and ARP each contribute to the ping?' \
  'The link carried frames. Assigning IPv4 addresses created a route over
eth0. ARP supplied the peer’s MAC so Ethernet could deliver the ping.
Next, lesson 02 adds a switch and asks who can assign addresses for you.' \
  'Continue with lesson 02: lessons/02/README.md'
