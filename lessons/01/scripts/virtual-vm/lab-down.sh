#!/usr/bin/env bash
# Tear down the two-VM lab: stop both QEMU processes and clean up their sockets.
# By default the downloaded base image and the per-node disks are KEPT, so the
# next lab-up is fast and your nodes remember their state. Pass --wipe to delete
# the node disks + seeds for a factory-fresh boot next time.
set -uo pipefail
cd "$(dirname "$0")"
source ./common.sh

for n in a b; do
  pidfile="$LAB_HOME/pi-$n.pid"
  if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
    kill "$(cat "$pidfile")" 2>/dev/null && echo "stopped pi-$n"
  else
    echo "(pi-$n not running)"
  fi
  rm -f "$pidfile" "$LAB_HOME/pi-$n.qmp"
done

echo "Lab down."

if [ "${1:-}" = "--wipe" ]; then
  rm -f "$LAB_HOME"/pi-*.qcow2 "$LAB_HOME"/seed-*.iso
  echo "wiped node disks + seeds (base image kept)."
fi
