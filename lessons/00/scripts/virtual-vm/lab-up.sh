#!/usr/bin/env bash
# Boot two Debian VMs (pi-a, pi-b) joined by one bare QEMU socket cable, each
# reachable over its own isolated management NAT via SSH. Idempotent: re-running
# reuses the downloaded base image, the per-node disks, and the SSH key.
#
#   pi-a  <--- QEMU socket cable (eth0) --->  pi-b
#     \__ ssh :2201            ssh :2202 __/   (isolated mgmt NAT, your way in)
#
# No sudo needed on the Mac — HVF runs QEMU unprivileged. First run downloads a
# ~350MB image and installs tcpdump inside the guests, so it takes a few minutes.
set -euo pipefail
cd "$(dirname "$0")"
source ./common.sh

mkdir -p "$LAB_HOME"

# 1. an SSH keypair the lab injects into both guests (created once).
if [ ! -f "$SSH_KEY" ]; then
  ssh-keygen -t ed25519 -N '' -f "$SSH_KEY" -C little-internet-lab >/dev/null
  echo "created lab SSH key: $SSH_KEY"
fi

# 2. the Debian cloud image, downloaded once and kept read-only as a backing file.
if [ ! -f "$BASE_IMG" ]; then
  echo "downloading Debian cloud image (once, ~350MB)…"
  curl -fL "$IMG_URL" -o "$BASE_IMG.part"
  mv "$BASE_IMG.part" "$BASE_IMG"
fi

# 3. per-node overlay disks (copy-on-write on top of the base) + seed ISOs.
for n in a b; do
  if [ ! -f "$LAB_HOME/pi-$n.qcow2" ]; then
    "$QEMU_IMG" create -f qcow2 -F qcow2 -b "$BASE_IMG" "$LAB_HOME/pi-$n.qcow2" >/dev/null
  fi
  build_seed "$n"
done

# 4. boot pi-a FIRST as the wire's listener, then pi-b connects to it.
if [ -f "$LAB_HOME/pi-a.pid" ] && kill -0 "$(cat "$LAB_HOME/pi-a.pid")" 2>/dev/null; then
  echo "pi-a already running. Run ./lab-down.sh first to restart clean." >&2
  exit 1
fi
echo "booting pi-a (wire listener)…"
boot_node a "socket,id=wire,listen=127.0.0.1:$WIRE_PORT"
sleep 2   # let the listen socket bind before the peer connects
echo "booting pi-b (wire connector)…"
boot_node b "socket,id=wire,connect=127.0.0.1:$WIRE_PORT"

# 5. wait for SSH on both (first boot runs cloud-init + apt, so be patient).
echo -n "waiting for both nodes to answer SSH (first boot installs tcpdump)…"
for n in a b; do
  ok=""
  for _ in $(seq 1 150); do
    if node_ssh "$n" true 2>/dev/null; then ok=1; break; fi
    echo -n "."; sleep 2
  done
  [ -n "$ok" ] || { echo; echo "pi-$n did not come up — see $LAB_HOME/pi-$n-serial.log" >&2; exit 1; }
done
echo " up."

# cloud-init can't reliably install tshark on first boot: its own package step
# holds the apt lock while it runs, and SSH comes up before it finishes. So wait
# for cloud-init to complete, then install. Fast no-op on later boots.
echo "ensuring tshark on both nodes (first boot may take a moment)…"
for n in a b; do
  node_ssh "$n" 'command -v tshark >/dev/null 2>&1 && exit 0
    sudo cloud-init status --wait >/dev/null 2>&1 || true
    sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y tshark' >/dev/null 2>&1 \
    || echo "warning: could not install tshark on pi-$n (beats fall back to tcpdump)" >&2
done

cat <<EOF

Lab up:  pi-a  <--socket cable (eth0)-->  pi-b   (cable seated, no IPv4 yet)

Open two terminals side by side and step onto each node:
  ./ssh-a          # left pane  — you're on pi-a
  ./ssh-b          # right pane — you're on pi-b

Watch a frame cross the wire (classic move):
  on pi-b:  sudo tcpdump -i eth0 -n -e            # leave this running
  on pi-a:  sudo ip addr add 10.10.0.1/24 dev eth0
  on pi-b:  sudo ip addr add 10.10.0.2/24 dev eth0
  on pi-a:  ping -c2 10.10.0.2                    # ARP + ICMP scroll up on pi-b

Seat / unseat the cable (Layer 1), from a third pane on the Mac:
  ./link.sh a off        # pi-a's eth0 goes NO-CARRIER; watch pi-b react
  ./link.sh a on

Tear it all down with:  ./lab-down.sh   (add --wipe to delete the node disks)
EOF
