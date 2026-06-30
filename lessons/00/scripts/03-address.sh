#!/usr/bin/env bash
# Give the wire an identity on BOTH nodes at once. The node
# decides how: nmcli if it has NetworkManager (the Pi image does), otherwise
# plain `ip addr add` (the namespace lab).
source "$(dirname "$0")/lib.sh"

addr_for() {  # $1 = this node's IPv4, $2 = peer IPv4
cat <<EOF
if command -v nmcli >/dev/null && systemctl is-active --quiet NetworkManager; then
  # autoconnect-priority above the eth-dhcp baseline (0) so this static identity
  # wins on the device from here on, including across reboots.
  nmcli connection add type ethernet ifname eth0 con-name eth ipv4.method manual \
    ipv4.addresses $1/24 ipv4.never-default yes ipv6.method link-local \
    connection.autoconnect yes connection.autoconnect-priority 10
  nmcli connection up eth
else
  ip addr add $1/24 dev eth0
fi
h "ip route get $2 now points at eth0"
ip route get $2 || true
EOF
}

note <<'EOF'
So, hand the wire an identity—the piece that was missing. This gives both nodes an
IPv4 address in one go. Then watch the same "ip route get" that betrayed you a
moment ago: the instant eth0 has an address, the routing table can finally see the
cable as a path. pi-a becomes 10.10.0.1, pi-b becomes 10.10.0.2.
EOF

pause "Press Enter to assign 10.10.0.1 to pi-a and 10.10.0.2 to pi-b."

h "Addressing pi-a as 10.10.0.1"
node_a "$STYLE
$(addr_for 10.10.0.1 10.10.0.2)"
h "Addressing pi-b as 10.10.0.2"
node_b "$STYLE
$(addr_for 10.10.0.2 10.10.0.1)"

eye <<'EOF'
each node accepts its address with no error
"ip route get" to the peer now resolves to dev eth0—the wire just became reachable
the src shown is the address you just assigned
EOF

pause "Press Enter when you've had a look."
