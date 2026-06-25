#!/usr/bin/env bash
# Is there even a wire? Layer 1, before and after you seat the cable.
#
# HARDWARE ONLY. A virtual veth pair has no PHY, so there is no carrier
# handshake, no autonegotiation, and no Speed/Duplex to read. Layer 1 is the one
# layer you have to feel on real hardware.
source "$(dirname "$0")/lib.sh"

if [ "$MODE" = netns ]; then
  note <<'EOF'
Layer 1 is hardware-only—a veth has no PHY, so there's nothing to show here.
EOF
  exit 0
fi

note <<'EOF'
First question, before anything fancy: is there even a wire? You'll read pi-a's
lowest layer twice. Unplugged, it's dead—no carrier, nobody home. Seat the cable on
both ends and look again. Notice you never configure a thing: a wire either has a
heartbeat or it doesn't.
EOF

eye <<'EOF'
NO-CARRIER -> LOWER_UP, and "Link detected: no -> yes"
Speed/Duplex flipping from Unknown! to 100Mb/s / Full
a "Link partner advertised" block shows up after link-up—autonegotiation, made visible
EOF

PROBE="$STYLE"'
h "ip link show eth0"; ip link show eth0
h "ethtool eth0"; ethtool eth0'

pause "UNPLUG the cable on pi-a, then press Enter (expect NO-CARRIER)."
node_a "$PROBE"
pause "Now seat the cable on BOTH ends, wait ~3s, then press Enter (expect LOWER_UP)."
node_a "$PROBE"
