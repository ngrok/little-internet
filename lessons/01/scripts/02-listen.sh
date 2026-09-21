#!/usr/bin/env bash
# Capture link-up traffic, then test IPv4 reachability before addressing.
source "$(dirname "$0")/lib.sh"
begin '02 — Are frames flowing already?' \
  'A live link lets Ethernet frames travel. Capture the first burst of traffic
before assigning IPv4 addresses, then test whether a ping can reach pi-b.'
note 'Compare the Source and Destination columns and the message names.
Neighbor Solicitation checks an IPv6 address; DHCP Discover asks for an IPv4
address. These may appear before you configure anything yourself.'

# Keep the hardware image's DHCP baseline and its spontaneous link-up traffic.
if [ "$MODE" = ssh ]; then
  node_a "$(baseline_block)"
  node_b "$(baseline_block)"
fi
pause 'Which machine do you expect to hear: pi-a, pi-b, or both?'
CAPTURE="/tmp/little-internet-01-$RUN_ID-link-up.pcap"
BPID=
if [ "$MODE" = ssh ] || [ "$MODE" = vm ]; then
  # Best effort: a password-protected sudo session may not run in the background.
  node_b 'ip link set eth0 down; sleep 2; ip link set eth0 up' >/dev/null 2>&1 &
  BPID=$!
fi
node_a "tcpdump -i eth0 -n -e -U -w '$CAPTURE' 2>'$CAPTURE.log' & CAP=\$!
trap 'kill -INT \$CAP 2>/dev/null || true' EXIT
sleep 1
ip link set eth0 down
sleep 1
ip link set eth0 up
sleep 10
if ! kill -0 \$CAP 2>/dev/null; then cat '$CAPTURE.log' >&2; exit 1; fi
kill -INT \$CAP
wait \$CAP || true
trap - EXIT
chmod a+r '$CAPTURE'"
if [ -n "$BPID" ]; then
  if ! wait "$BPID"; then
    note 'The neighbor’s link bounce did not complete. The capture may show only
pi-a’s own startup traffic. Compare the source addresses before concluding.'
  fi
fi
capture_show "$CAPTURE" link-up
pause 'Do the sources include both machines? Which message types appeared?'
eye 'Neighbor Solicitation from :: checks whether an IPv6 address is in use.
Multicast Listener Reports announce group membership; Router Solicitation
asks for an IPv6 router. Pis may also send mDNS and DHCP Discover.
The mix depends on each node’s services. This link has no DHCP server.'
note 'The capture shows Ethernet traffic. Now try an IPv4 ping using the
address you want pi-b to have. Link activity alone may not be enough.'
pause 'Will ping reach 10.10.0.2 before you assign that address?'
if node a 'ping -c1 -W1 10.10.0.2'; then
  note 'The ping unexpectedly worked. Inspect the current addresses and route
before treating this as an unconfigured link.'
else
  status=$?
  [ "$status" -eq 1 ] || exit "$status"
  note 'The ping failed. Keep that result in view while you inspect the route
in the next phase. A failed ping alone does not identify the cause.'
fi
finish 'Do frames on the link prove that 10.10.0.2 is reachable?' \
  'No. The capture proves that frames travel, including automatic discovery
traffic. Reaching a particular IPv4 address also needs suitable addresses
and a route. Next, ask the kernel which route it would use.' \
  'Next: ./scripts/03-no-address.sh'
