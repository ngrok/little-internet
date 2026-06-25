#!/usr/bin/env bash
# They're already talking, you just weren't listening. With the cable
# already seated, momentarily bounce pi-a's link to re-create the
# instant of connection, and capture what the node says into the void.
source "$(dirname "$0")/lib.sh"

note <<'EOF'
This is the one that got me. A live wire, no addresses, nothing configured—so the
link should sit there silent until you tell it to do something. It doesn't. Bounce
pi-a's link to replay the moment of connection and watch: the instant it comes up,
the Pi hands itself an identity, shouts its own name, and goes hunting for a server
that isn't there. You asked for none of it. And look closely—some of these frames
aren't even pi-a. The other Pi is already on the wire, talking too.

(It looks different every run: a free-for-all of independent processes, not a
script. Watch for the kinds of frames below, not an exact transcript.)
EOF

eye <<'EOF'
ICMP6 "neighbor solicitation, who has fe80::..."  DAD: claiming its own IPv6 address
"multicast listener report"                       joining IPv6 groups
"router solicitation" to ff02::2                  hunting for a router (no reply comes)
On real Pis you'll ALSO see MDNS (the node shouting its own hostname) and DHCP
Discover (begging for an address). Both go unanswered. All talk, no answers.
EOF

pause "Press Enter to bounce pi-a's link and capture the burst."

node_a "$STYLE"'
rm -f /tmp/link-up.pcap
tcpdump -i eth0 -n -e -U -w /tmp/link-up.pcap 2>/dev/null & CAP=$!
sleep 1; ip link set eth0 down; sleep 1; ip link set eth0 up; sleep 8
kill $CAP 2>/dev/null; wait $CAP 2>/dev/null
h "the link-up burst on eth0 (oldest first)"
if command -v tshark >/dev/null 2>&1; then
  tshark -n -r /tmp/link-up.pcap 2>/dev/null
else
  echo "(tshark not found—showing tcpdump)"
  tcpdump -n -r /tmp/link-up.pcap 2>/dev/null
fi'
