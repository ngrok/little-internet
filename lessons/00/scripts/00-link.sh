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

if [ "$MODE" = vm ]; then
  LINK="$(dirname "$0")/virtual-vm/link.sh"
  note <<'EOF'
Layer 1 on the VM lab: a virtio NIC has no PHY, so there's no Speed or Duplex to
read, but its carrier is real and QEMU controls it. The lab starts with the cable
unseated, so pi-a's eth0 is a dead wire. Seat it and watch the link come alive:
NO-CARRIER to LOWER_UP, the transition a physical cable shows. This is the one beat
the namespace lab can't do at all.
EOF
  PROBE="$STYLE"'
h "ip link show eth0"; ip link show eth0
h "carrier (1 up, 0 down)"; cat /sys/class/net/eth0/carrier 2>/dev/null || echo "(down)"'
  pause "The cable is unseated. Press Enter to read pi-a's link (expect NO-CARRIER, carrier 0)."
  node_a "$PROBE"
  pause "Now seat the cable. Press Enter (runs link.sh a on)."
  "$LINK" a on
  sleep 2
  node_a "$PROBE"
  eye <<'EOF'
carrier 0 -> 1, and eth0 flips NO-CARRIER -> LOWER_UP
no Speed, Duplex, or autonegotiation: a virtio NIC has no PHY, only the carrier is real
EOF
  pause "Press Enter when you've had a look."
  exit 0
fi

note <<'EOF'
First question, before anything fancy: Is there even a wire? You'll read pi-a's
lowest layer twice. When unplugged, it's dead. Seat the cable on both ends, look 
again, and notice you never configure a thing: a wire either has a heartbeat or 
it doesn't.
EOF

PROBE="$STYLE"'
h "ip link show eth0"; ip link show eth0
h "ethtool eth0"; ethtool eth0'

pause "UNPLUG the cable on pi-a, then press Enter (expect NO-CARRIER)."
node_a "$PROBE"
pause "Now seat the cable on BOTH ends, wait ~3s, then press Enter (expect LOWER_UP)."
node_a "$PROBE"

eye <<'EOF'
NO-CARRIER -> LOWER_UP, and "Link detected: no -> yes"
Speed/Duplex flipping from Unknown! to 100Mb/s / Full
a "Link partner advertised" block shows up after link-up—autonegotiation, made visible
EOF

pause "Press Enter when you've had a look."
