#!/usr/bin/env bash
# Beat 3 — The obvious thing fails. With no IPv4 identity on the wire, the ping
# doesn't even use the wire: the routing table can't see the link as a path, so
# the packet leaves via your only other route (the management Wi-Fi on the Pis)
# and dies. Connectivity is not reachability.
set -uo pipefail
IFACE="${IFACE:-eth0}"
PEER_IP="${PEER_IP:-10.10.0.2}"

echo "--- ip -4 addr show $IFACE  (expect: no 'inet' line) ---"
ip -4 addr show "$IFACE"
echo
echo "--- ip route get $PEER_IP  (the smoking gun: which 'dev'?) ---"
ip route get "$PEER_IP" || true
echo
echo "--- ping -c1 $PEER_IP  (expect failure) ---"
ping -c1 -W1 "$PEER_IP" || true
echo
echo ">>> The point: $IFACE has no L3 identity, so the kernel can't see the wire"
echo ">>> as a way to reach $PEER_IP. On a Pi the ping leaks out the default"
echo ">>> route (wlan0) and never touches the cable."
