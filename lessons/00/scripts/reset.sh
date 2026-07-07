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
Returning eth0 on both nodes to its stock resting state: a single DHCP, autoconnect
profile and no address. That's a "blank wire" in the sense the lesson means—nothing
*you* configured—but it still chatters the instant the link comes up, exactly like a
freshly imaged Pi. This is what makes the whole thing re-runnable: reset, start from
the top, and beat 2 fires for real again instead of sitting silent.
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
