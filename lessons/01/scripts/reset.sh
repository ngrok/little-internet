#!/usr/bin/env bash
# Put the wire back to blank so you can re-run from the top.
source "$(dirname "$0")/lib.sh"

if [ "$MODE" = netns ]; then
  note <<'EOF'
Namespace lab: tear it all down with  sudo ./virtual/lab-down.sh
EOF
  exit 0
fi

note <<'EOF'
Reset eth0 on both nodes to one DHCP profile with autoconnect enabled.
On this serverless link, DHCP requests go unanswered and eth0 stays without
an IPv4 address. The link-up traffic is still there to inspect when you
repeat the lesson.
EOF

pause "Press Enter to reset eth0 to the stock DHCP baseline on both nodes."

RESET="$(baseline_block)"'
if ip -4 addr show eth0 | grep -q "inet "; then
  echo "eth0 back to the DHCP baseline, but it unexpectedly has an IPv4 address"
else
  echo "eth0 back to the DHCP baseline (eth-dhcp): no address, ready to chatter"
fi'

h "pi-a"; node_a "$RESET"
h "pi-b"; node_b "$RESET"
