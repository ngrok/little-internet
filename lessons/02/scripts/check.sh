#!/usr/bin/env bash
# Read-only preflight. No hardware backend and no implicit lab creation.
set -euo pipefail
case "${1:-}" in ''|--host) ;; *) echo 'usage: check.sh [--host]' >&2; exit 2;; esac
source "$(dirname "$0")/lib.sh"
for tool in "$QEMU_IMG" ssh ssh-keygen curl python3; do
  command -v "$tool" >/dev/null || { echo "Missing host tool: $tool" >&2; exit 1; }
done
if ! command -v hdiutil >/dev/null && ! command -v xorriso >/dev/null && ! command -v genisoimage >/dev/null; then
  echo 'Missing ISO tool: install xorriso on Linux.' >&2; exit 1
fi
echo "Host ready: $GUEST_ARCH / $ACCEL; lab directory: $LAB_HOME"
[ "${1:-}" != --host ] || exit 0
for n in a b dhcp; do
  echo "Checking pi-$n (localhost:$(ssh_port "$n"))"
  if ! setup "$n" '
    set -e
    for tool in nmcli dhclient dnsmasq dhcp_release tcpdump tshark ip ping arping ethtool; do command -v "$tool"; done
    test -f /var/lib/little-internet-02-ready
    ip -br link show eth0; ip -4 -br addr show eth0
    nmcli -f DEVICE,STATE,CONNECTION device
    NetworkManager --print-config | grep "dhcp=dhclient"
    systemctl is-active NetworkManager
'
  then
    echo "pi-$n is not ready. Run ./scripts/virtual-vm/lab-up.sh; inspect its logs on failure." >&2; exit 1
  fi
done
