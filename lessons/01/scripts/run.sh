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
# lessons/01/README.md.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

VIRTUAL=; VM=
while [ "$#" -gt 0 ]; do
  case "$1" in
    --virtual) VIRTUAL=1 ;;
    --vm) VM=1 ;;
    --auto) export LESSON_AUTO=1 ;;
    *) echo 'usage: run.sh [--virtual|--vm] [--auto]' >&2; exit 2 ;;
  esac
  shift
done
if [ -n "$VIRTUAL" ] && [ -n "$VM" ]; then
  echo 'Choose either --virtual or --vm.' >&2
  exit 2
fi
# Physical actions still require a person, even in an unattended invocation.
if [ "${LESSON_AUTO:-0}" = 1 ] && [ -z "$VIRTUAL$VM" ]; then
  echo '--auto requires --virtual or --vm; hardware needs cable handoffs.' >&2
  exit 2
fi

# Phase 01 shows physical negotiation on hardware, carrier events in VMs, and
# the already-connected link in namespaces.
BEATS=(01-link 02-listen 03-no-address 04-address 05-arp)

if [ -n "$VM" ]; then
  "$HERE/virtual-vm/lab-down.sh" >/dev/null 2>&1 || true
  QUIET=1 START_UNSEATED=1 "$HERE/virtual-vm/lab-up.sh" || exit 1
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

source "$HERE/lib.sh"
export MODE LESSON_OUTPUT_DIR
export LESSON_RUNNER=1
mkdir -p "$LESSON_OUTPUT_DIR"
export LESSON_RUN_INDEX="$LESSON_OUTPUT_DIR/run-$RUN_ID.txt"
printf 'Lesson 01 evidence from this run\n' > "$LESSON_RUN_INDEX"
# Keep the existing backend teardown trap and add the evidence index to it.
runner_cleanup() {
  local status=$?
  if [ -n "$VM" ]; then "$HERE/virtual-vm/lab-down.sh" >/dev/null 2>&1 || true; fi
  if [ -n "$VIRTUAL" ]; then sudo "$HERE/virtual/lab-down.sh" >/dev/null 2>&1 || true; fi
  note "Capture paths and decoded rows for this run: $LESSON_RUN_INDEX"
  return "$status"
}
trap runner_cleanup EXIT
for step in "${BEATS[@]}"; do
  run_script "$HERE/$step.sh"
done

# Virtual finale: the lab's still up, so offer the live dashboard before teardown.
# Only interactively — a non-tty run (CI) just falls through to the EXIT trap.
if [ -n "$VIRTUAL" ] && [ -t 0 ] && [ -t 1 ] && [ "${LESSON_AUTO:-0}" != 1 ]; then
  note 'The lab is still up. The dashboard shows both ARP caches beside a shell
on pi-a. Send a ping there to watch the caches change. Ctrl-b, then d exits.'
  pause 'Press Enter to open the dashboard, or Ctrl-C to finish here.'
  sudo env ORCHESTRATED=1 "$HERE/virtual/watch.sh"
fi
