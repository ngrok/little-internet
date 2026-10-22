#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
begin '01 — Does the switch hand out addresses?' \
  'Last time, you assigned IPv4 addresses by hand. Now a switch connects
three machines. Test whether it assigns those addresses for you.'
pause 'Look for LOWER_UP: does each client have a live Ethernet link?'
setup dhcp 'if systemctl is-active --quiet dnsmasq; then
  echo "dnsmasq is already running; use scripts/reset.sh for a fresh lesson." >&2; exit 1
fi'
for n in a b; do
  setup "$n" 'if ip -4 -o addr show dev eth0 | grep -q "inet "; then
  echo "eth0 already has an address; use scripts/reset.sh first." >&2; exit 1
fi'
  node "$n" 'ip -br link show eth0'
done
pause 'The links are up. Who do you predict will answer a request for an address?'
note 'pi-a will ask using DHCP, the Dynamic Host Configuration Protocol.
No DHCP service is running yet. This attempt can take about 20 seconds.'
capture_start switch
if node a 'nmcli --wait 20 connection up eth-dhcp'; then
  echo 'Unexpected success: inspect the capture for a DHCP server.' >&2
  exit 1
fi
note 'The activation failed. Keep that error in view as we inspect the packets.'
capture_stop
note 'Discover asks for an address; Offer would be a server’s answer.
The Transaction ID labels the exchange. Keep one ID in mind when we
compare captures: frame numbers are local to each recording.'
pause 'Look at pi-a’s attempt. Is there an Offer answering its Discover?'
capture_show a dhcp
pause 'Did that request cross the switch? Look for its transaction ID on pi-b.'
capture_show b dhcp
pause 'Do the transaction IDs match? Why would pi-b hear pi-a’s request?'
eye 'Discover is a broadcast: it asks everyone on this Ethernet network.
A matching Discover on pi-b shows the request crossed the switch.
Check for an Offer before concluding that nobody answered this attempt.'
node a 'ip -4 -br addr show dev eth0'
finish 'Does a live switch connection also give a client an IPv4 identity?' \
  'No. LOWER_UP describes the link; it does not assign an address. The
unanswered Discover and empty IPv4 column show what is still missing.
Next, assign addresses by hand and test what the switch can carry.' \
  'Next: ./scripts/02-manual.sh'
