#!/usr/bin/env bash
# Runs inside dedicated lesson VMs, never on the workstation or a hardware Pi.
set -euo pipefail
for tool in nmcli dhclient dnsmasq dhcp_release tcpdump tshark ip ping arping ethtool; do
  command -v "$tool" >/dev/null || { echo "Missing package tool: $tool" >&2; exit 1; }
done
# The management NIC belongs to cloud-init. Find only the lab MAC and rename it
# on first boot; the .link file makes the name persistent on later boots.
if ! ip link show eth0 >/dev/null 2>&1; then
  for path in /sys/class/net/*; do
    case "$(cat "$path/address")" in
      b8:27:eb:02:00:*)
        iface="${path##*/}"
        ip link set "$iface" down
        ip link set "$iface" name eth0
        ;;
    esac
  done
fi
# An intentionally addressless lesson NIC must not delay cloud-init on reboot.
systemctl disable NetworkManager-wait-online.service
ip link set eth0 up
nmcli device set eth0 managed yes
if [ ! -f /var/lib/little-internet-02-ready ]; then
  systemctl disable --now dnsmasq
  nmcli connection add type ethernet ifname eth0 con-name eth-dhcp \
    ipv4.method auto ipv4.never-default yes ipv4.ignore-auto-dns yes \
    ipv4.dhcp-timeout 15 ipv4.dhcp-client-id mac ipv4.may-fail no \
    ipv6.method link-local connection.autoconnect no
  touch /var/lib/little-internet-02-ready
fi
sync
