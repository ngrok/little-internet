#!/usr/bin/env bash
# Capture the traffic at link-up, then test IPv4 reachability before addressing.
source "$(dirname "$0")/lib.sh"

note <<'EOF'
The wire already carries traffic, even though you haven't assigned IPv4
addresses. Disconnect and reconnect the interface to capture that first burst.

Look for IPv6 neighbor discovery and, on the Pis, hostname announcements and
DHCP requests. Compare the sources: pi-a can hear its neighbor as well as itself.
The mix and timing depend on each node's services, so follow your actual rows.
EOF

# Both nodes need their stock DHCP baseline so the bounce reproduces the FULL burst
# (DHCP + IPv6 + mDNS), not just the kernel's IPv6 chatter. NetworkManager only; the
# netns lab has no NM and shows the IPv6-only burst on its own.
if [ "$MODE" = ssh ]; then
  h "making sure both nodes are at the stock DHCP baseline"
  node_a "$(baseline_block)"
  node_b "$(baseline_block)"
fi

pause "Press Enter to bounce the link(s) and capture the burst on pi-a."

# In ssh mode, bounce the neighbor in the background too, timed so its link comes up
# *inside* pi-a's capture window: pi-a then hears pi-b wake up on the shared wire,
# not just itself—the "some of these frames aren't even me" moment from the build log.
# Best-effort: if pi-b can't be driven unattended (passworded sudo on a backgrounded
# session), you simply get pi-a's own burst, same as before.
BPID=
if [ "$MODE" = ssh ] || [ "$MODE" = vm ]; then
  node_b "$STYLE"'ip link set eth0 down; sleep 2; ip link set eth0 up' >/dev/null 2>&1 &
  BPID=$!
fi

node_a "$STYLE"'
rm -f /tmp/link-up.pcap
tcpdump -i eth0 -n -e -U -w /tmp/link-up.pcap 2>/dev/null & CAP=$!
sleep 1; ip link set eth0 down; sleep 1; ip link set eth0 up; sleep 10
kill $CAP 2>/dev/null; wait $CAP 2>/dev/null
h "the link-up burst on eth0 (oldest first)"
if command -v tshark >/dev/null 2>&1; then
  # COLORTERM inline because the ssh transport runs this via non-login sudo bash,
  # which never sources /etc/profile.d; tshark --color stays blank without it.
  COLORTERM=truecolor tshark -n -r /tmp/link-up.pcap --color 2>/dev/null
else
  echo "(tshark not found—showing tcpdump)"
  tcpdump -n -r /tmp/link-up.pcap 2>/dev/null
fi'

[ -n "$BPID" ] && wait "$BPID" 2>/dev/null
true

eye <<'EOF'
Neighbor solicitation from :: checks whether an IPv6 address is already in use.
Multicast listener reports announce membership in IPv6 multicast groups.
Router solicitation to ff02::2 asks for an IPv6 router.

On the Pis, also look for mDNS hostname announcements and DHCP Discover.
This two-node network has no router or DHCP server to answer those requests.
EOF

pause "Press Enter when you've had a look."

note <<'EOF'
The capture shows frames crossing the link. Now try an IPv4 ping before
assigning addresses. This tests reachability using the address you type.
EOF

pause "Press Enter to ping pi-b from pi-a."

node_a "$STYLE"'
h "ping -c1 10.10.0.2"
ping -c1 -W1 10.10.0.2 || true'

note <<'EOF'
If the ping failed, the link alone wasn't enough. Next, inspect the route
to find out where the kernel tried to send it.
EOF

pause "Press Enter to find out."
