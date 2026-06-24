#!/usr/bin/env bash
# Tear down the lab IP profile so you can re-run from a blank wire. Run on each
# node you addressed.
set -uo pipefail

echo ">>> Deleting the 'eth' NetworkManager profile..."
if sudo nmcli connection delete eth 2>/dev/null; then
  echo ">>> Done. eth0 is back to a blank wire (no IPv4 identity)."
else
  echo "(no 'eth' profile found — already blank)"
fi
