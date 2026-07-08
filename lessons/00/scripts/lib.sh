#!/usr/bin/env bash
# Shared transport + presentation for the lesson 00 steps.
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
set -uo pipefail

# MODE picks the backend. If you don't set it, autodetect: a namespace lab being up
# (pi-a present under /run/netns) means you're virtual; otherwise assume real Pis
# over SSH. The context banner below prints whichever it chose.
if [ -z "${MODE:-}" ]; then
  if [ -e /run/netns/pi-a ] || [ -e /var/run/netns/pi-a ]; then MODE=netns; else MODE=ssh; fi
fi
A_HOST="${A_HOST:-pi@pi-foo-01.local}"
B_HOST="${B_HOST:-pi@pi-foo-02.local}"

# ---- presentation ----------------------------------------------------------
# Colors only when stdout is a terminal and NO_COLOR is unset.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  _B=$'\033[1m'; _C=$'\033[36m'; _Y=$'\033[33m'; _D=$'\033[2m'; _X=$'\033[0m'
else
  _B=; _C=; _Y=; _D=; _X=
fi

# Every helper emits ONE leading blank line and hugs whatever follows, so any two
# elements are separated by exactly one blank line and headers sit right atop
# their output.
# h TEXT — a section header: a blank line, then a bold-cyan marker.
h() { printf '\n%s%s▸ %s%s\n' "$_B" "$_C" "$*" "$_X"; }
# note — dimmed explanatory text read from stdin.
note() { printf '\n'; while IFS= read -r l; do printf '%s%s%s\n' "$_D" "$l" "$_X"; done; }
# eye — a yellow "what just happened" block read from stdin; shown AFTER the output
# so it's a look-back at what you just saw, not a spoiler before it.
eye() { printf '\n%swhat just happened%s\n' "$_B$_Y" "$_X"
        while IFS= read -r l; do printf '%s    %s%s\n' "$_Y" "$l" "$_X"; done; }
# pause MSG — bold prompt, then wait for Enter so you can read before anything
# runs. When there's no terminal (the demo one-shot, CI), it prints and continues.
pause() {
  printf '\n%s%s%s\n' "$_B" "$*" "$_X"
  [ -t 0 ] || return 0
  printf '%s[press Enter]%s ' "$_D" "$_X"; read -r
}

# $STYLE — the h() definition with colors frozen in, to prepend to node blocks so
# sub-headers printed on the node look identical to the controller's.
STYLE="h(){ printf '\n${_B}${_C}▸ %s${_X}\n' \"\$*\"; }"

# ---- transport -------------------------------------------------------------
# _run TARGET BLOCK — run BLOCK as root on TARGET. For ssh the block is base64'd
# (so its quoting never bites) and decoded on the far side; `ssh -t` keeps a
# terminal attached so sudo can prompt, and the block travels as an argument so
# your keyboard stays free to type the password.
_run() {
  if [ "$MODE" = ssh ]; then
    local b64; b64="$(printf '%s' "$2" | base64 | tr -d '\n')"
    # LogLevel=ERROR hides ssh's own chatter (the "Connection to X closed." line
    # that -t prints at session end) while still surfacing real errors and the
    # remote sudo prompt.
    ssh -t -o LogLevel=ERROR "$1" "echo $b64 | base64 -d | sudo bash"
  else
    printf '%s' "$2" | sudo ip netns exec "$1" bash
  fi
}

if [ "$MODE" = ssh ]; then
  A_TGT="$A_HOST"; B_TGT="$B_HOST"
else
  A_TGT="pi-a"; B_TGT="pi-b"
fi

node_a() { _run "$A_TGT" "$1"; }
node_b() { _run "$B_TGT" "$1"; }

# baseline_block — shell (run as root on a node) that returns eth0 to its stock
# resting state: a single DHCP, autoconnect wired profile (eth-dhcp) that never
# grabs the default route, so management stays on wlan0. This is what a freshly
# imaged Pi has out of the box, and it's what makes a blank eth0 chatter the
# instant the link comes up—the spontaneous burst the whole lesson is built on.
# DHCP finds no server on a two-Pi link, so the wire stays addressless ("no
# identity") while still talking. Idempotent. NetworkManager only; the netns lab
# has no NM, so this no-ops there.
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
    ipv4.method auto ipv6.method auto connection.autoconnect yes \
    ipv4.never-default yes ipv6.never-default yes >/dev/null
nmcli connection up eth-dhcp >/dev/null 2>&1 || true
EOF
}

# Context line, every step: you run from THIS machine; it reaches both nodes.
if [ "$MODE" = ssh ]; then
  note <<EOF
Running from this machine against pi-a=$A_HOST and pi-b=$B_HOST.
Each node's sudo may prompt once. (MODE=ssh; set A_HOST/B_HOST to retarget.)
EOF
else
  note <<EOF
Running from this machine against the local namespace lab (pi-a, pi-b). (MODE=netns)
EOF
fi
