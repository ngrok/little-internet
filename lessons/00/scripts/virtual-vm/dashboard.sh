#!/usr/bin/env bash
# Stand up the two-VM lab (if it isn't already) and open a minimal black-and-white
# web dashboard: both nodes' link, address, ARP cache, serial console, and the
# frames crossing the wire, all live. Ctrl-C stops the dashboard; the lab keeps
# running (tear it down with ./lab-down.sh).
set -uo pipefail
cd "$(dirname "$0")"
source ./common.sh
export LAB_HOME
DASH_PORT="${DASH_PORT:-8099}"
export DASH_PORT

# stand up the lab as we start (idempotent; skips if VMs are already running)
if ! pgrep -f qemu-system >/dev/null 2>&1; then
  ./lab-up.sh
fi

echo "opening dashboard at http://127.0.0.1:$DASH_PORT"
( sleep 1; open "http://127.0.0.1:$DASH_PORT" >/dev/null 2>&1 || true ) &
exec python3 ./dashboard.py
