#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
begin 'Reset — Back to the starting line' \
  'This deletes lesson profiles, preferences, and server leases inside these dedicated VMs. Saved captures remain.'
pause 'Press Enter to reset the lesson VMs, or Ctrl-C to leave them as they are.'
setup dhcp 'systemctl disable --now dnsmasq
rm -f /var/lib/misc/dnsmasq.leases'
for n in a b dhcp; do
  "$SCRIPTS/virtual-vm/link.sh" "$n" on >/dev/null
  setup "$n" 'for profile in eth-manual eth-server eth-dhcp; do
  if nmcli -t -f NAME connection show | grep -qx "$profile"; then
    nmcli connection delete "$profile"
  fi
done
rm -f /etc/NetworkManager/dhclient-eth0.conf
rm -f /var/lib/NetworkManager/dhclient-*-eth0.lease
ip -4 addr flush dev eth0
ip neigh flush dev eth0
nmcli connection add type ethernet ifname eth0 con-name eth-dhcp \
  ipv4.method auto ipv4.never-default yes ipv4.ignore-auto-dns yes \
  ipv4.dhcp-timeout 15 ipv4.dhcp-client-id mac ipv4.may-fail no \
  ipv6.method link-local connection.autoconnect no
ip link set eth0 up
ip -4 addr show dev eth0'
done
if [ "${LESSON_RUNNER:-0}" = 1 ]; then
  printf '\nReset\nSetup transcript: %s\n' "$TRANSCRIPT" >> "$LESSON_RUN_INDEX"
  say 'Reset complete. Continuing to phase 01.'
else
  say 'Ready for ./scripts/run.sh. The server configuration is kept but its service is stopped.'
fi
