#!/usr/bin/env bash
# Build a two-node "little internet" in network namespaces: two independent
# network stacks (pi-a, pi-b) joined by a single veth pair. A veth pair is the
# closest software analog to one Ethernet cable — two ends, nothing in between.
# No bridge, no gateway, no DHCP. Just a wire.
#
# Requires a Linux host (or a Linux VM, e.g. colima/lima) and root. The link
# comes up with NO IPv4 address — a blank wire, exactly where the lesson starts.
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

# bring both ends up (carrier needs both, just like a real cable) — but assign
# NO IPv4. Blank L3.
for ns in "$A" "$B"; do
  ip netns exec "$ns" ip link set lo up
  ip netns exec "$ns" ip link set eth0 up
done

echo "Lab up:  $A  <--veth(eth0)-->  $B   (link up, no IPv4 yet)"
echo
echo "Step onto a node and run the beats there, e.g.:"
echo "  sudo ip netns exec $A ip -4 addr show eth0      # blank"
echo "  sudo ip netns exec $A ping -c1 10.10.0.2        # beat 3: fails, no identity"
echo "  sudo ip netns exec $A ip addr add 10.10.0.1/24 dev eth0   # beat 4 setup"
echo "  sudo ip netns exec $B ip addr add 10.10.0.2/24 dev eth0"
echo "  sudo ip netns exec $A ./demo.sh                 # or run beats 3-4 in one shot"
echo
echo "Tear down with: sudo ./lab-down.sh"
