#!/usr/bin/env bash
# Shared transport + presentation for the lesson 01 steps.
#
# Each step hands a block of shell to node_a / node_b, which runs it AS ROOT on
# that node. Pick a backend with MODE:
#
#   MODE=ssh    (default)  drive two real nodes over SSH. You'll be asked for
#                          that node's sudo password once per step—unless
#                          you've set up passwordless sudo, which is opt-in.
#   MODE=netns             drive the local namespace lab (see virtual/lab-up.sh).
#
# Point the SSH backend at your nodes with A_HOST / B_HOST.
set -euo pipefail

# MODE picks the backend. If you don't set it, autodetect: a namespace lab being up
# (pi-a present under /run/netns) means you're virtual; otherwise assume real Pis
# over SSH. The context banner below prints whichever it chose.
if [ -z "${MODE:-}" ]; then
  if [ -e /run/netns/pi-a ] || [ -e /var/run/netns/pi-a ]; then MODE=netns; else MODE=ssh; fi
fi
A_HOST="${A_HOST:-pi@pi-foo-01.local}"
B_HOST="${B_HOST:-pi@pi-foo-02.local}"

# The VM lab (scripts/virtual-vm) is SSH-reachable on localhost: pi-a on port
# 2201, pi-b on 2202, using the key the lab generated. MODE=vm drives those.
VM_KEY="${VM_KEY:-$HOME/.little-internet/lab00-vm/id_ed25519}"

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPTS/../../shared/presentation.sh"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
LESSON_OUTPUT_DIR="${LESSON_OUTPUT_DIR:-$HOME/.little-internet/lesson01}"
EVIDENCE=""

phase_cleanup() {
  local status=$?
  if [ "$status" -ne 0 ]; then
    note 'This phase stopped. Correct the error above before continuing.'
    if [ -n "${CAPTURE:-}" ]; then note "Partial pi-a capture: $CAPTURE"; fi
  fi
}
begin() {
  PHASE_TITLE="$1"
  trap phase_cleanup EXIT
  phase_banner "$1"
  note "$2"
}
finish() {
  review "$1" "$2"
  if [ "${LESSON_RUNNER:-0}" = 1 ]; then
    case "${3:-}" in 'Next: '*|'') ;; *) note "$3";; esac
  else
    if [ -n "$EVIDENCE" ]; then note "$EVIDENCE"; fi
    if [ -n "${3:-}" ]; then note "$3"; fi
  fi
}

# ---- transport -------------------------------------------------------------
# _run TARGET BLOCK — run BLOCK as root on TARGET. For ssh the block is base64'd
# (so its quoting never bites) and decoded on the far side; `ssh -t` keeps a
# terminal attached so sudo can prompt, and the block travels as an argument so
# your keyboard stays free to type the password.
_run() {
  case "$MODE" in
    ssh)
      local b64; b64="$(printf '%s' "$2" | base64 | tr -d '\n')"
      # LogLevel=ERROR hides ssh's own chatter (the "Connection to X closed." line
      # that -t prints at session end) while still surfacing real errors and the
      # remote sudo prompt.
      ssh -t -o LogLevel=ERROR "$1" "echo $b64 | base64 -d | sudo bash -e"
      ;;
    vm)
      # Same base64 SSH transport, but the VM nodes are on localhost ports with a
      # dedicated key, and their pi user has passwordless sudo (so no -t needed).
      local b64; b64="$(printf '%s' "$2" | base64 | tr -d '\n')"
      ssh -i "$VM_KEY" -p "$1" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o SetEnv=LC_ALL=C.UTF-8 -o LogLevel=ERROR \
        pi@127.0.0.1 "echo $b64 | base64 -d | sudo bash -e"
      ;;
    *)
      printf '%s' "$2" | sudo ip netns exec "$1" bash -e
      ;;
  esac
}

case "$MODE" in
  ssh) A_TGT="$A_HOST"; B_TGT="$B_HOST" ;;
  vm)  A_TGT="2201"; B_TGT="2202" ;;
  *)   A_TGT="pi-a"; B_TGT="pi-b" ;;
esac

node_a() { terminal_output _run "$A_TGT" "$1"; }
node_b() { terminal_output _run "$B_TGT" "$1"; }
node() {
  h "[pi-$1] $ $2"
  "node_$1" "$2"
}
# Decode as the login user, without sudo or an allocated remote terminal. This
# keeps authentication prompts and terminal escapes out of the saved packet rows.
read_node_a() {
  case "$MODE" in
    ssh) ssh -T -o LogLevel=ERROR "$A_TGT" "$1" ;;
    vm) ssh -T -i "$VM_KEY" -p "$A_TGT" \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o SetEnv=LC_ALL=C.UTF-8 -o LogLevel=ERROR pi@127.0.0.1 "$1" ;;
    *) sudo ip netns exec "$A_TGT" bash -ec "$1" ;;
  esac
}
capture_show() {
  local capture="$1" label="$2" file command status
  mkdir -p "$LESSON_OUTPUT_DIR"
  file="$LESSON_OUTPUT_DIR/$RUN_ID-$label.txt"
  command="if command -v tshark >/dev/null 2>&1; then
  tshark -n -r '$capture'
else
  tcpdump -n -e -r '$capture'
fi"
  h "pi-a packets · $label"
  if read_node_a "$command" > "$file"; then status=0; else status=$?; fi
  EVIDENCE="${EVIDENCE}pi-a capture: $capture
Decoded rows: $file
"
  if [ "${LESSON_RUNNER:-0}" = 1 ]; then
    printf '%s\n' "$PHASE_TITLE" "pi-a capture: $capture" "Decoded rows: $file" >> "$LESSON_RUN_INDEX"
  fi
  if [ "$status" -ne 0 ]; then
    h "Failed: [pi-a] $ $command"
    terminal_output cat "$file"
    return "$status"
  fi
  page_rows "$file"
}

# baseline_block — shell (run as root on a node) that returns eth0 to its stock
# resting state: a single DHCP, autoconnect wired profile (eth-dhcp) that never
# grabs the default route, so management stays on wlan0. This is what a freshly
# imaged Pi has out of the box, and it's what makes a blank eth0 chatter the
# instant the link comes up—the spontaneous burst the whole lesson is built on.
# DHCP finds no server on a two-Pi link, so the wire stays addressless ("no
# identity") while still talking. Each DHCP try and IPv6 RA wait is capped at
# 10s to match the image profile (see image/.../files/eth-dhcp.nmconnection
# for the why).
# Idempotent. NetworkManager only; the netns lab has no NM, so this no-ops
# there.
baseline_block() {
cat <<'EOF'
command -v nmcli >/dev/null 2>&1 || exit 0
existing="$(nmcli -t -f NAME connection show 2>/dev/null)"
# Drop the lesson's other wired profiles so eth-dhcp is the only connection on eth0.
for c in eth eth0 "Wired connection 1"; do
  printf '%s\n' "$existing" | grep -qx "$c" && nmcli connection delete "$c" >/dev/null 2>&1
done
printf '%s\n' "$existing" | grep -qx eth-dhcp || \
  nmcli connection add type ethernet ifname eth0 con-name eth-dhcp \
    ipv4.method auto ipv4.dhcp-timeout 10 ipv6.method auto ipv6.ra-timeout 10 \
    connection.autoconnect yes ipv4.never-default yes ipv6.never-default yes \
    >/dev/null
# --wait 0: don't sit out the doomed DHCP/RA activation — on a serverless wire
# it only ever resolves to the addressless resting state we're after anyway.
nmcli --wait 0 connection up eth-dhcp >/dev/null 2>&1 || true
EOF
}
