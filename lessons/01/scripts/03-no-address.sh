#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
begin '03 — Where would that ping go?' \
  'The last phase tested a ping before assigning addresses. Inspect eth0 and
ask the kernel which route it would use to reach 10.10.0.2.'
note 'An inet line identifies an IPv4 address. In the route, dev names the
outgoing interface. An unreachable error means there is no route.'
pause 'Will the route name eth0, another interface, or no path at all?'
node a 'ip -4 addr show eth0'
# No route is an expected observation in the namespace lab.
if node a 'ip route get 10.10.0.2'; then
  :
else
  status=$?
  [ "$status" -eq 2 ] || exit "$status"
fi
pause 'Is there an inet line? If a route appeared, which dev does it name?'
eye 'In the starting state, eth0 has no IPv4 address or connected route for
10.10.0.2. A Pi may choose wlan0; a VM may choose its management interface.
The namespace lab has no other route. Compare that expectation with your output.'
finish 'Why can a live Ethernet link still be missing from this IPv4 route?' \
  'Carrier reports link state. It does not assign an IPv4 address or create
a connected IPv4 route. Next, assign addresses in the same subnet and
compare the route’s dev and src fields again.' \
  'Next: ./scripts/04-address.sh'
