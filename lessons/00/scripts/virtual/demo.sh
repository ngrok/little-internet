#!/usr/bin/env bash
# Run beats 3 and 4 across the namespace lab in one shot. Assumes lab-up.sh has
# already built pi-a <--veth--> pi-b. Run as root on the host.
#
# Beats 2 (link-up chatter) and 1 (Layer 1) are not driven here: see the README
# for why the L1 beat has nothing to show on a veth, and how to watch the (thinner)
# zero-config burst yourself.
set -uo pipefail
A="${A:-pi-a}"
B="${B:-pi-b}"
nx() { ip netns exec "$@"; }

echo "=== Beat 3 — ping with no identity (blank wire) ==="
echo "--- pi-a: ip -4 addr show eth0 (expect no inet) ---"
nx "$A" ip -4 addr show eth0
echo "--- pi-a: ip route get 10.10.0.2 ---"
nx "$A" ip route get 10.10.0.2 2>&1 || true
echo "--- pi-a: ping -c1 10.10.0.2 (expect failure) ---"
nx "$A" ping -c1 -W1 10.10.0.2 2>&1 || true

echo
echo "=== Beat 4 setup — give each node an identity ==="
nx "$A" ip addr add 10.10.0.1/24 dev eth0
nx "$B" ip addr add 10.10.0.2/24 dev eth0
echo "--- pi-a: ip route get 10.10.0.2 now points at eth0 ---"
nx "$A" ip route get 10.10.0.2

echo
echo "=== Beat 4 — ARP makes the introduction ==="
nx "$A" ip neigh flush dev eth0
nx "$A" tcpdump -i eth0 -n -e "arp or icmp" -w /tmp/first-arp.pcap 2>/dev/null &
CAP=$!
sleep 1
nx "$A" ping -c2 10.10.0.2 || true
sleep 1
kill "$CAP" 2>/dev/null || true
wait "$CAP" 2>/dev/null || true
echo "--- pi-a: neighbor cache after (expect 10.10.0.2 ... REACHABLE) ---"
nx "$A" ip neigh show dev eth0
echo "--- the captured exchange, frame by frame ---"
tcpdump -n -e -t -r /tmp/first-arp.pcap 2>/dev/null || true
