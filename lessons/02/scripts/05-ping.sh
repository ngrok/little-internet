#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
begin '05 — DHCP supplied identities. How do they talk?' \
  'Ping the address pi-b actually received. Clear pi-a’s neighbor cache to
watch it find the peer’s MAC address again.'
pause 'Does the DHCP server have to relay a ping between these clients?'
require_clients
peer="$(client_ip b)"
node a "ip route get $peer"
note 'dev eth0 names the local interface; there is no “via” gateway in this route.
That is a direct path to the peer. Now test whether a packet gets a reply.'
pause 'Find dev eth0. Ready to send two pings down that path?'
capture_start ping
setup a 'ip neigh flush dev eth0'
node a "ping -I eth0 -c2 -W2 $peer"
capture_stop
note 'The ping received a reply: the clients can reach each other using their
DHCP-assigned addresses. That answers “can they talk?” Next, the capture
shows how pi-a found the Ethernet destination before sending its first echo.'
pause 'Check the received count and packet loss. Ready to inspect the exchange?'
note 'Look for “Who has” asking for pi-b’s leased IP, then the “is at” reply.
Follow those rows to the ICMP Echo packets. Their seq values identify
the first and second ping; announcements are separate ARP traffic.'
pause 'Will the second Echo request need another “Who has” lookup?'
capture_show a 'arp or icmp'
pause 'Is another lookup needed before seq=2, or does pi-a reuse the first reply?'
eye 'DHCP supplied an IP identity. ARP supplies the peer’s MAC address.
Once that mapping is cached, later echoes can use it directly.'
note 'Compare the same client-to-client traffic in the server’s recording.
Look for the “Who has” broadcast and the Echo rows between the clients’ IPs.
The server may also send its own ARP queries; check their source addresses.'
pause 'Should the server hear the broadcast, relay the echoes, or simply listen?'
capture_show dhcp 'arp or icmp'
pause 'Is the client broadcast present? Are the clients’ Echo packets present?'
eye 'The server hears broadcasts, but it doesn’t relay these pings.
The switch forwards learned unicast to the destination port.
Unknown unicast can be flooded, so follow your actual capture.'
finish 'Did the DHCP server relay this ping? Which evidence supports your answer?' \
  'No. The route went directly over eth0, and ARP resolved the peer’s MAC.
DHCP assigned addresses; the switch carried the client-to-client frames.
Next, ask whether the clients can influence which addresses they receive.' \
  'Next: ./scripts/06-preference.sh'
