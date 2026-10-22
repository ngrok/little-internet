#!/usr/bin/env bash
# Hardware shows physical negotiation; the VM lab shows QEMU carrier events.
source "$(dirname "$0")/lib.sh"
begin '01 — Is there a live link?' \
  'Start with the Ethernet link. Inspect its state before and after connection,
before assigning either machine an IPv4 address.'

if [ "$MODE" = netns ]; then
  note 'The namespace lab has no cable control or physical Ethernet transceiver
(PHY). Its virtual interfaces are already connected. Inspect their link state.'
  node a 'ip -br link show eth0'
  finish 'Does this virtual link show how physical Ethernet negotiates a connection?' \
    'No. The namespace lab supplies a connected virtual pair. Use the VM lab
for controllable carrier events, or hardware for speed and duplex negotiation.
Next, inspect the frames that appear when an interface comes up.' \
    'Next: ./scripts/02-listen.sh'
  exit 0
fi

if [ "$MODE" = vm ]; then
  LINK="$SCRIPTS/virtual-vm/link.sh"
  note 'QEMU controls carrier, the signal that a link is available. The virtual
interface has no physical transceiver, so speed and duplex are not negotiated.'
  pause 'Ready to disconnect the virtual cable and inspect pi-a’s link?'
  terminal_output "$LINK" a off
  node a 'ip -br link show eth0'
  pause 'Find NO-CARRIER. What should change when you reconnect?'
  terminal_output "$LINK" a on
  sleep 2
  node a 'ip -br link show eth0'
  pause 'Did NO-CARRIER change to LOWER_UP?'
  eye 'LOWER_UP means the interface reports a live link. Here, QEMU supplied
that carrier event. No physical speed negotiation took place.'
else
  note 'In ip output, LOWER_UP describes a live link. In ethtool, compare
Link detected, Speed, and Duplex before and after seating the cable.'
  pause 'Unplug the cable on pi-a, then press Enter to inspect the disconnected port.'
  node a 'ip -br link show eth0'
  node a 'ethtool eth0 | grep -E "Speed:|Duplex:|Link detected:"'
  pause 'Seat the cable on both ends, wait about three seconds, then press Enter.'
  node a 'ip -br link show eth0'
  node a 'ethtool eth0 | grep -E "Speed:|Duplex:|Link detected:"'
  pause 'Which fields changed? Did the hardware report a speed and duplex?'
  eye 'LOWER_UP and Link detected: yes identify the live link. Speed and Duplex
show what the two Ethernet interfaces negotiated. Follow your reported values;
they depend on the hardware and cable.'
fi

finish 'What does LOWER_UP prove, and what has it not tested yet?' \
  'It proves the interface reports a live link. You have not yet tested
which frames cross it or whether an IPv4 ping can reach the other machine.
Next, capture the traffic that appears when the link comes up.' \
  'Next: ./scripts/02-listen.sh'
