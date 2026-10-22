#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
begin '02 — Can the switch carry a ping?' \
  'The address request went unanswered. Try the fix from lesson 01:
assign 10.10.0.1 to pi-a and 10.10.0.2 to pi-b, then inspect the route.'
pause 'Will adding IPv4 identities make eth0 a path to the other machine?'
for n in a b; do
  client_down "$n"
  case "$n" in a) addr=10.10.0.1;; b) addr=10.10.0.2;; esac
  setup "$n" "if nmcli -t -f NAME connection show | grep -qx eth-manual; then
  nmcli connection delete eth-manual
fi
nmcli connection add type ethernet ifname eth0 con-name eth-manual \\
  ipv4.method manual ipv4.addresses $addr/24 ipv4.never-default yes \\
  ipv6.method link-local connection.autoconnect no
nmcli connection up eth-manual"
  node "$n" 'ip -4 -br addr show dev eth0'
done
node a 'ip route get 10.10.0.2'
pause 'Find dev eth0 and src 10.10.0.1. Ready to try that route?'
capture_start manual
setup a 'ip neigh flush dev eth0'
node a 'ping -I eth0 -c2 -W2 10.10.0.2'
capture_stop
note 'The ping received a reply. Assigning IPv4 addresses made the peer reachable
through the switch. Now follow the capture to see how that IP address became
an Ethernet destination before the first echo left pi-a.'
pause 'Check the received count and packet loss. Ready to follow the packets?'
note 'Ping names an IPv4 address; Ethernet also needs the destination MAC.
Look for “Who has 10.10.0.2?” sent to ff:ff:ff:ff:ff:ff (everyone),
then an “is at” reply. ICMP Echo rows are the ping itself.
“ARP Announcement” introduces the sender’s own IP; it is a separate message.'
pause 'Which packet supplies the missing MAC before the first Echo request?'
capture_show a 'arp or icmp'
pause 'What MAC appears in the “is at” reply, and what packet follows it?'
eye 'The ARP reply maps 10.10.0.2 to its MAC. That gives pi-a the Ethernet
destination for its Echo request. Follow that request to the Echo reply:
the successful ping depended on this address lookup first.'
note 'Now inspect pi-dhcp. It’s listening, but neither client is pinging it.
Compare the same “Who has” broadcast with the Echo packets between the clients.
Broadcast addresses everyone; unicast addresses one destination.'
pause 'Which should reach the third machine: the broadcast, the echoes, or both?'
capture_show dhcp 'arp or icmp'
pause 'Is the “Who has” broadcast here? Are any client-to-client Echo rows here?'
eye 'Broadcasts without client echoes match the behavior of a learning switch.
It learns a source MAC’s port as frames arrive, then sends traffic for that
MAC to that port. Broadcast still reaches everyone. An unknown unicast
destination can also be flooded; compare that expectation with your rows.'
finish 'The ping works, but which part of this setup still needed a person?' \
  'You assigned the IPv4 addresses. The switch carried frames between the
machines, and ARP found the peer’s MAC. Next, give a DHCP server the job
of assigning addresses automatically.' \
  'Next: ./scripts/03-server.sh'
