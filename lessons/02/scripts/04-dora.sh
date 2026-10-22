#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
begin '04 — How does an addressless client ask?' \
  'The server is ready. Have pi-a ask again, then follow its conversation.'
pause 'Predict the source and destination of the first packet. Ready to record it?'
setup dhcp 'systemctl is-active dnsmasq'
for n in a b; do client_down "$n"; forget_client "$n"; done
capture_start dora
node a 'nmcli --wait 30 connection up eth-dhcp'
# Bring up both clients within one capture, but inspect one conversation at a time.
setup b 'nmcli --wait 30 connection up eth-dhcp'
capture_stop
note 'Read the Source and Destination columns on the first row, then follow
one Transaction ID through the message names: Discover, Offer, Request, ACK.
Use the shared ID to follow one exchange, including any retries.'
pause 'Who sends the first packet, and which message first answers it?'
capture_show a "dhcp && dhcp.hw.mac_addr == $(cable_mac a)"
pause 'Which source sends the Offer? Does its transaction also reach Request and ACK?'
eye 'Discover asks for an address; Offer proposes one. Request accepts the
offer, and ACK confirms the lease. Those initials give us DORA.
The transaction ID ties the messages together, even when there are retries.'
pause 'Did that conversation become an address on eth0? Compare both clients.'
node a 'ip -4 -br addr show dev eth0'
node b 'ip -4 -br addr show dev eth0'
pause 'The addresses can differ from .1 and .2. Does the server agree?'
note 'The lease file lists expiry time, client MAC, IPv4 address, hostname,
and client ID. Match each IPv4 address with the interface output above.'
node dhcp 'cat /var/lib/misc/dnsmasq.leases'
pause 'Do the addresses match? Neither client needed a manual IPv4 assignment.'
eye 'NetworkManager applied the leases. The server chooses from its pool of
available addresses; the first two devices might get something other than
.1 and .2.'
finish 'What changed after ACK, and how did you check that it took effect?' \
  'NetworkManager applied the leased IPv4 address to eth0. You compared the
interface address with the server’s lease record. The clients now have
addresses without manual assignment. Next, test whether they can talk.' \
  'Next: ./scripts/05-ping.sh'
