#!/usr/bin/env bash
# Build a two-node "little internet" in network namespaces: two independent
# network stacks (pi-a, pi-b) joined by a single veth pair. A veth pair is the
# closest software analog to one Ethernet cable—two ends, nothing in between.
# No bridge, no gateway, no DHCP. Just a wire.
#
# Requires a Linux host (or a Linux VM, e.g. colima/lima) and root. The link
# comes up with NO IPv4 address—a blank wire, exactly where the lesson starts.
set -euo pipefail
A="${A:-pi-a}"
B="${B:-pi-b}"

if ip netns list | grep -qw "$A"; then
  echo "Namespace $A already exists. Run lab-down.sh first." >&2
  exit 1
fi

ip netns add "$A"
ip netns add "$B"

# the veth pair = the cable; one end into each namespace, renamed eth0 so every
# command below matches the hardware runbook verbatim.
ip link add veth-a type veth peer name veth-b
ip link set veth-a netns "$A"
ip link set veth-b netns "$B"
ip netns exec "$A" ip link set veth-a name eth0
ip netns exec "$B" ip link set veth-b name eth0

# bring both ends up (carrier needs both, just like a real cable)—but assign
# NO IPv4. Blank L3.
for ns in "$A" "$B"; do
  ip netns exec "$ns" ip link set lo up
  ip netns exec "$ns" ip link set eth0 up
done

echo "Lab up:  $A  <--veth(eth0)-->  $B   (link up, no IPv4 yet)"

# Verbose hints when run by hand; quiet when driven by demo.sh (QUIET=1).
if [ -z "${QUIET:-}" ]; then
  echo
  echo "Drive the steps against this lab with MODE=netns, e.g. from lessons/00:"
  echo "  MODE=netns ./scripts/02-no-address.sh    # fails, no identity"
  echo "  MODE=netns ./scripts/03-address.sh       # give each node an identity"
  echo "  MODE=netns ./scripts/04-arp.sh           # the ARP introduction"
  echo
  echo "Tear down with: sudo ./lab-down.sh"
fi
