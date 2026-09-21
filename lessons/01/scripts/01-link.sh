#!/usr/bin/env bash
# Is there even a wire? Layer 1, before and after you seat the cable.
#
# Hardware shows physical negotiation; the VM lab shows QEMU carrier events.
# The namespace lab skips this step because it has no cable control.
source "$(dirname "$0")/lib.sh"

if [ "$MODE" = netns ]; then
  note <<'EOF'
The namespace lab has no cable control or physical Ethernet transceiver (PHY).
Use the VM lab for carrier events or hardware for speed negotiation.
EOF
  exit 0
fi

if [ "$MODE" = vm ]; then
  LINK="$(dirname "$0")/virtual-vm/link.sh"
  note <<'EOF'
QEMU controls this virtual interface's carrier state. There is no physical
Ethernet transceiver (PHY), so speed and duplex aren't negotiated.
The lab starts with the virtual cable disconnected. Connect it and look for
NO-CARRIER to change to LOWER_UP on pi-a's eth0.
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
QEMU changed the carrier state; the virtual interface has no physical speed negotiation
EOF
  pause "Press Enter when you've had a look."
  exit 0
fi

note <<'EOF'
Read pi-a's link state with the cable unplugged, then with both ends connected.
Watch the carrier, speed, and duplex fields. The Ethernet hardware negotiates
the link before you assign an IP address.
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
