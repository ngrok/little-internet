#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
begin '06 — Can you ask for the address you want?' \
  'DHCP chose the addresses. This time, have pi-a ask for .1 and pi-b for .2.
A preference is a request. The server decides which address to offer.'
pause 'Would changing a preference replace a lease that is already active?'
require_clients
a_ip="$(client_ip a)"; b_ip="$(client_ip b)"
note 'First stop both clients, release their actual server bindings, and clear
their remembered leases. That gives the new requests a fresh start.'
for n in a b; do client_down "$n"; done
for n in a b; do
  case "$n" in a) old="$a_ip"; desired=10.10.0.1;; b) old="$b_ip"; desired=10.10.0.2;; esac
  setup dhcp "dhcp_release eth0 $old $(cable_mac "$n")
sleep 1"
  setup "$n" "cat > /etc/NetworkManager/dhclient-eth0.conf <<'CONF'
on transmission {
    if config-option dhcp-message-type = 01 {
        send dhcp-requested-address $desired;
    }
}
CONF"
  forget_client "$n"
done
node b 'cat /etc/NetworkManager/dhclient-eth0.conf'
pause 'The condition means “only in Discover.” Ready to see what pi-b asks for?'
capture_start preference
for n in a b; do
  setup "$n" 'nmcli --wait 30 connection up eth-dhcp'
done
capture_stop
note 'First check that pi-b completed a DHCP exchange: follow one Transaction ID
from Discover through ACK. This summary names each message; the address preference
is inside them. Inspect those fields next.'
pause 'Did one exchange reach ACK?'
capture_show b "dhcp && dhcp.hw.mac_addr == $(cable_mac b)"
pause 'Can you trace Discover, Offer, Request, and ACK with the same ID?'
note 'Look inside the same exchange. Type 1 = Discover, 2 = Offer,
3 = Request, 5 = ACK. Option 50 is the requested address;
yiaddr is the address the server offers or assigns.'
pause 'Does the address requested in Discover match the one offered and assigned?'
dhcp_fields b
pause 'Compare Discover’s requested address with Offer and ACK. Did they agree?'
eye 'Discover carries the preference. Request accepts the server’s offer,
which can differ. A reservation would be a rule configured on the server.'
pause 'Check what the clients actually applied.'
node a 'ip -4 -br addr show dev eth0'
node b 'ip -4 -br addr show dev eth0'
finish 'Why might a client keep its old address if you only edit the preference?' \
  'Editing the preference doesn’t replace an active lease. Both client and
server remember the assignment. That’s why you stopped the client, released its
binding, and cleared its remembered lease before asking again. Next, test
whether this configured network comes back on its own after reconnection.' \
  'Next: ./scripts/07-reconnect.sh'
