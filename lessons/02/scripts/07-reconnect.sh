#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
begin '07 — Can the network assemble itself?' \
  'The switch carries frames, the server offers leases, and the clients
have address preferences. Reconnect Ethernet and watch them get to work.'
pause 'Predict the order: obtaining an identity, finding a MAC, sending a ping.'
require_clients
note 'Disconnecting both virtual cables. These are carrier events in QEMU;
this lab has no physical cable or speed negotiation.'
for n in a b; do
  setup "$n" 'nmcli connection modify eth-dhcp connection.autoconnect yes'
  "$SCRIPTS/virtual-vm/link.sh" "$n" off >/dev/null
  # Explicit connection down can suppress automatic reconnect. Let NM respond
  # to carrier loss instead, then clear only the client's remembered lease.
  setup "$n" 'for i in $(seq 1 20); do
  if ! nmcli -t -f NAME connection show --active | grep -qx eth-dhcp; then
    exit 0
  fi
  sleep 1
done
echo "NetworkManager did not deactivate after carrier loss." >&2
exit 1'
  forget_client "$n"
  node "$n" 'ip -br link show eth0'
done
pause 'Find NO-CARRIER. Ready to reconnect and let the clients ask automatically?'
setup dhcp 'systemctl stop dnsmasq'
capture_start reconnect
setup dhcp 'systemctl start dnsmasq'
for n in a b; do "$SCRIPTS/virtual-vm/link.sh" "$n" on >/dev/null; done
for n in a b; do
  setup "$n" 'for i in $(seq 1 45); do
  if ip -4 -o addr show dev eth0 | grep -q "inet 10.10.0."; then
    exit 0
  fi
  sleep 1
done
echo "No lease after reconnect; inspect the capture and dnsmasq log." >&2
exit 1'
done
require_clients
peer="$(client_ip b)"
setup a 'ip neigh flush dev eth0'
node a "ping -I eth0 -c2 -W2 $peer"
capture_stop
note 'The ping received a reply after reconnection. The clients obtained their
identities automatically and became reachable again. Read the capture in two
parts: first the DHCP lease, then the ARP lookup and ping.'
pause 'Check the received count and packet loss. Ready to trace those two parts?'
note 'Start with the DHCP rows: follow pi-a’s Transaction ID through ACK,
the server’s confirmation. Then inspect the ARP and ping traffic.'
pause 'The ping has replies. First, find how pi-a got an identity after reconnect.'
capture_show a "dhcp && dhcp.hw.mac_addr == $(cable_mac a)"
pause 'Find the ACK. What still had to happen to reach pi-b?'
eye 'NetworkManager restarted DHCP when carrier returned and applied the lease.
The server kept its lease records, so receiving the old address is possible.'
note 'In the next table, look for “Who has” asking for pi-b’s leased address,
then its “is at” reply and the client-to-client Echo packets. Queries from
10.10.0.254 are the server’s own checks; distinguish them by their source.'
pause 'Which address lookup belongs to the client-to-client ping?'
capture_show a 'arp or icmp'
pause 'Does that lookup finish before the clients’ first Echo request?'
eye 'The switch supplies Ethernet connectivity. DHCP leases IPv4 identities.
ARP finds the peer’s MAC; ICMP echo replies demonstrate reachability.
You configured each machine once, then watched them reconnect.'
finish 'Which packet or field would you point to as evidence for each job?' \
  'Broadcasts arriving on another node show the switch carried frames.
DHCP ACK and the interface address show the lease became an identity.
The ARP “is at” reply supplies the peer’s MAC. ICMP Echo replies show
reachability: the configured pieces worked together after reconnection.' \
  'The lab stays up. Explore, reset with ./scripts/reset.sh, or stop with
./scripts/virtual-vm/lab-down.sh.'
