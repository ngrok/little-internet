#!/usr/bin/env bash
# Beat 4 (setup) — Give the wire an identity. Run on EACH node, with its own IP:
#   SELF_IP=10.10.0.1 ./03-address.sh   # on pi-a
#   SELF_IP=10.10.0.2 ./03-address.sh   # on pi-b
#
# Uses NetworkManager (the Pi image runs it). ipv4.never-default keeps this lab
# link out of the default route; ipv6.method link-local leaves the fe80:: alone.
set -euo pipefail
IFACE="${IFACE:-eth0}"
SELF_IP="${SELF_IP:-10.10.0.1}"

echo ">>> Assigning $SELF_IP/24 to $IFACE via NetworkManager (manual, lab-only)."
sudo nmcli connection add type ethernet ifname "$IFACE" con-name eth \
  ipv4.method manual ipv4.addresses "$SELF_IP/24" \
  ipv4.never-default yes ipv6.method link-local connection.autoconnect yes
sudo nmcli connection up eth
echo
echo "--- ip route get the peer now resolves to $IFACE ---"
echo ">>> Re-run 02-no-address.sh: 'ip route get' now points at $IFACE instead of"
echo ">>> wlan0. Giving the wire an identity made it visible to the routing table."
