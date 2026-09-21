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
Assign 10.10.0.1/24 to pi-a and 10.10.0.2/24 to pi-b. Each address creates a
connected route for this subnet. Run "ip route get" again and compare its dev
and src fields with the previous result.
EOF

pause "Press Enter to assign 10.10.0.1 to pi-a and 10.10.0.2 to pi-b."

h "Addressing pi-a as 10.10.0.1"
node_a "$STYLE
$(addr_for 10.10.0.1 10.10.0.2)"
h "Addressing pi-b as 10.10.0.2"
node_b "$STYLE
$(addr_for 10.10.0.2 10.10.0.1)"

eye <<'EOF'
Check that each address assignment succeeded.
The route to the peer should now use dev eth0.
The src field should match the address you assigned to that node.
EOF

pause "Press Enter when you've had a look."
