#!/usr/bin/env bash
# Beat 4 (the star) — Watch ARP make the introduction. Flush the neighbor cache,
# ping once, and capture the who-has / is-at exchange that has to happen before
# the ICMP echo can land. Run on pi-a after BOTH nodes have addresses.
#
# In the capture you're looking for:
#   1. who-has PEER? tell SELF   (broadcast to ff:ff:ff:ff:ff:ff)
#   2. PEER is-at <mac>          (unicast answer)
#   3. THEN the ICMP echo request, and its reply
#   4. seq 2 skips ARP entirely — the cache is now REACHABLE
set -uo pipefail
IFACE="${IFACE:-eth0}"
PEER_IP="${PEER_IP:-10.10.0.2}"
OUT="${OUT:-$HOME/cap/first-arp_$(hostname).pcap}"
mkdir -p "$(dirname "$OUT")"

echo ">>> Neighbor cache before:"
ip neigh show dev "$IFACE" || true
echo
echo ">>> Flushing cache, then capturing arp+icmp while we ping twice..."
sudo ip neigh flush dev "$IFACE"
sudo tcpdump -i "$IFACE" -n -e "arp or icmp" -w "$OUT" 2>/dev/null &
TCPDUMP_PID=$!
sleep 1
ping -c2 "$PEER_IP" || true
sleep 1
sudo kill "$TCPDUMP_PID" 2>/dev/null || true
wait "$TCPDUMP_PID" 2>/dev/null || true
echo
echo ">>> Neighbor cache after (expect $PEER_IP ... REACHABLE):"
ip neigh show dev "$IFACE"
echo
echo ">>> The exchange, frame by frame:"
sudo tcpdump -n -e -t -r "$OUT" 2>/dev/null || true
echo
echo ">>> Capture saved to $OUT"
