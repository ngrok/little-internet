#!/usr/bin/env bash
# Walk the whole lesson start to finish, pausing between each step. The individual
# step scripts still stand alone (run or re-run any one of them); this just chains
# them into one guided pass.
#
#   ./run.sh                 # drive two real Pis over SSH (set A_HOST / B_HOST)
#   ./run.sh --virtual       # stand up the local namespace lab, walk it, tear down
#   ./run.sh --vm            # stand up the two-VM QEMU lab, walk it, tear down
#
# --virtual needs Linux + root + the virtual/ deps (tcpdump, ping). On macOS or
# Windows, run that inside a Linux VM. --vm needs QEMU (brew install qemu). See
# lessons/00/README.md.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

VIRTUAL=; VM=
case "${1:-}" in
  "")        ;;
  --virtual) VIRTUAL=1 ;;
  --vm)      VM=1 ;;
  *)         echo "usage: run.sh [--virtual|--vm]" >&2; exit 2 ;;
esac

# 00-link is hardware-only on a real PHY; it self-skips under netns and runs the
# carrier beat under the VM lab (whose virtio NIC has a controllable carrier).
BEATS=(00-link 01-listen 02-no-address 03-address 04-arp)

if [ -n "$VM" ]; then
  "$HERE/virtual-vm/lab-down.sh" >/dev/null 2>&1 || true
  "$HERE/virtual-vm/lab-up.sh" || exit 1
  export MODE=vm
  # tear the VM lab down on any exit, including Ctrl-C partway through
  trap '"$HERE/virtual-vm/lab-down.sh" >/dev/null 2>&1 || true' EXIT
elif [ -n "$VIRTUAL" ]; then
  sudo "$HERE/virtual/lab-down.sh" >/dev/null 2>&1 || true
  sudo QUIET=1 "$HERE/virtual/lab-up.sh" || exit 1
  export MODE=netns
  # tear the lab down on any exit, including Ctrl-C partway through
  trap 'sudo "$HERE/virtual/lab-down.sh" >/dev/null 2>&1 || true' EXIT
fi

for i in "${!BEATS[@]}"; do
  [ "$i" -gt 0 ] && printf '\n────────────────────────────────────────────────────\n'
  "$HERE/${BEATS[$i]}.sh"
done

# Virtual finale: the lab's still up, so offer the live dashboard before teardown.
# Only interactively — a non-tty run (CI) just falls through to the EXIT trap.
if [ -n "$VIRTUAL" ] && [ -t 1 ]; then
  printf '\n────────────────────────────────────────────────────\n\n'
  printf 'The lab is still up. Want to watch the ARP cache react live?\n'
  printf 'A dashboard opens with pi-a and pi-b side by side and a shell on pi-a to\n'
  printf 'poke them: ping from the bottom pane and watch both caches move.\n'
  printf '(Ctrl-b then d exits the dashboard.)\n\n'
  printf 'Press Enter to open it, or Ctrl-C to finish here. '
  read -r
  sudo env ORCHESTRATED=1 "$HERE/virtual/watch.sh"
fi
