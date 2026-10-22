#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
"$VM_DIR/../check.sh" --host
mkdir -p "$LAB_HOME"
# Refuse partial/running labs before touching disks or seed images.
for name in pi-a pi-b pi-dhcp switch; do
  if [ -f "$LAB_HOME/$name.pid" ] && kill -0 "$(cat "$LAB_HOME/$name.pid")" 2>/dev/null; then
    echo "$name is already running. Use check.sh, or lab-down.sh before restarting." >&2
    exit 1
  fi
done
if [ ! -f "$SSH_KEY" ]; then
  ssh-keygen -q -t ed25519 -N '' -f "$SSH_KEY" -C little-internet-02
fi
if [ ! -f "$BASE_IMG" ]; then
  echo 'Downloading Debian 12 cloud image (once)...'
  curl -fL --retry 3 "$IMG_URL" -o "$BASE_IMG.part"
  mv "$BASE_IMG.part" "$BASE_IMG"
fi
for n in a b dhcp; do
  if [ ! -f "$LAB_HOME/pi-$n.qcow2" ]; then
    "$QEMU_IMG" create -f qcow2 -F qcow2 -b "$BASE_IMG" "$LAB_HOME/pi-$n.qcow2" 6G
  fi
  build_seed "$n"
done
# On failure stop only processes this invocation created; retain logs and disks.
started=""
cleanup() {
  status=$?
  if [ "$status" -ne 0 ]; then
    echo "Startup failed; logs and disks are in $LAB_HOME. Stopping this attempt." >&2
    for name in $started; do
      [ ! -f "$LAB_HOME/$name.pid" ] || kill "$(cat "$LAB_HOME/$name.pid")" 2>/dev/null || true
    done
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
nohup python3 -u "$VM_DIR/switch.py" --port "$WIRE_PORT" > "$LAB_HOME/switch.log" 2>&1 < /dev/null &
echo $! > "$LAB_HOME/switch.pid"
started="switch"
for _ in $(seq 1 50); do
  if grep -q '^READY ' "$LAB_HOME/switch.log"; then break; fi
  kill -0 "$(cat "$LAB_HOME/switch.pid")" 2>/dev/null || { cat "$LAB_HOME/switch.log"; exit 1; }
  sleep 0.1
done
grep -q '^READY ' "$LAB_HOME/switch.log"
for n in a b dhcp; do
  echo "Booting pi-$n..."
  boot_node "$n" "socket,id=wire,connect=127.0.0.1:$WIRE_PORT"
  started="$started pi-$n"
done
for n in a b dhcp; do
  echo "Waiting for pi-$n SSH and first-boot package installation..."
  ready=false
  for _ in $(seq 1 180); do
    if node_ssh "$n" true 2>/dev/null; then ready=true; break; fi
    sleep 2
  done
  "$ready" || { echo "SSH timeout: $LAB_HOME/pi-$n-serial.log" >&2; exit 1; }
  node_ssh "$n" 'sudo timeout 900 cloud-init status --wait' || {
    echo "Cloud-init failed on pi-$n. Inspect its serial log; no lesson was started." >&2; exit 1;
  }
  node_ssh "$n" 'sudo bash -se' < "$VM_DIR/../guest/provision.sh"
done
"$VM_DIR/../check.sh"
cat <<MSG

Lesson 02 is ready. Each VM has its own kernel; eth0 connects to the lab switch.
Start the lesson: ./scripts/run.sh
Open a shell:    ./scripts/virtual-vm/ssh-a  (or ssh-b / ssh-dhcp)
Stop the lab:    ./scripts/virtual-vm/lab-down.sh
Disks, logs, and captures: $LAB_HOME
MSG
