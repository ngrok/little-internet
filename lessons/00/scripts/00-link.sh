#!/usr/bin/env bash
# Beat 1 — Is there even a wire? Layer 1, before and after you seat the cable.
#
# HARDWARE ONLY. A virtual veth pair has no PHY, so there is no carrier
# handshake, no autonegotiation, and no Speed/Duplex to read. Layer 1 is the
# one layer you have to feel on real hardware.
#
# Run this twice: once with the cable UNPLUGGED, once a few seconds AFTER you
# seat it on both ends.
set -uo pipefail
IFACE="${IFACE:-eth0}"

echo ">>> Layer 1 status for $IFACE."
echo ">>> Watch the before/after for: NO-CARRIER -> LOWER_UP, 'Link detected:"
echo ">>> no -> yes', and Speed/Duplex flipping from Unknown! to 100Mb/s / Full."
echo ">>> After link-up, a 'Link partner advertised' block appears: autoneg made"
echo ">>> visible. Carrier needs BOTH ends powered and seated."
echo
echo "--- ip link show $IFACE ---"
ip link show "$IFACE"
echo
echo "--- ethtool $IFACE ---"
sudo ethtool "$IFACE"
