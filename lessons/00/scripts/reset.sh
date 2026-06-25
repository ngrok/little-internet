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
Wiping the lab profile from both nodes so eth0 goes back to a blank wire, ready to
run the whole thing again from scratch.
EOF

pause "Press Enter to delete the 'eth' profile on both nodes."

RESET='if nmcli connection delete eth 2>/dev/null; then
  echo "deleted the eth profile—back to a blank wire"
else
  echo "no eth profile found (already blank)"
fi'

h "pi-a"; node_a "$RESET"
h "pi-b"; node_b "$RESET"
