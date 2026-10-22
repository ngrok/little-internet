#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
begin '04 — Give each end an IPv4 address' \
  'Assign 10.10.0.1/24 to pi-a and 10.10.0.2/24 to pi-b. The /24 puts both
addresses in the same local subnet, 10.10.0.0/24.'
addr_for() {
cat <<EOF
if command -v nmcli >/dev/null && systemctl is-active --quiet NetworkManager; then
  nmcli connection add type ethernet ifname eth0 con-name eth ipv4.method manual \\
    ipv4.addresses $1/24 ipv4.never-default yes ipv6.method link-local \\
    connection.autoconnect yes connection.autoconnect-priority 10
  nmcli connection up eth
else
  ip addr add $1/24 dev eth0
fi
EOF
}
pause 'Which interface should the kernel choose once both addresses are assigned?'
h 'Assigning 10.10.0.1/24 to pi-a'
node_a "$(addr_for 10.10.0.1)"
h 'Assigning 10.10.0.2/24 to pi-b'
node_b "$(addr_for 10.10.0.2)"
note 'Now inspect the result. dev identifies the outgoing interface; src is
the IPv4 source address the kernel chooses for that destination.'
pause 'Ready to compare the routes in both directions?'
node a 'ip route get 10.10.0.2'
node b 'ip route get 10.10.0.1'
pause 'Does each route use dev eth0 and the address assigned to that node?'
eye 'Assigning these /24 addresses creates connected routes on eth0.
The kernel can now choose the Ethernet interface to reach the peer’s IPv4
address. A route tells you where it will try; a ping tests whether it works.'
finish 'What changed in the route, and what still needs a test?' \
  'dev should now name eth0, and src should match that node’s new address.
Both machines have a local path to the peer. Next, send a ping and inspect
the address lookup that makes Ethernet delivery possible.' \
  'Next: ./scripts/05-arp.sh'
