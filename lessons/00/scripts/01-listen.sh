#!/usr/bin/env bash
# They're already talking, you just weren't listening: bounce pi-a's link, capture
# the link-up burst, then try the naive ping that "obviously" works (it doesn't).
source "$(dirname "$0")/lib.sh"

note <<'EOF'
This is the one that got me. There's a live wire but no addresses, nothing 
configured, so the link should sit there silent until you tell it to do 
something. It doesn't. 

Bounce pi-a's link to replay the moment of connection and watch: the instant it comes up,
the Pi hands itself an identity, shouts its own name, and goes hunting for a server
that isn't there. You asked for none of it. And look closely—some of these frames
aren't even pi-a. The other Pi is already on the wire, talking too.

(It looks different every run: a free-for-all of independent processes, not a
script. Watch for the kinds of frames below, not an exact transcript.)
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
# not just itself—the "some of these frames aren't even me" moment from the diary.
# Best-effort: if pi-b can't be driven unattended (passworded sudo on a backgrounded
# session), you simply get pi-a's own burst, same as before.
BPID=
if [ "$MODE" = ssh ]; then
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
ICMP6 "neighbor solicitation, who has fe80::..."  DAD: claiming its own IPv6 address
"multicast listener report"                       joining IPv6 groups
"router solicitation" to ff02::2                  hunting for a router (no reply comes)

On real Pis you'll also see MDNS (the node shouting its own hostname) and DHCP
Discover (begging for an address), both of which go unanswered.
EOF

pause "Press Enter when you've had a look."

note <<'EOF'
Frames are flying both directions now. So the two can obviously ping each
other... right? Let's just try, before we configure a single thing.
EOF

pause "Press Enter to ping pi-b from pi-a."

node_a "$STYLE"'
h "ping -c1 10.10.0.2"
ping -c1 -W1 10.10.0.2 || true'

note <<'EOF'
Fie. A live wire, frames flowing both ways, and the ping still drops. So
where did that packet even go? That's the next step.
EOF

pause "Press Enter to find out."
