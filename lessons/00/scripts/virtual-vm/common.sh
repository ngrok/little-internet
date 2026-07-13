#!/usr/bin/env bash
# Shared configuration + helpers for the two-VM "one bare cable" lab.
# Sourced by lab-up.sh, lab-down.sh, link.sh, and the ssh-a/ssh-b wrappers.
#
# The physical bench is two Raspberry Pis joined by one Ethernet cable, each
# reachable over an isolated Wi-Fi. Here each Pi is a QEMU process, the cable is
# a QEMU socket netdev (pure L2, nothing in between), and the isolated Wi-Fi is
# a per-VM user-mode NAT that only carries your SSH session.
set -euo pipefail

# Everything the lab creates at runtime lives OUTSIDE the repo so git stays clean.
LAB_HOME="${LAB_HOME:-$HOME/.little-internet/lab00-vm}"

# HVF can only accelerate a guest that matches the host CPU, so the host arch
# picks both the QEMU binary and the Debian image (Apple Silicon runs arm64
# guests, Intel Macs run amd64).
case "$(uname -m)" in
  arm64|aarch64) GUEST_ARCH=arm64; QEMU_DEFAULT=qemu-system-aarch64 ;;
  x86_64)        GUEST_ARCH=amd64; QEMU_DEFAULT=qemu-system-x86_64 ;;
  *) echo "error: unsupported host architecture: $(uname -m)" >&2; exit 1 ;;
esac

# Debian 12 "bookworm" cloud image — the same Debian lineage as Raspberry Pi OS.
IMG_URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-$GUEST_ARCH.qcow2"
BASE_IMG="$LAB_HOME/debian-base-$GUEST_ARCH.qcow2"

# The virtual crossover cable is a QEMU socket on this localhost TCP port.
WIRE_PORT="${WIRE_PORT:-10000}"

# Resolve QEMU + qemu-img from the SAME directory, so a stray qemu-img earlier in
# PATH (e.g. the Android SDK's) can't be picked up by accident.
QEMU="${QEMU:-$QEMU_DEFAULT}"
if ! command -v "$QEMU" >/dev/null 2>&1; then
  echo "error: '$QEMU' not found. Install QEMU first:  brew install qemu" >&2
  exit 1
fi
QEMU_IMG="${QEMU_IMG:-$(dirname "$(command -v "$QEMU")")/qemu-img}"

# x86_64 QEMU has a default board and BIOS; aarch64 has neither, so it gets the
# generic "virt" machine plus the EDK2 UEFI firmware that ships with QEMU.
# (Always non-empty: bash 3.2, macOS's default, chokes on empty arrays + set -u.)
if [ "$GUEST_ARCH" = arm64 ]; then
  EDK2_FW="$(dirname "$(command -v "$QEMU")")/../share/qemu/edk2-aarch64-code.fd"
  if [ ! -f "$EDK2_FW" ]; then
    echo "error: EDK2 firmware not found at $EDK2_FW (reinstall QEMU?)" >&2
    exit 1
  fi
  machine_args=( -M virt -bios "$EDK2_FW" )
else
  machine_args=( -M q35 )
fi

SSH_KEY="$LAB_HOME/id_ed25519"
ssh_opts=( -i "$SSH_KEY" -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
           -o SetEnv=LC_ALL=C.UTF-8 )

# Per-node settings. pi-a LISTENS on the wire; pi-b CONNECTS to it.
#   ssh_port  -> host port forwarded to the guest's sshd over the mgmt NAT
#   mgmt_mac  -> the "Wi-Fi" NIC you SSH in over (QEMU default 52:54:00 prefix)
#   cable_mac -> the eth0 cable NIC under study (b8:27:eb = real Pi vendor prefix)
ssh_port()  { case "$1" in a) echo 2201;; b) echo 2202;; *) return 1;; esac; }
mgmt_mac()  { case "$1" in a) echo 52:54:00:aa:00:01;; b) echo 52:54:00:aa:00:02;; esac; }
cable_mac() { case "$1" in a) echo b8:27:eb:00:00:01;; b) echo b8:27:eb:00:00:02;; esac; }

# Run a command on a node over its management SSH (non-interactive).
node_ssh() { local n="$1"; shift; ssh "${ssh_opts[@]}" -p "$(ssh_port "$n")" pi@127.0.0.1 "$@"; }

# Build the cloud-init seed ISO for one node: hostname, our login key, tcpdump,
# and a network-config that renames NICs by MAC and leaves the cable BLANK (no
# IPv4) — exactly where the lesson starts.
build_seed() {
  local n="$1" hn="pi-$1" dir iso
  hn="pi-$n"
  iso="$LAB_HOME/seed-$n.iso"
  dir="$(mktemp -d)"

  cat > "$dir/meta-data" <<EOF
instance-id: pi-$n
local-hostname: $hn
EOF

  cat > "$dir/user-data" <<EOF
#cloud-config
hostname: $hn
users:
  - name: pi
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
    ssh_authorized_keys:
      - $(cat "$SSH_KEY.pub")
package_update: true
packages:
  - tcpdump
runcmd:
  - [ systemctl, enable, --now, ssh ]
EOF

  # match=MAC so naming is deterministic regardless of PCI probe order.
  # eth0 (the cable) is intentionally left with no address: a blank wire.
  cat > "$dir/network-config" <<EOF
version: 2
ethernets:
  mgmt:
    match:
      macaddress: "$(mgmt_mac "$n")"
    set-name: mgmt
    dhcp4: true
  eth0:
    match:
      macaddress: "$(cable_mac "$n")"
    set-name: eth0
    dhcp4: false
    dhcp6: false
    optional: true
EOF

  rm -f "$iso"
  # hdiutil (built into macOS) writes an ISO9660+Joliet image labeled CIDATA,
  # which is what cloud-init's NoCloud datasource looks for.
  hdiutil makehybrid -quiet -o "$iso" -iso -joliet -default-volume-name CIDATA "$dir"
  rm -rf "$dir"
}

# Boot one node, detached. $2 is the wire netdev spec (listen on pi-a, connect on
# pi-b). The cable NIC carries id=cable so link.sh can toggle its carrier.
boot_node() {
  local n="$1" wire_spec="$2"
  "$QEMU" \
    -name "pi-$n" \
    "${machine_args[@]}" \
    -accel hvf \
    -cpu host \
    -m 1024 -smp 2 \
    -drive if=virtio,format=qcow2,file="$LAB_HOME/pi-$n.qcow2" \
    -drive if=virtio,format=raw,file="$LAB_HOME/seed-$n.iso",readonly=on \
    -netdev user,id=mgmt,hostfwd=tcp:127.0.0.1:"$(ssh_port "$n")"-:22 \
    -device virtio-net-pci,netdev=mgmt,mac="$(mgmt_mac "$n")" \
    -netdev "$wire_spec" \
    -device virtio-net-pci,netdev=wire,mac="$(cable_mac "$n")",id=cable \
    -qmp "unix:$LAB_HOME/pi-$n.qmp,server,nowait" \
    -serial "file:$LAB_HOME/pi-$n-serial.log" \
    -display none \
    -pidfile "$LAB_HOME/pi-$n.pid" \
    -daemonize
}
