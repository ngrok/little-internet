#!/usr/bin/env bash
# Reuse lesson 01's host/architecture detection and QEMU launcher. Separate
# disks, keys, ports and MACs keep the two lessons independent.
set -euo pipefail
VM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LAB_HOME="${LAB_HOME:-$HOME/.little-internet/lab02-vm}"
case "$LAB_HOME" in /*) ;; *) echo 'LAB_HOME must be an absolute path.' >&2; exit 2;; esac
export WIRE_PORT="${WIRE_PORT:-10002}"
source "$VM_DIR/../../../01/scripts/virtual-vm/common.sh"
ssh_opts+=( -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=5
            -o ServerAliveInterval=10 -o ServerAliveCountMax=3 )
ssh_port() { case "$1" in a) echo 2221;; b) echo 2222;; dhcp) echo 2223;; *) return 1;; esac; }
mgmt_mac() { case "$1" in a) echo 52:54:00:02:00:01;; b) echo 52:54:00:02:00:02;; dhcp) echo 52:54:00:02:00:fe;; *) return 1;; esac; }
cable_mac() { case "$1" in a) echo b8:27:eb:02:00:01;; b) echo b8:27:eb:02:00:02;; dhcp) echo b8:27:eb:02:00:fe;; *) return 1;; esac; }

build_seed() (
  set -e
  n="$1"
  dir="$(mktemp -d)"
  trap 'rm -rf "$dir"' EXIT
  cat > "$dir/meta-data" <<SEED
instance-id: lesson02-pi-$n-v1
local-hostname: pi-$n
SEED
  cat > "$dir/user-data" <<SEED
#cloud-config
hostname: pi-$n
users:
  - name: pi
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - $(cat "$SSH_KEY.pub")
package_update: true
packages:
  - network-manager
  - isc-dhcp-client
  - dnsmasq
  - dnsmasq-utils
  - tcpdump
  - tshark
  - iputils-ping
  - iputils-arping
  - ethtool
write_files:
  - path: /etc/NetworkManager/conf.d/10-little-internet.conf
    content: |
      [main]
      dhcp=dhclient
      no-auto-default=*
      [keyfile]
      unmanaged-devices=interface-name:mgmt
  - path: /etc/systemd/network/10-lab-eth0.link
    content: |
      [Match]
      MACAddress=$(cable_mac "$n")
      [Link]
      Name=eth0
  - path: /etc/dnsmasq.conf
    content: |
      # The lesson enables DHCP later. Never serve the management network.
      port=0
      interface=eth0
      bind-dynamic
runcmd:
  - [ systemctl, disable, --now, dnsmasq ]
  - [ systemctl, enable, --now, NetworkManager ]
  - [ systemctl, disable, NetworkManager-wait-online.service ]
SEED
  # Only mgmt belongs to cloud-init/networkd. NM owns the lab NIC. The .link
  # file is installed during boot, so provisioning renames the NIC once below.
  cat > "$dir/network-config" <<SEED
version: 2
ethernets:
  mgmt:
    match:
      macaddress: "$(mgmt_mac "$n")"
    set-name: mgmt
    dhcp4: true
SEED
  iso="$LAB_HOME/seed-$n.iso"
  rm -f "$iso"
  if command -v hdiutil >/dev/null; then
    hdiutil makehybrid -quiet -o "$iso" -iso -joliet -default-volume-name CIDATA "$dir"
  elif command -v xorriso >/dev/null; then
    xorriso -as mkisofs -quiet -o "$iso" -V CIDATA -J -r "$dir"
  elif command -v genisoimage >/dev/null; then
    genisoimage -quiet -o "$iso" -V CIDATA -J -r "$dir"
  else
    echo 'Install xorriso (Linux) or use hdiutil (macOS).' >&2; exit 1
  fi
)
