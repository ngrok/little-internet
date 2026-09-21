#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
case "${1:-}" in ''|--wipe) ;; *) echo 'usage: lab-down.sh [--wipe]' >&2; exit 2;; esac
# Verify the process command before using a saved PID; stale PID files must not
# kill an unrelated process. Wait for QEMU to exit before deleting any disks.
for name in pi-a pi-b pi-dhcp switch; do
  file="$LAB_HOME/$name.pid"
  [ -f "$file" ] || continue
  pid="$(cat "$file")"
  case "$pid" in ''|*[!0-9]*) echo "Invalid PID in $file" >&2; exit 1;; esac
  if kill -0 "$pid" 2>/dev/null; then
    command_line="$(ps -p "$pid" -o command=)"
    case "$name:$command_line" in
      switch:*"$VM_DIR/switch.py"*|pi-*:*"$LAB_HOME/$name.qcow2"*) ;;
      *) echo "Refusing to stop unrelated PID $pid from $file" >&2; exit 1;;
    esac
    case "$name" in
      pi-*) node_ssh "${name#pi-}" 'sudo sync' || {
        echo "Could not sync $name; refusing an abrupt stop. Inspect the VM first." >&2; exit 1;
      };;
    esac
    kill "$pid"
    for _ in $(seq 1 100); do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.1
    done
    if kill -0 "$pid" 2>/dev/null; then echo "PID $pid has not stopped; disks kept." >&2; exit 1; fi
    echo "Stopped $name"
  fi
  rm -f "$file" "$LAB_HOME/$name.qmp"
done
if [ "${1:-}" = --wipe ]; then
  for n in a b dhcp; do rm -f "$LAB_HOME/pi-$n.qcow2" "$LAB_HOME/seed-$n.iso"; done
  echo 'Deleted lesson 02 guest disks and seeds; base image and host captures kept.'
fi
